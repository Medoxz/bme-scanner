import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Components/allergy_listing.dart';

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

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllergies();
  }

  Future<void> _loadAllergies() async {
    final jsonString = await rootBundle.loadString(
      'assets/alternative_names_asz.json',
    );

    final List<dynamic> jsonData = json.decode(jsonString);

    setState(() {
      _allergies = List<Map<String, dynamic>>.from(jsonData);
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
      final name = item["chemical_name"] ?? "";
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
                        allergyName: item["chemical_name"],
                        alternativeNames: List<String>.from(
                          item["alternative_names"] ?? [],
                        ),
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
