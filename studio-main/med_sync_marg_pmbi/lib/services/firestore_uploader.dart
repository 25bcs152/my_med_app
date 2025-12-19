import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/firestore/v1.dart';

class FirestoreUploader {
  final String serviceAccountPath;
  late AutoRefreshingAuthClient _client;
  late FirestoreApi _firestore;
  late String _projectId;

  FirestoreUploader(this.serviceAccountPath);

  Future<void> init() async {
    final saContent = await File(serviceAccountPath).readAsString();
    final saJson = jsonDecode(saContent);
    _projectId = saJson['project_id'];
    
    final credentials = ServiceAccountCredentials.fromJson(saJson);
    _client = await clientViaServiceAccount(credentials, [FirestoreApi.datastoreScope]);
    _firestore = FirestoreApi(_client);
  }

  String get _parent => "projects/$_projectId/databases/(default)/documents";

  // Deletes all texts in a collection to "clear" it.
  // Note: REST API doesn't have "delete collection", so we list and delete.
  // This can be slow for huge collections, but matches python script behavior.
  Future<void> cleanCollection(String collectionName, Function(String) log) async {
    log("Cleaning collection: $collectionName...");
    bool done = false;
    int deletedCount = 0;
    
    while (!done) {
        // List documents
        final response = await _firestore.projects.databases.documents.list(
            "projects/$_projectId/databases/(default)/documents", 
            collectionName,
            pageSize: 300
        );
        
        if (response.documents == null || response.documents!.isEmpty) {
            done = true;
            break;
        }

        // Create a batch delete request
        List<Write> writes = [];
        for (var doc in response.documents!) {
            if (doc.name != null) {
                writes.add(Write(delete: doc.name));
            }
        }
        
        if (writes.isNotEmpty) {
             final request = CommitRequest(writes: writes);
             await _firestore.projects.databases.documents.commit(request, "projects/$_projectId/databases/(default)");
             deletedCount += writes.length;
             log("Deleted $deletedCount docs...");
        }
        
        if (response.nextPageToken == null) {
            done = true;
        }
    }
    log("Collection $collectionName cleared.");
  }

  Future<void> uploadBatch(String collectionName, List<Map<String, dynamic>> rows, Function(String) log) async {
    log("Uploading ${rows.length} items to $collectionName...");
    
    // Limits: Firestore batch is max 500 writes.
    const int batchSize = 400; // safe margin
    
    for (var i = 0; i < rows.length; i += batchSize) {
        var end = (i + batchSize < rows.length) ? i + batchSize : rows.length;
        var chunk = rows.sublist(i, end);
        
        List<Write> writes = [];
        for (var row in chunk) {
            String docId = row['_id']; // extracted by parser
            Map<String, dynamic> data = Map.from(row);
            data.remove('_id'); // don't store ID inside fields if not needed, but python logic kept it? 
            // Python kept `id` in metadata items but generally docId is key.
            // Python used `data["_imported_at"] = firestore.SERVER_TIMESTAMP`
            // We can skip that or try to replicate using transforms if strictly needed, 
            // but for simplicity we'll just put the string timestamp or skip.
            data['_imported_at'] = DateTime.now().toIso8601String();

            String name = "$_parent/$collectionName/$docId";
            
            // Map Dart Map to Firestore Value
            Map<String, Value> fields = {};
            data.forEach((k, v) {
                fields[k] = _toValue(v);
            });

            // Using 'update' (upsert behavior) if we want to merge, or 'currentDocument' checks.
            // Python script used `batch.set(..., data)`, which overwrites.
            // REST API `update` with no mask acts as overwrite/create if we set it right or just use `update`.
            // The `Write` object with `update` sets the document.
            writes.add(Write(
                update: Document(name: name, fields: fields)
            ));
        }

        final request = CommitRequest(writes: writes);
        await _firestore.projects.databases.documents.commit(request, "projects/$_projectId/databases/(default)");
        log("Batch ${i ~/ batchSize + 1} uploaded (${chunk.length} items).");
    }
    log("Upload to $collectionName complete.");
  }
  
  // Updates the special 'metadata' collection
  Future<void> updateMetadata(String docName, List<Map<String, dynamic>> items, Function(String) log) async {
      log("Updating metadata/$docName...");
      String name = "$_parent/metadata/$docName";
      
      // Metadata items in Python include 'id' inside them
      List<Map<String, dynamic>> cleanItems = items.map((e) {
         var m = Map<String, dynamic>.from(e);
         m['id'] = m['_id'];
         m.remove('_id');
         // convert dates to string for json friendly storage in the big array
         m.forEach((k, v) {
             if (v is DateTime) m[k] = v.toIso8601String();
         });
         return m;
      }).toList();

      // Firestore REST value construction for a huge array map
      // This might hit document size limits (1MB). 
      // Python script did: db.collection('metadata').document('medicine_1_data').set({'items': items1})
      // If it worked in Python, it should work here barring huge lists.
      
      Map<String, Value> fields = {
          "items": _toValue(cleanItems)
      };
      
      List<Write> writes = [
          Write(update: Document(name: name, fields: fields))
      ];
      
      await _firestore.projects.databases.documents.commit(CommitRequest(writes: writes), "projects/$_projectId/databases/(default)");
      log("Metadata updated.");
  }
  
  // Helper to convert Dart types to Firestore Value
  Value _toValue(dynamic v) {
      if (v == null) return Value(nullValue: "NULL_VALUE");
      if (v is bool) return Value(booleanValue: v);
      if (v is int) return Value(integerValue: v.toString());
      if (v is double) return Value(doubleValue: v);
      if (v is String) return Value(stringValue: v);
      if (v is DateTime) return Value(timestampValue: v.toUtc().toIso8601String());
      if (v is List) {
          return Value(arrayValue: ArrayValue(values: v.map((e) => _toValue(e)).toList()));
      }
      if (v is Map) {
          Map<String, Value> mapFields = {};
          v.forEach((k, val) => mapFields[k.toString()] = _toValue(val));
          return Value(mapValue: MapValue(fields: mapFields));
      }
      return Value(stringValue: v.toString());
  }

  void close() {
      _client.close();
  }
}
