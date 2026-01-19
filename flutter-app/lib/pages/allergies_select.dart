import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Components/AllergyState.dart';
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

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allergyState = context.watch<AllergyState>();

    // Filter allergies based on search query
    final filtered = allergyState.allergies.where((item) {
      final name = item["stof"] ?? "";
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jouw Allergieën'),
          centerTitle: false,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Allergie Informatie'),
                    content: const Text(
                      'Selecteer je allergieën uit de lijst. \n\n'
                      'Je kunt zoeken naar specifieke allergieën met de zoekbalk. \n\n'
                      'Deze selecties worden gebruikt om mogelijke allergenen in gescande producten te identificeren.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
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
                    hintText: 'Zoek allergieën...',
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
                      final name = item["stof"] ?? "";

                      return AllergyListingWidget(
                        item: item,
                        isSelected: allergyState.isSelected(name),
                        onChanged: (isSelected) {
                          allergyState.setSelected(name, isSelected);
                        },
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
