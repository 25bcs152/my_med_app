import 'package:flutter/foundation.dart';
import 'package:med_sync_marg_pmbi/services/excel_parser.dart';
import 'package:med_sync_marg_pmbi/services/firestore_uploader.dart';
import 'dart:io';

class SyncProvider extends ChangeNotifier {
  String? serviceAccountPath;
  String? margPath;
  String? pmbiPath;
  bool isSyncing = false;
  final List<String> _log = [];
  List<String> get log => List.unmodifiable(_log);

  void addLog(String msg) {
    _log.add(msg);
    notifyListeners();
  }

  void setServiceAccount(String path) {
    serviceAccountPath = path;
    notifyListeners();
  }

  void setMargPath(String path) {
    margPath = path;
    notifyListeners();
  }

  void setPmbiPath(String path) {
    pmbiPath = path;
    notifyListeners();
  }

  Future<void> startSync() async {
    if (serviceAccountPath == null || serviceAccountPath!.isEmpty) {
      addLog('Service account not selected');
      return;
    }
    if ((margPath == null || margPath!.isEmpty) && (pmbiPath == null || pmbiPath!.isEmpty)) {
      addLog('No Excel files selected');
      return;
    }
    isSyncing = true;
    notifyListeners();
    try {
      final uploader = FirestoreUploader(serviceAccountPath!);
      await uploader.init();
      // Clean collections first (optional)
      if (margPath != null && margPath!.isNotEmpty) {
        await uploader.cleanCollection('medicine-1', addLog);
      }
      if (pmbiPath != null && pmbiPath!.isNotEmpty) {
        await uploader.cleanCollection('medicine-2', addLog);
      }
      final parser = ExcelParser();
      // Process Marg
      List<Map<String, dynamic>> margRows = [];
      if (margPath != null && margPath!.isNotEmpty) {
        addLog('Parsing Marg file: $margPath');
        margRows = await parser.parseFile(margPath!, 'medicine-1');
        await uploader.uploadBatch('medicine-1', margRows, addLog);
        await uploader.updateMetadata('medicine_1_data', margRows, addLog);
      }
      // Process PMBI
      List<Map<String, dynamic>> pmbiRows = [];
      if (pmbiPath != null && pmbiPath!.isNotEmpty) {
        addLog('Parsing PMBI file: $pmbiPath');
        pmbiRows = await parser.parseFile(pmbiPath!, 'medicine-2');
        await uploader.uploadBatch('medicine-2', pmbiRows, addLog);
        await uploader.updateMetadata('medicine_2_data', pmbiRows, addLog);
      }
      addLog('Sync completed successfully');
    } catch (e, st) {
      addLog('Error during sync: $e');
      if (kDebugMode) {
        addLog(st.toString());
      }
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }
}
