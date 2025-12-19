import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:convert';
import 'package:med_sync_desktop/services/excel_parser.dart';
import 'package:med_sync_desktop/services/firestore_uploader.dart';
import 'package:med_sync_desktop/models/db_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class SyncProvider extends ChangeNotifier {
  String? margDirectory;
  String? pmbiDirectory;
  String? margDetectedFile; 
  String? pmbiDetectedFile;
  
  bool deleteFilesAfterSync = false;
  
  bool isSyncing = false;
  final List<String> _log = [];
  List<String> get log => List.unmodifiable(_log);

  SyncProvider() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved or use Defaults provided by user
    margDirectory = prefs.getString('margDir') ?? r'C:\Users\Public\MARG\56823\report';
    pmbiDirectory = prefs.getString('pmbiDir') ?? r'D:\app\DESK AUTO DETECT\xlsx';
    
    deleteFilesAfterSync = prefs.getBool('deleteFiles') ?? false;
    notifyListeners();
    
    _scanForFiles();
  }

  void addLog(String msg) {
    _log.add(msg);
    notifyListeners();
  }

  Future<void> setMargDirectory(String path) async {
    margDirectory = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('margDir', path);
    notifyListeners();
    _scanForFiles();
  }
  
  Future<void> setPmbiDirectory(String path) async {
    pmbiDirectory = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pmbiDir', path);
    notifyListeners();
    _scanForFiles();
  }

  void setDeleteFilesAfterSync(bool value) async {
    deleteFilesAfterSync = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('deleteFiles', value);
    notifyListeners();
  }

  void setMargFileManual(String path) {
      margDetectedFile = path;
      addLog("Manually selected Marg file: ${p.basename(path)}");
      notifyListeners();
  }

  void setPmbiFileManual(String path) {
      pmbiDetectedFile = path;
      addLog("Manually selected PMBI file: ${p.basename(path)}");
      notifyListeners();
  }

  // Scan directories for relevant files
  Future<void> _scanForFiles() async {
     bool changed = false;
     
     // 1. Scan Marg Directory
     if (margDirectory != null && await Directory(margDirectory!).exists()) {
       try {
         final dir = Directory(margDirectory!);
         final List<FileSystemEntity> entities = await dir.list().toList();
         final files = entities.whereType<File>().where((f) {
           final name = p.basename(f.path).toLowerCase();
           final isExcel = name.endsWith('.xls') || name.endsWith('.xlsx');
           // Accept 'stock' (permissive) but EXCLUDE 'stockreport' (PMBI)
           return isExcel && ((name.startsWith('stock') && !name.startsWith('stockreport')) || name.startsWith('hsncodemaster'));
         }).toList();

         files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

         if (files.isNotEmpty) {
           final newest = files.first.path;
           if (margDetectedFile != newest) {
              margDetectedFile = newest;
              addLog("Detected Marg file: ${p.basename(newest)}");
              changed = true;
           }
         } else {
            if (margDetectedFile != null) {
              // Only clear if NOT manual? 
              // For now, if directory scan runs and fails, we warn.
              // IF user set manual file that IS NOT in this directory, we might have issue.
              // But setMargFileManual sets the file path directly.
              // We'll trust user manual selection invalidates auto-scan until refresh.
              // Logic: _scanForFiles overwrites manual IF it finds a file. 
              // If it finds nothing, it clears.
              margDetectedFile = null;
              addLog("No matching Marg file found in directory.");
              changed = true;
            }
         }
       } catch (e) {
          addLog("Error scanning Marg dir: $e");
       }
     }

     // 2. Scan PMBI Directory
     if (pmbiDirectory != null && await Directory(pmbiDirectory!).exists()) {
       try {
         final dir = Directory(pmbiDirectory!);
         final List<FileSystemEntity> entities = await dir.list().toList();
         final files = entities.whereType<File>().where((f) {
           final name = p.basename(f.path).toLowerCase();
           return name.contains('stockreport') && (name.endsWith('.xlsx') || name.endsWith('.xls'));
         }).toList();

         files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

         if (files.isNotEmpty) {
           final newest = files.first.path;
           if (pmbiDetectedFile != newest) {
              pmbiDetectedFile = newest;
              addLog("Detected PMBI file: ${p.basename(newest)}");
              changed = true;
           }
         } else {
             if (pmbiDetectedFile != null) {
               pmbiDetectedFile = null;
               addLog("No matching PMBI file found.");
               changed = true;
             }
         }
       } catch (e) {
          addLog("Error scanning PMBI dir: $e");
       }
     }

     if (changed) notifyListeners();
  }
  
  Future<void> refreshFiles() async {
      await _scanForFiles();
  }

  Future<void> startSync() async {
    // Re-scan before sync to be sure
    await _scanForFiles();
    
    if ((margDetectedFile == null) && (pmbiDetectedFile == null)) {
      addLog('No valid files detected in the selected directories.');
      return;
    }

    isSyncing = true;
    notifyListeners();
    
    try {
      addLog('Loading service account from assets...');
      final serviceAccountJson = await rootBundle.loadString('assets/serviceAccount.json');
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/serviceAccount.json');
      await tempFile.writeAsString(serviceAccountJson);
      
      final uploader = FirestoreUploader(tempFile.path);
      await uploader.init();
      
      addLog('Clearing metadata collection...');
      await uploader.cleanCollection('metadata', addLog);

      final parser = ExcelParser();

      // Track files to delete
      String? margFileToDelete;
      String? pmbiFileToDelete;

      if (margDetectedFile != null) {
           addLog("Processing Marg: $margDetectedFile");
           try {
             final data = await parser.parseFile(margDetectedFile!, 'medicine_1_data', log: addLog);
             if (data.isNotEmpty) {
                await uploader.updateMetadata('medicine_1_data', data, addLog);
                addLog('Successfully updated Marg data (${data.length} items).');
                margFileToDelete = margDetectedFile;
             } else {
                addLog('Marg file empty or parsing failed.');
             }
           } catch (e) {
             addLog("Error processing Marg: $e");
           }
      }

      if (pmbiDetectedFile != null) {
           addLog("Processing PMBI: $pmbiDetectedFile");
           try {
             final data = await parser.parseFile(pmbiDetectedFile!, 'medicine_2_data', log: addLog);
             if (data.isNotEmpty) {
                await uploader.updateMetadata('medicine_2_data', data, addLog);
                addLog('Successfully updated PMBI data (${data.length} items).');
                pmbiFileToDelete = pmbiDetectedFile;
             } else {
                addLog('PMBI file empty or parsing failed.');
             }
           } catch (e) {
             addLog("Error processing PMBI: $e");
           }
      }

      addLog('Sync process finished.');
      uploader.close();
      await tempFile.delete();
      
      if (deleteFilesAfterSync) {
        if (margFileToDelete != null) {
           try {
             if (await File(margFileToDelete).exists()) {
                 await File(margFileToDelete).delete();
                 addLog("Deleted $margFileToDelete");
                 // Trigger re-scan to update UI
                 _scanForFiles();
             }
           } catch (e) { addLog("Failed delete Marg: $e"); }
        }
        if (pmbiFileToDelete != null) {
           try {
             if (await File(pmbiFileToDelete).exists()) {
                 await File(pmbiFileToDelete).delete();
                 addLog("Deleted $pmbiFileToDelete");
                 _scanForFiles();
             }
           } catch (e) { addLog("Failed delete PMBI: $e"); }
        }
      }

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

