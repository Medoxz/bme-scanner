import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Components/allergy_listing.dart';
import 'Components/json_updater.dart';

class AllergiesSelectPage extends StatefulWidget {
  const AllergiesSelectPage({super.key});

  static const routeName = '/allergiesSelect';

  @override
  State<AllergiesSelectPage> createState() => _AllergiesSelectPageState();
}

class _AllergiesSelectPageState extends State<AllergiesSelectPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Sample allergy list; replace with your real data source
  List<Map<String, dynamic>> _allergies = [
    {
      "chemical_name": "Example Allergen 1",
      "file": "Allergie voor Example",
      "alternative_names": ["Alternative 1", "Alternative 2"],
    },
  ];

  final JsonUpdater jsonUpdater = JsonUpdater(
    googleDriveFileId: '1BnWPiWg9KjV-_mv7yYYm20R74Xg5Mnj7',
  );

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllergies();
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
    setState(() {
      _allergies = List<Map<String, dynamic>>.from(jsonData);
    });

    //    In the background, try fetching latest JSON from Google Drive
    //    This does NOT block the UI
    jsonUpdater.updateJsonFile('allergies.json').then((file) async {
      if (file != null) {
        // Optionally, you could reload the UI with new data
        final newData = await jsonUpdater.readLocalJson('allergies.json');
        if (newData.isNotEmpty) {
          setState(() {
            _allergies = List<Map<String, dynamic>>.from(newData);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter allergies based on search query
    final filtered = _allergies.where((item) {
      final name = item["stof"] ?? "";
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Allergies'),
          centerTitle: false,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                print('Info button pressed');
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ---------- Search Field ----------
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search allergies...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(width: 1),
                    ),
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // ---------- Allergy List ----------
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];

                      return AllergyListingWidget(
                        allergyName:
                            item["stof"] ??
                            '', // Fallback to empty string if stof is null
                        alternativeNames:
                            (item["synoniemen"] as List?)
                                ?.whereType<
                                  String
                                >() // Only keep elements that are Strings
                                .toList() ??
                            [], // Fallback to empty list if synonyms is null
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
