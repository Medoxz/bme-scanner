import 'dart:convert';
import 'package:bme_scanner/pages/Components/json_updater.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllergyState extends ChangeNotifier {
  static const String _prefsKey = 'selected_allergies';

  Set<String> selectedAllergies = {};
  List<Map<String, dynamic>> allergies = [
    {
      "stof": "Example Allergen 1",
      "file": "Allergie voor Example",
      "synoniemen": ["Alternative 1", "Alternative 2"],
    },
  ];

  final JsonUpdater jsonUpdater = JsonUpdater(
    googleDriveFileId: '1BnWPiWg9KjV-_mv7yYYm20R74Xg5Mnj7',
  );

  AllergyState() {
    _loadSelectedAllergies();
    _loadAllergies();
  }

  bool isSelected(String allergy) {
    return selectedAllergies.contains(allergy);
  }

  void setSelected(String allergy, bool value) {
    if (value) {
      selectedAllergies.add(allergy);
    } else {
      selectedAllergies.remove(allergy);
    }
    _saveSelectedAllergies();
    notifyListeners();
  }

  Future<void> _loadSelectedAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? [];

    selectedAllergies
      ..clear()
      ..addAll(stored);

    notifyListeners();
  }

  Future<void> _saveSelectedAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, selectedAllergies.toList());
  }

  Future<void> _loadAllergies() async {
    List<dynamic> jsonData = [];

    // Try reading local copy first
    jsonData = await jsonUpdater.readLocalJson('allergies.json');

    // If local copy does not exist or is empty, fall back to assets
    if (jsonData.isEmpty) {
      final jsonString = await rootBundle.loadString(
        'assets/Data_app_export.json',
      );
      jsonData = json.decode(jsonString);
    }

    // Update state immediately to display allergies
    allergies = List<Map<String, dynamic>>.from(jsonData);
    notifyListeners();

    //    In the background, try fetching latest JSON from Google Drive
    //    This does NOT block the UI
    jsonUpdater.updateJsonFile('allergies.json').then((file) async {
      if (file != null) {
        // Optionally, you could reload the UI with new data
        final newData = await jsonUpdater.readLocalJson('allergies.json');
        if (newData.isNotEmpty) {
          allergies = List<Map<String, dynamic>>.from(newData);
          notifyListeners();
        }
      }
    });
  }
}
