import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';

class AppState extends ChangeNotifier {
  String _language = 'english'; // Default changed to English
  List<Medicine> _myMedicines = [];

  String get language => _language;
  List<Medicine> get myMedicines => _myMedicines;



  AppState() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? medicinesString = prefs.getString('my_medicines');
    if (medicinesString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(medicinesString);
        _myMedicines = jsonList.map((json) {
          if (json['type'] == 'med1') {
            return Medicine1.fromJson(json);
          } else {
            return Medicine2.fromJson(json);
          }
        }).toList();
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading medicines: $e");
        // Optionally clear corrupted data
        // await prefs.remove('my_medicines');
      }
    }
    
    // Load language if saved (optional but good for consistency)
    // String? lang = prefs.getString('language');
    // if(lang != null) _language = lang;
  }

  Future<void> _saveMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_myMedicines.map((m) {
       if (m is Medicine1) return m.toJson();
       if (m is Medicine2) return m.toJson();
       return {};
    }).toList());
    await prefs.setString('my_medicines', jsonString);
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void addToMyMedicines(Medicine medicine) {
    if (_myMedicines.any((m) => m.id == medicine.id)) {
      return;
    }
    _myMedicines.add(medicine);
    _saveMedicines(); // Persist to ROM
    notifyListeners();
  }

  void removeFromMyMedicines(Medicine medicine) {
    _myMedicines.removeWhere((m) => m.id == medicine.id);
    _saveMedicines(); // Persist changes
    notifyListeners();
  }

  // Translation helper
  String t(String key) {
    final translations = {
      'app_title': {'english': 'Jan Aushadhi', 'kannada': 'ಜನ ಔಷಧಿ'},
      'app_subtitle': {
        'english': 'Generic Medicine Search',
        'kannada': 'ಜೌಷಧಿ ಹುಡುಕಾಟ'
      }, // Approximate translation
      'tab1_title': {'english': 'Generic', 'kannada': 'ಜೆನೆರಿಕ್'},
      'tab2_title': {'english': 'Jan Aushadhi', 'kannada': 'ಜನ ಔಷಧಿ'},
      'my_medicines': {'english': 'My Medicines', 'kannada': 'ನನ್ನ ಔಷಧಿಗಳು'},
      'search_placeholder_product': {
        'english': 'Search products...',
        'kannada': 'ಉತ್ಪನ್ನಗಳನ್ನು ಹುಡುಕಿ...'
      },
      'search_placeholder_drug': {
        'english': 'Search drugs...',
        'kannada': 'ಔಷಧಗಳನ್ನು ಹುಡುಕಿ...'
      },
      'search_my_medicines': {
        'english': 'Search my medicines...',
        'kannada': 'ನನ್ನ ಔಷಧಿಗಳನ್ನು ಹುಡುಕಿ...'
      },
       'mrp': {'english': 'MRP', 'kannada': 'ಬೆಲೆ'},
       'expiry': {'english': 'Expiry', 'kannada': 'ಅವಧಿ ಮುಕ್ತಾಯ'},
       'stock': {'english': 'Stock', 'kannada': 'ದಾಸ್ತಾನು'},
       'quantity': {'english': 'Quantity', 'kannada': 'ಪರಿಮಾಣ'},
       'uom': {'english': 'UOM', 'kannada': 'ಅಳತೆ'},
       'batch no': {'english': 'Batch No', 'kannada': 'ಬ್ಯಾಚ್ ಸಂಖ್ಯೆ'},
       'add': {'english': 'Add', 'kannada': 'ಸೇರಿಸಿ'},
       'added': {'english': 'Added', 'kannada': 'ಸೇರಿಸಲಾಗಿದೆ'},
       'add_to_my_medicines': {'english': 'Add to My Medicines', 'kannada': 'ನನ್ನ ಔಷಧಿಗಳಿಗೆ ಸೇರಿಸಿ'},
       'remove': {'english': 'Remove', 'kannada': 'ತೆಗೆದುಹಾಕಿ'},
       'removed': {'english': 'Removed', 'kannada': 'ತೆಗೆದುಹಾಕಲಾಗಿದೆ'},
    };

    if (translations.containsKey(key)) {
      return translations[key]![_language] ?? key;
    }
    return key;
  }
}
