import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:convert';
import 'package:med_sync_desktop/services/excel_parser.dart';
import 'package:med_sync_desktop/services/firestore_uploader.dart';
import 'package:med_sync_desktop/models/db_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SyncProvider extends ChangeNotifier {
  String? xlsxFolderPath;
  String? margFilePath; 
  String? pmbiFilePath;
  
  bool isSyncing = false;
  final List<String> _log = [];
  List<String> get log => List.unmodifiable(_log);

  void addLog(String msg) {
    _log.add(msg);
    notifyListeners();
  }

  void setXlsxFolder(String path) {
    xlsxFolderPath = path;
    notifyListeners();
  }

  Future<void> autoDetectXlsxFolder() async {
    try {
      // Get the executable directory
      final exePath = Platform.resolvedExecutable;
      final exeDir = path.dirname(exePath);
      
      // Check for xlsx folder in exe directory
      final xlsxDir = Directory(path.join(exeDir, 'xlsx'));
      
      if (await xlsxDir.exists()) {
        xlsxFolderPath = xlsxDir.path;
        addLog('Found xlsx folder: ${xlsxDir.path}');
        await _detectFiles();
      } else {
        addLog('xlsx folder not found in app directory. Please select manually.');
        xlsxFolderPath = null;
      }
      notifyListeners();
    } catch (e) {
      addLog('Error detecting xlsx folder: $e');
    }
  }

  Future<void> _detectFiles() async {
    if (xlsxFolderPath == null) return;
    
    try {
      final dir = Directory(xlsxFolderPath!);
      final files = await dir.list().where((f) => f.path.toLowerCase().endsWith('.xlsx')).toList();
      
      // Try to identify Marg and PMBI files
      for (var file in files) {
        final fileName = path.basename(file.path).toLowerCase();
        
        // Look for keywords to identify file type
        if (fileName.contains('marg') || fileName.contains('stock')) {
          margFilePath = file.path;
          addLog('Detected Marg file: ${path.basename(file.path)}');
        } else if (fileName.contains('pmbi') || fileName.contains('drug')) {
          pmbiFilePath = file.path;
          addLog('Detected PMBI file: ${path.basename(file.path)}');
        }
      }
      
      // If not found by name, use first two files
      if (margFilePath == null && files.isNotEmpty) {
        margFilePath = files[0].path;
        addLog('Using first file as Marg: ${path.basename(files[0].path)}');
      }
      if (pmbiFilePath == null && files.length > 1) {
        pmbiFilePath = files[1].path;
        addLog('Using second file as PMBI: ${path.basename(files[1].path)}');
      }
      
      notifyListeners();
    } catch (e) {
      addLog('Error detecting files: $e');
    }
  }

  Future<void> startSync() async {
    // Auto-detect if not already done
    if (xlsxFolderPath == null) {
      await autoDetectXlsxFolder();
    }
    
    if ((margFilePath == null || margFilePath!.isEmpty) && (pmbiFilePath == null || pmbiFilePath!.isEmpty)) {
      addLog('No data files found. Please select xlsx folder manually.');
      return;
    }

    isSyncing = true;
    notifyListeners();
    
    try {
      // Load service account from assets
      addLog('Loading service account from assets...');
      final serviceAccountJson = await rootBundle.loadString('assets/serviceAccount.json');
      
      // Write to temp file for FirestoreUploader
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/serviceAccount.json');
      await tempFile.writeAsString(serviceAccountJson);
      
      final uploader = FirestoreUploader(tempFile.path);
      await uploader.init();
      
      addLog('Clearing metadata collection...');
      await uploader.cleanCollection('metadata', addLog);

      final parser = ExcelParser();

      // Process Marg
      if (margFilePath != null && margFilePath!.isNotEmpty) {
           addLog("Processing Marg: $margFilePath");
           try {
             final data = await parser.parseFile(margFilePath!, 'medicine_1_data', log: addLog);
             if (data.isNotEmpty) {
                await uploader.updateMetadata('medicine_1_data', data, addLog);
                addLog('Successfully updated Marg data (${data.length} items).');
             } else {
                addLog('Marg file empty or parsing failed.');
             }
           } catch (e) {
             addLog("Error processing Marg: $e");
           }
      }

      // Process PMBI
      if (pmbiFilePath != null && pmbiFilePath!.isNotEmpty) {
           addLog("Processing PMBI: $pmbiFilePath");
           try {
             final data = await parser.parseFile(pmbiFilePath!, 'medicine_2_data', log: addLog);
             if (data.isNotEmpty) {
                await uploader.updateMetadata('medicine_2_data', data, addLog);
                addLog('Successfully updated PMBI data (${data.length} items).');
             } else {
                addLog('PMBI file empty or parsing failed.');
             }
           } catch (e) {
             addLog("Error processing PMBI: $e");
           }
      }

      addLog('Sync process finished.');
      uploader.close();
      
      // Clean up temp file
      await tempFile.delete();
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
