import 'package:cloud_firestore/cloud_firestore.dart';

abstract class Medicine {
  String get id;
  String? get expiryDateAsString;
}

class Medicine1 implements Medicine {
  @override
  final String id;
  final String productName;
  final String productNameKn;
  final String? currentStock;
  final String? mrp;
  // Handling flexible expiry types from Firestore (String, Number, Timestamp)
  final dynamic expiryRaw;

  Medicine1({
    required this.id,
    required this.productName,
    required this.productNameKn,
    this.currentStock,
    this.mrp,
    this.expiryRaw,
  });

  factory Medicine1.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medicine1(
      id: doc.id,
      productName: data['Product Name'] ?? data['Product_Name'] ?? '',
      productNameKn: data['Product Name_kn'] ?? data['Product Name_Kn'] ?? data['Product Name_KN'] ?? data['Product_Name_kn'] ?? '',
      currentStock: data['Current Stock']?.toString(),
      mrp: _formatMRP(data['M.R.P.'] ?? data['MRP']),
      expiryRaw: data['EXP'] ?? data['Expiry Date'],
    );
  }

  @override
  String? get expiryDateAsString {
    if (expiryRaw == null) return null;
    if (expiryRaw is String) return expiryRaw;
    if (expiryRaw is Timestamp) return (expiryRaw as Timestamp).toDate().toString();
    return expiryRaw.toString();
  }
  
  factory Medicine1.fromJson(Map<String, dynamic> json) {
    return Medicine1(
      id: json['id']?.toString() ?? '',
      productName: json['Product Name']?.toString() ?? '',
      productNameKn: json['Product Name_kn']?.toString() ?? '',
      currentStock: json['Current Stock']?.toString(),
      mrp: _formatMRP(json['M.R.P.']), // Apply formatting
      expiryRaw: json['EXP'], 
    );
  }

  Map<String, dynamic> toJson() {
    dynamic exp = expiryRaw;
    if (exp is Timestamp) {
      exp = exp.toDate().toIso8601String();
    }
    return {
      'id': id,
      'Product Name': productName,
      'Product Name_kn': productNameKn,
      'Current Stock': currentStock,
      'M.R.P.': mrp,
      'EXP': exp,
      'type': 'med1', 
    };
  }
}

class Medicine2 implements Medicine {
  @override
  final String id;
  final String drugCode;
  final String drugName;
  final String drugNameKn;
  final String? uom;
  final String? batchNo;
  final String? qty;
  final String? mrp;
  final dynamic expiryRaw;

  Medicine2({
    required this.id,
    required this.drugCode,
    required this.drugName,
    required this.drugNameKn,
    this.uom,
    this.batchNo,
    this.qty,
    this.mrp,
    this.expiryRaw,
  });

  factory Medicine2.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medicine2(
      id: doc.id,
      drugCode: data['Drug Code'] ?? '',
      drugName: data['Drug Name'] ?? data['Drug_Name'] ?? '',
      drugNameKn: data['Drug Name_kn'] ?? data['Drug Name_Kn'] ?? data['Drug Name_KN'] ?? data['Drug_Name_kn'] ?? '',
      uom: data['UOM'],
      batchNo: data['Batch No'],
      qty: data['Qty']?.toString(),
      mrp: _formatMRP(data['MRP'] ?? data['M.R.P.']),
      expiryRaw: data['Expiry Date'] ?? data['EXP'],
    );
  }
  
  @override
  String? get expiryDateAsString {
    if (expiryRaw == null) return null;
    if (expiryRaw is String) return expiryRaw;
    if (expiryRaw is Timestamp) return (expiryRaw as Timestamp).toDate().toString();
    return expiryRaw.toString();
  }

  factory Medicine2.fromJson(Map<String, dynamic> json) {
    return Medicine2(
      id: json['id']?.toString() ?? '',
      drugCode: json['Drug Code']?.toString() ?? '',
      drugName: json['Drug Name']?.toString() ?? '',
      drugNameKn: json['Drug Name_kn']?.toString() ?? '',
      uom: json['UOM']?.toString(),
      batchNo: json['Batch No']?.toString(),
      qty: json['Qty']?.toString(),
      mrp: _formatMRP(json['MRP']), // Apply formatting
      expiryRaw: json['Expiry Date'],
    );
  }

  Map<String, dynamic> toJson() {
    dynamic exp = expiryRaw;
    if (exp is Timestamp) {
      exp = exp.toDate().toIso8601String();
    }
    return {
      'id': id,
      'Drug Code': drugCode,
      'Drug Name': drugName,
      'Drug Name_kn': drugNameKn,
      'UOM': uom,
      'Batch No': batchNo,
      'Qty': qty,
      'MRP': mrp,
      'Expiry Date': exp,
      'type': 'med2', 
    };
  }
}

String? _formatMRP(dynamic value) {
  if (value == null) return null;
  double? numValue;
  
  if (value is num) {
    numValue = value.toDouble();
  } else if (value is String) {
    numValue = double.tryParse(value);
  }
  
  if (numValue != null) {
    // "At most 2 decimal points" implementation:
    // 12.00 -> 12
    // 12.50 -> 12.5
    // 12.54 -> 12.54
    String s = numValue.toStringAsFixed(2);
    if (s.endsWith('.00')) {
      return s.substring(0, s.length - 3);
    }
    if (s.endsWith('0') && s.contains('.')) {
      return s.substring(0, s.length - 1);
    }
    return s;
  }
  
  return value.toString();
}
