import 'package:flutter_test/flutter_test.dart';
import 'package:med_sync_desktop/services/excel_parser.dart';
import 'dart:io';

void main() {
  test('Parse StockReport.xlsx (PMBI)', () async {
    final parser = ExcelParser();
    // Use absolute path
    final path = r'c:\New folder\studio-main\xlsx\StockReport.xlsx';
    
    print('Testing parsing of: $path');
    
    // We expect this to map to medicine_2_data
    final data = await parser.parseFile(path, 'medicine_2_data', log: (s) => print('LOG: $s'));
    
    print('Parsed ${data.length} items');
    
    if (data.isNotEmpty) {
      final first = data.first;
      print('First item keys: ${first.keys.toList()}');
      print('First item data: $first');
      
      expect(first.containsKey('Drug Code'), true);
      expect(first.containsKey('Drug Name'), true);
      expect(first.containsKey('UOM'), true);
      expect(first.containsKey('Batch No'), true);
      expect(first.containsKey('Expiry Date'), true);
      expect(first.containsKey('Qty'), true);
      expect(first.containsKey('MRP'), true);
    } else {
      fail('No data parsed');
    }
  });
}
