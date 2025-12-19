import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Inspect Headers', () async {
    final files = [
      r'C:\New folder\studio-main\xlsx\stock_REPORTS MARG AS ON 03.12.25.xlsx',
      // r'C:\New folder\studio-main\xlsx\PMBI STOCK REOPRTS AS ON 02.12.25.xlsx',
    ];

    for (var path in files) {
      print('\n--- Inspecting $path ---');
      final bytes = File(path).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        print('No sheets found');
        continue;
      }
      final sheet = excel.tables[excel.tables.keys.first]!;
      // Print first 5 rows to find header
      for (var i = 0; i < 15; i++) {
        if (i >= sheet.maxRows) break;
        final row = sheet.row(i);
        final values = row.map((cell) => cell?.value.toString()).toList();
        print('Row $i: $values');
      }
    }
  });
}
