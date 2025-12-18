import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ScanHistoryState extends ChangeNotifier {
  static const String _prefsKey = 'scan_history';
  final List<ScanResult> _history = [];
  final _uuid = const Uuid();

  List<ScanResult> get history => List.unmodifiable(_history);

  ScanHistoryState() {
    loadFromPrefs();
  }

  // inside ScanHistoryState (addScan)
  void addScan({
    required String title,
    required String recognizedText,
    required File imageFile,
    required bool allergensDetected,
    required List<String> matchedAllergens,
    DateTime? timestamp, // optional param
  }) {
    final result = ScanResult(
      id: _uuid.v4(),
      title: title,
      recognizedText: recognizedText,
      imagePath: imageFile.path,
      allergensDetected: allergensDetected,
      matchedAllergens: matchedAllergens,
      timestamp: timestamp ?? DateTime.now(),
    );
    _history.insert(0, result);
    notifyListeners();
    saveToPrefs();
  }

  /// Edit a single scan result by ID
  void editScan(
    String id, {
    String? title,
    String? recognizedText,
    File? imageFile,
    bool? allergensDetected,
    List<String>? matchedAllergens,
    DateTime? timestamp,
  }) {
    final index = _history.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final old = _history[index];
    _history[index] = old.copyWith(
      title: title,
      recognizedText: recognizedText,
      imagePath: imageFile?.path,
      allergensDetected: allergensDetected,
      matchedAllergens: matchedAllergens,
      timestamp: timestamp,
    );
    notifyListeners();
    saveToPrefs();
  }

  /// Remove a scan result
  void removeScan(String id) {
    _history.removeWhere((r) => r.id == id);
    notifyListeners();
    saveToPrefs();
  }

  /// Clear all history
  void clearHistory() {
    _history.clear();
    notifyListeners();
    saveToPrefs();
  }

  /// Save to SharedPreferences
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_history.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
    print('Saved scan history to prefs.');
  }

  /// Load from SharedPreferences
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data == null) return;

    final List<dynamic> jsonList = jsonDecode(data);
    _history.clear();
    _history.addAll(jsonList.map((e) => ScanResult.fromJson(e)));
    notifyListeners();
  }
}

class ScanResult {
  final String id;
  final String title;
  final String recognizedText;
  final String imagePath;
  final bool allergensDetected;
  final List<String> matchedAllergens;
  final DateTime timestamp;

  ScanResult({
    required this.id,
    required this.title,
    required this.recognizedText,
    required this.imagePath,
    required this.allergensDetected,
    required this.matchedAllergens,
    required this.timestamp,
  });

  ScanResult copyWith({
    String? title,
    String? recognizedText,
    String? imagePath,
    bool? allergensDetected,
    List<String>? matchedAllergens,
    DateTime? timestamp,
  }) {
    return ScanResult(
      id: id,
      title: title ?? this.title,
      recognizedText: recognizedText ?? this.recognizedText,
      imagePath: imagePath ?? this.imagePath,
      allergensDetected: allergensDetected ?? this.allergensDetected,
      matchedAllergens: matchedAllergens ?? this.matchedAllergens,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'recognizedText': recognizedText,
    'imagePath': imagePath,
    'allergensDetected': allergensDetected,
    'matchedAllergens': matchedAllergens,
    'timestamp': timestamp.toIso8601String(), // store as ISO string
  };

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'],
      title: json['title'],
      recognizedText: json['recognizedText'],
      imagePath: json['imagePath'],
      allergensDetected: json['allergensDetected'],
      matchedAllergens: List<String>.from(json['matchedAllergens']),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  File get imageFile => File(imagePath);
}
