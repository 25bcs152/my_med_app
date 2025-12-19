import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

class ExcelParser {
  dynamic _getCellValue(CellValue? value) {
    if (value == null) return null;
    if (value is TextCellValue) {
      return value.value;
    } else if (value is IntCellValue) {
      return value.value;
    } else if (value is DoubleCellValue) {
      return value.value;
    } else if (value is DateTimeCellValue) {
      // DateTimeCellValue has asDateTimeLocal() method
      try {
        return value.asDateTimeLocal();
      } catch (e) {
        return value.toString();
      }
    } else if (value is DateCellValue) {
      // DateCellValue in excel 4.x has year, month, day properties
      try {
        // Construct DateTime - ensure correct order: year, month, day
        final dt = DateTime(value.year, value.month, value.day);
        return dt;
      } catch (e) {
        // Fallback: try toString and parse
        return value.toString();
      }
    }
    return value.toString();
  }

  // Normalize header similar to Python's normalize_header_key
  String _normalize(String header) {
    return header.trim().toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
  }

  // Smart mapping based on Python logic
  String? _mapHeader(String original, {required bool isMarg}) {
    final nk = _normalize(original);
    
    if (isMarg) {
       // Marg (Medicine 1) STRICT Fields: "Product Name", "Current Stock", "M.R.P.", "EXP"
       if (['productname', 'product', 'product_name', 'name'].contains(nk)) return 'Product Name';
       if (['productname_kn', 'product_name_kn', 'kan_name', 'trans'].contains(nk)) return 'Product Name_kn'; // Added for Translation
       
       if (['currentstock', 'current_stock', 'stock', 'quantity', 'closingstock', 'qty', 'opening'].contains(nk)) return 'Current Stock'; // Added 'opening'
       
       if (nk.contains('mrp') || ['m.r.p', 'mrp.', 'm_r_p', 'price', 'rate'].contains(nk)) return 'M.R.P.';
       
       if (nk == 'exp' || nk.startsWith('exp') || nk.contains('expiry') || nk == 'bb') return 'EXP';
    } else {
       // PMBI (Medicine 2) STRICT Fields: "Drug Code", "Drug Name", "UOM", "Batch No", "Expiry Date", "Qty", "MRP"
       if (nk.contains('drugcode') || nk == 'code') return 'Drug Code';
       
       if (nk.contains('drugname') || (nk.contains('drug') && nk.contains('name')) || nk == 'productname') return 'Drug Name';
       if (['drugname_kn', 'drug_name_kn', 'kan_name'].contains(nk)) return 'Drug Name_kn'; // Added for Translation
       
       if (nk == 'uom' || nk.contains('unit')) return 'UOM';
       if (nk.contains('batch')) return 'Batch No';
       if (nk == 'expirydate' || nk.contains('expiry') || nk == 'exp') return 'Expiry Date';
       if (['qty', 'quantity', 'qnty', 'stock'].contains(nk)) return 'Qty'; 
       if (nk.contains('mrp') || ['m.r.p', 'mrp.', 'm_r_p', 'price'].contains(nk)) return 'MRP';
    }
    return null; // Strict: ignore other fields
  }

