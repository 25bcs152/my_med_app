import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

class ExcelParser {
  // Normalize header similar to Python's normalize_header_key
  String _normalize(String header) {
    return header.trim().toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
  }

  // Smart mapping based on Python logic
  String? _mapHeader(String original) {
    final nk = _normalize(original);
    // MARG mappings
    if (['productname', 'product', 'product_name', 'name'].contains(nk)) return 'Product Name';
    if (['currentstock', 'current_stock', 'stock', 'quantity'].contains(nk)) return 'Current Stock';
    if (nk.contains('mrp') || ['m.r.p', 'mrp.', 'm_r_p', 'price', 'rate'].contains(nk)) return 'M.R.P.';
    if (nk == 'exp' || nk.startsWith('exp') || nk.contains('expiry') || nk == 'bb') return 'EXP';
    // PMBI mappings
    if (nk.contains('drugcode') || nk == 'code') return 'Drug Code';
    if (nk.contains('drugname') || (nk.contains('drug') && nk.contains('name'))) return 'Drug Name';
    if (nk == 'uom') return 'UOM';
    if (nk.contains('batch')) return 'Batch No';
    if (['qty', 'quantity', 'qnty'].contains(nk)) return 'Qty';
    // MRP for PMBI
    if (nk.contains('mrp') && nk != 'm.r.p') return 'MRP';
    return null;
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
  Future<List<Map<String, dynamic>>> parseFile(String path, String collectionName) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    // Assume first sheet
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return [];
    // Detect header row (similar to Python auto-detect)
    int headerRowIdx = 0;
    // Simple heuristic: first row with at least one non-empty string
    for (int i = 0; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.any((cell) => cell != null && cell.value != null && cell.value.toString().trim().isNotEmpty)) {
        headerRowIdx = i;
        break;
      }
    }
    final rawHeaders = sheet.row(headerRowIdx).map((c) => c?.value?.toString() ?? '').toList();
    // Map headers to canonical names
    final headerMap = <int, String>{};
    for (int i = 0; i < rawHeaders.length; i++) {
      final mapped = _mapHeader(rawHeaders[i]);
      if (mapped != null) headerMap[i] = mapped;
    }
    // Base candidates for document ID
    final baseCandidates = collectionName == 'medicine-1'
        ? ['Product Name', 'ProductName', 'product name', 'Product', 'name']
        : ['Drug Name', 'DrugName', 'drug name', 'Drug', 'name'];
    final rows = <Map<String, dynamic>>[];
    for (int i = headerRowIdx + 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.every((c) => c == null || c.value == null || c.value.toString().trim().isEmpty)) continue; // skip empty
      final map = <String, dynamic>{};
      for (int j = 0; j < row.length; j++) {
        final val = row[j]?.value;
        if (headerMap.containsKey(j)) {
          final key = headerMap[j]!;
          // parse based on key type
          if (['M.R.P.', 'MRP'].contains(key)) {
            map[key] = _parseNumber(val);
          } else if (['Current Stock', 'Qty'].contains(key)) {
            map[key] = _parseInt(val);
          } else if (['EXP', 'Expiry Date'].contains(key)) {
            map[key] = _parseDate(val);
          } else {
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
      // fallback: search any key containing name+product/drug
      if (baseVal == null) {
        map.forEach((k, v) {
          final nk = k.toLowerCase();
          if ((nk.contains('name') && (nk.contains('product') || nk.contains('drug'))) && v != null) {
            baseVal = v.toString();
          }
        });
      }
      if (baseVal == null) continue; // skip if no ID
      // sanitize doc id similar to python's sanitize_doc_id
      String docId = baseVal!.replaceAll('/', '-').replaceAll('\\', '-').trim();
      docId = docId.length > 200 ? docId.substring(0, 200) : docId;
      docId = docId.replaceAll(RegExp(r'[^\w\-. ]'), '_');
      map['_id'] = docId;
      rows.add(map);
    }
    return rows;
  }
}
