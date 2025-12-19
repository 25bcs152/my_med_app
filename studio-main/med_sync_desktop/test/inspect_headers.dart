
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Inspect Excel Headers', () {
    final files = [
      r"c:\New folder\studio-main\xlsx\stock_REPORTS MARG AS ON 03.12.25.xlsx",
      r"c:\New folder\studio-main\xlsx\PMBI STOCK REOPRTS AS ON 02.12.25.xlsx"
    ];

    for (var path in files) {
      print('Processing: $path');
      var bytes = File(path).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      if (excel.tables.isNotEmpty) {
        var sheet = excel.tables[excel.tables.keys.first];
        if (sheet != null && sheet.maxRows > 0) {
           // Find first non-empty row to treat as header
           List<String> headers = [];
           for(int i=0; i<min(5, sheet.maxRows); i++) {
               var row = sheet.row(i);
               var rowValues = row.map((e) => e?.value.toString() ?? '').toList();
               print('Row $i: $rowValues');
               
               // Heuristic: if row has "Product" or "Name", it's likely header
               if (rowValues.any((s) => s.toLowerCase().contains('product') || s.toLowerCase().contains('name') || s.toLowerCase().contains('stock'))) {
                   headers = rowValues;
               }
           }
           print('Potential Headers: $headers');
        }
      }
      print('---');
    }
  });
}

int min(int a, int b) => a < b ? a : b;