  // Parse number, int, date similar to Python utilities
  double? _parseNumber(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '').trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    final s = v.toString().replaceAll(',', '').trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final formats = [
      DateFormat('dd/MM/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd/MM/yy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd.MM.yyyy'), 
      DateFormat('dd.MM.yy'),   
      DateFormat('dd-MMM-yyyy'),
      DateFormat('dd-MMM-yy'), // Added for '01-Jun-27'
    ];
    for (var fmt in formats) {
      try {
        return fmt.parseStrict(s);
      } catch (_) {}
    }
    // fallback using DateTime.parse (may handle ISO)
    try {
      return DateTime.parse(s);
    } catch (_) {}
    return null;
  }

  /// Reads an Excel file and returns a list of rows (as maps) and the detected column headers.
  Future<List<Map<String, dynamic>>> parseFile(String path, String collectionName, {Function(String)? log}) async {
    log?.call("Opening file: $path");
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    // Assume first sheet
    if (excel.tables.isEmpty) {
        log?.call("No sheets found in Excel file.");
        return [];
    }
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) {
        log?.call("First sheet is null.");
        return [];
    }
    
    // BLIND DEBUG: Log first 5 rows to see what's actually in the file
    log?.call("--- RAW EXCEL DUMP (First 5 rows) ---");
    for (int i = 0; i < 5 && i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        final rowData = row.map((c) => _getCellValue(c?.value)?.toString() ?? '').toList();
        log?.call("Row $i: $rowData");
    }
    log?.call("--- END DUMP ---");

    // Detect header row by looking for known keywords
    int headerRowIdx = -1; // Default to -1 to know if we found something
    int maxMatches = 0;
    
    // Keywords to look for (normalized)
    final keywords = ['product', 'name', 'mrp', 'stock', 'qty', 'quantity', 'batch', 'expiry', 'exp', 'rate', 'drug'];
    
    for (int i = 0; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        int matches = 0;
        for (final cell in row) {
          if (cell == null) continue;
          final val = _getCellValue(cell.value)?.toString().toLowerCase() ?? '';
          if (keywords.any((k) => val.contains(k))) {
            matches++;
          }
        }
      
      // If we find a row with multiple matches, it's likely the header
      if (matches > maxMatches) {
        maxMatches = matches;
        headerRowIdx = i;
      }
    }
    
    if (headerRowIdx != -1) {
        log?.call("Found header at row $headerRowIdx with $maxMatches keyword matches.");
    }

    // If no good match found, fall back to first non-empty
    if (headerRowIdx == -1 || maxMatches == 0) {
        log?.call("No robust header match found. Falling back to first non-empty row.");
        for (int i = 0; i < sheet.maxRows; i++) {
           final row = sheet.row(i);
           if (row.any((cell) => _getCellValue(cell?.value)?.toString().trim().isNotEmpty ?? false)) {
             headerRowIdx = i;
             break;
           }
        }
    }
    
    if (headerRowIdx == -1) headerRowIdx = 0; // Absolute fallback
    log?.call("Using row $headerRowIdx as header.");

    final rawHeaders = sheet.row(headerRowIdx).map((c) => _getCellValue(c?.value)?.toString() ?? '').toList();
    log?.call("Raw headers detected: $rawHeaders");
    
    // Verify we are matching intent
    final isMarg = collectionName.contains('medicine_1');
    final headerMap = <int, String>{};
    for (int i = 0; i < rawHeaders.length; i++) {
      final header = rawHeaders[i];
      if (header.isEmpty) continue;
      
      final mapped = _mapHeader(header, isMarg: isMarg);
      if (mapped != null) {
        headerMap[i] = mapped;
      }
      // Strict: If mapped is null, we IGNORE this column entirely.
    }
    log?.call("Mapped headers: $headerMap");
    // Base candidates for document ID
    final baseCandidates = collectionName == 'medicine-1'
        ? ['Product Name', 'ProductName', 'product name', 'Product', 'name']
        : ['Drug Name', 'DrugName', 'drug name', 'Drug', 'name'];
    final rows = <Map<String, dynamic>>[];
    for (int i = headerRowIdx + 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      // Check for empty row using helper
      if (row.every((c) {
          final v = _getCellValue(c?.value);
          return v == null || v.toString().trim().isEmpty;
      })) continue; 

      final map = <String, dynamic>{};
      for (int j = 0; j < row.length; j++) {
        final val = _getCellValue(row[j]?.value);
        if (headerMap.containsKey(j)) {
          final key = headerMap[j]!;
          // parse based on key type
          if (['M.R.P.', 'MRP'].contains(key)) {
            double? d = _parseNumber(val);
            if (d != null) {
                map[key] = d.toStringAsFixed(2); // Convert to String "XX.YY"
            } else {
                map[key] = null;
            }
          } else if (['Current Stock', 'Qty'].contains(key)) {
             int? i = _parseInt(val);
             if (i != null) {
                 map[key] = i.toString(); // Convert to String
             } else {
                 map[key] = null; // or "0"? Mobile uses String? so null is fine.
             }
          } else if (key == 'EXP') {
             // Medicine-1 (Marg): Format as dd-MM-yy
             var d = _parseDate(val);
             if (d != null) {
               map[key] = DateFormat('dd-MM-yy').format(d);
             } else {
               String? rawStr = val?.toString().trim();
               if (rawStr != null && rawStr.length == 8 && RegExp(r'^\d{8}$').hasMatch(rawStr)) {
                 // ddmmyyyy -> ddmmyy
                 map[key] = rawStr.substring(0, 6);
               } else {
                 map[key] = rawStr;
               }
             }
          } else if (key == 'Expiry Date') {
             // Medicine-2 (PMBI): Format as dd-MM-yy (same as Medicine-1)
             var d = _parseDate(val);
             if (d != null) {
               map[key] = DateFormat('dd-MM-yy').format(d);
             } else {
               String? rawStr = val?.toString().trim();
               if (rawStr != null && rawStr.length == 8 && RegExp(r'^\d{8}$').hasMatch(rawStr)) {
                 // Convert ddmmyyyy to ddmmyy
                 // Example: "01122028" -> "011228"
                 map[key] = rawStr.substring(0, 6); // ddmmyy
               } else {
                 map[key] = rawStr;
               }
             }
          } else {
             // For unknown columns, try to keep original type or generic parse if string
             map[key] = val;
          }
        }
      }
      // Determine base value for doc ID
      String? baseVal;
      for (var cand in baseCandidates) {
        if (map.containsKey(cand) && map[cand] != null && map[cand].toString().trim().isNotEmpty) {
          baseVal = map[cand].toString();
          break;
        }
      }
      if (baseVal == null) {
        // Fallback: search any key containing name+product/drug
        map.forEach((k, v) {
          final nk = k.toLowerCase();
          if ((nk.contains('name') && (nk.contains('product') || nk.contains('drug'))) && v != null) {
            baseVal = v.toString();
          }
        });
      }
      
      if (baseVal == null || baseVal!.trim().isEmpty) {
        // STRICT: If no name found, skip this row. Do not create UNKNOWN items.
        log?.call("Row $i: Skipped (No valid Product/Drug Name found). Data: $map");
        continue;
      }

      // sanitize doc id similar to python's sanitize_doc_id
      String docId = baseVal!.replaceAll('/', '-').replaceAll('\\', '-').trim();
      docId = docId.length > 200 ? docId.substring(0, 200) : docId;
      docId = docId.replaceAll(RegExp(r'[^\w\-. ]'), '_');
      
      // Additional safety: Ensure ID is not empty after sanitization
      if (docId.isEmpty) continue;
      
      map['_id'] = docId;
      rows.add(map);
    }
    return rows;
  }
}
