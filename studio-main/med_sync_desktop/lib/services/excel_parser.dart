import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ExcelParser {
  
  /// Reads an Excel/XLS file using Python bridge and returns a list of rows (as maps)
  Future<List<Map<String, dynamic>>> parseFile(String path, String collectionName, {Function(String)? log}) async {
    log?.call("Opening file via Python: $path");
    
    final fileType = collectionName.contains('medicine_1') ? 'marg' : 'pmbi';
    
    // Assume input script is in assets/scripts/process_excel.py
    // In production (release), assets might be bundled differently.
    // For "studio" context, we assume relative path from executable or project root works.
    // We try to find the script.
    
    // Default development path
    String scriptPath = 'assets/scripts/process_excel.exe'; // Default to exe
    bool useSystemPython = false;
    
    // Check if running in Release mode/executable
    try {
      final exeDir = File(Platform.resolvedExecutable).parent;
      final releaseExePath = '${exeDir.path}/data/flutter_assets/assets/scripts/process_excel.exe';
      final releasePyPath = '${exeDir.path}/data/flutter_assets/assets/scripts/process_excel.py';
      
      if (await File(releaseExePath).exists()) {
        scriptPath = releaseExePath;
        log?.call("Found bundled exe: $scriptPath");
      } else if (await File(releasePyPath).exists()) {
         // Fallback to python script if exe missing (shouldn't happen if bundled correctly)
         scriptPath = releasePyPath;
         useSystemPython = true;
         log?.call("Bundled exe not found, using script: $scriptPath");
      } else {
         // Fallback checks for dev environment
         if (await File('med_sync_desktop/assets/scripts/process_excel.exe').exists()) {
              scriptPath = 'med_sync_desktop/assets/scripts/process_excel.exe';
         } else if (await File('assets/scripts/process_excel.exe').exists()) {
              scriptPath = 'assets/scripts/process_excel.exe';
         } else if (await File('med_sync_desktop/assets/scripts/process_excel.py').exists()) {
              scriptPath = 'med_sync_desktop/assets/scripts/process_excel.py';
              useSystemPython = true;
         } else if (await File('assets/scripts/process_excel.py').exists()) {
              scriptPath = 'assets/scripts/process_excel.py';
              useSystemPython = true;
         } else {
             // Try absolute path if all else fails (debug help)
             scriptPath = 'assets/scripts/process_excel.py'; 
             useSystemPython = true; 
         }
      }
    } catch (e) {
      log?.call("Error resolving script path: $e");
      useSystemPython = true; // Default safety
    }

    try {
        ProcessResult result;
        if (useSystemPython) {
            result = await Process.run('python', [scriptPath, path, fileType]);
        } else {
            result = await Process.run(scriptPath, [path, fileType]);
        }
        
        if (result.exitCode != 0) {
            log?.call("Python Error: ${result.stderr}");
            // Handle if output has error json
            try {
               final errJson = jsonDecode(result.stdout.toString());
               if (errJson is Map && errJson.containsKey('error')) {
                   log?.call("Script Error: ${errJson['error']}");
               }
            } catch (_) {}
            return [];
        }
        
        final String output = result.stdout.toString();
        // log?.call("Python Output: ${output.substring(0, 100)}..."); 
        
        final decoded = jsonDecode(output);
        if (decoded is Map && decoded.containsKey('error')) {
             log?.call("Script returned error: ${decoded['error']}");
             return [];
        }
        
        if (decoded is List) {
             return List<Map<String, dynamic>>.from(decoded);
        }
        
        return [];
        
    } catch (e) {
        log?.call("Process Exception: $e");
        return [];
    }
  }
}
