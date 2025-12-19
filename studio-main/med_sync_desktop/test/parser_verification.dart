import 'package:flutter_test/flutter_test.dart';
import 'package:med_sync_desktop/services/excel_parser.dart';
import 'dart:io';

void main() {
  final parser = ExcelParser();

  test('Parse Marg File (stock_81.xls)', () async {
    final path = r'c:\New folder\studio-main\xlsx\stock_81.xls';
    print('\nTesting Marg parsing: $path');
    
    final data = await parser.parseFile(path, 'medicine_1_data', log: (s) => print('MARG_LOG: $s'));
    
    expect(data.isNotEmpty, true);
    print('Marg Items Parsed: ${data.length}');
    
    // Check first item
    final item = data.first;
    print('Marg First Item: $item');
    
    // Keys we expect for Medicine-1
    expect(item.containsKey('Product Name'), true);
    expect(item.containsKey('Current Stock'), true); 
    expect(item.containsKey('M.R.P.'), true);
    expect(item.containsKey('EXP'), true); // or Expiry Date if normalized
  });

  test('Parse PMBI File (StockReport.xlsx)', () async {
    final path = r'c:\New folder\studio-main\xlsx\StockReport.xlsx';
    print('\nTesting PMBI parsing: $path');
    
    final data = await parser.parseFile(path, 'medicine_2_data', log: (s) => print('PMBI_LOG: $s'));
    
    expect(data.isNotEmpty, true);
    print('PMBI Items Parsed: ${data.length}');
    
    final item = data.first;
    print('PMBI First Item: $item');
    
    // Keys for Medicine-2
    expect(item.containsKey('Drug Name'), true);
    expect(item.containsKey('Drug Code'), true); 
    expect(item.containsKey('MRP'), true);
    expect(item.containsKey('Expiry Date'), true);
    expect(item.containsKey('Qty'), true);
  });
}
