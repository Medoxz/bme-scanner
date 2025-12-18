import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class JsonUpdater {
  final String googleDriveFileId;

  JsonUpdater({required this.googleDriveFileId});

  /// Fetches JSON from Google Drive and saves it to app's documents directory
  Future<File?> updateJsonFile(String fileName) async {
    try {
      // Construct Google Drive download URL
      final url = Uri.parse(
        'https://drive.google.com/uc?export=download&id=$googleDriveFileId',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonString = response.body;

        // Get app's documents directory
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');

        await file.writeAsString(jsonString);

        debugPrint('JSON updated successfully at ${file.path}');
        return file;
      } else {
        debugPrint('Failed to fetch JSON: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error updating JSON: $e');
      return null;
    }
  }

  /// Reads the locally saved JSON file
  Future<List<dynamic>> readLocalJson(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return json.decode(jsonString);
      } else {
        debugPrint('Local JSON file does not exist');
        return [];
      }
    } catch (e) {
      debugPrint('Error reading local JSON: $e');
      return [];
    }
  }
}
