import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AllergyState.dart';
import 'ScanHistoryState.dart';

class OCRResultTile extends StatefulWidget {
  final String scanId;
  final String title;
  final String recognizedText;
  final File imageFile;

  const OCRResultTile({
    super.key,
    required this.scanId,
    required this.title,
    required this.recognizedText,
    required this.imageFile,
  });

  @override
  State<OCRResultTile> createState() => _OCRResultTileState();
}

class _OCRResultTileState extends State<OCRResultTile> {
  void _showBottomSheet(BuildContext context) async {
    // Read selected allergies at the time of opening
    Set<String> selectedAllergies = context
        .read<AllergyState>()
        .selectedAllergies;
    List<Map<String, dynamic>> allergies = context
        .read<AllergyState>()
        .allergies;

    final double maxHeight = MediaQuery.of(context).size.height * 0.85;
    final double width = MediaQuery.of(context).size.width * 0.95;

    // Controllers created here so we can save on explicit Save press and dispose afterwards
    final TextEditingController textController = TextEditingController(
      text: widget.recognizedText,
    );
    final TextEditingController titleController = TextEditingController(
      text: widget.title,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Use StatefulBuilder to allow local setState for sheet UI
        return StatefulBuilder(
          builder: (context, setState) {
            String lowerText = textController.text.toLowerCase();

            List<Map<String, String>> selectedAllergySynonyms = allergies
                .where((a) => selectedAllergies.contains(a['stof']))
                .expand((a) {
                  final String parent = (a['stof'] ?? '').toString();
                  final List<dynamic> rawSyns =
                      (a['synoniemen'] as List<dynamic>?) ?? [];
                  // include the parent name itself plus all synonyms
                  final Iterable<String> allCandidates = [
                    parent,
                    ...rawSyns.map((s) => s.toString()),
                  ];
                  return allCandidates.map(
                    (syn) => {'allergy': parent, 'synonym': syn},
                  );
                })
                .toList();

            List<String> matchedAllergies = selectedAllergySynonyms
                .where(
                  (allergy) =>
                      lowerText.contains(allergy['synonym']!.toLowerCase()),
                )
                .map(
                  (allergy) =>
                      '${allergy['synonym']} ( van: ${allergy['allergy']})',
                )
                .toSet()
                .toList();

            bool hasMatches = matchedAllergies.isNotEmpty;

            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: width,
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 4,
                      color: Color(0x1A000000),
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Replace the existing Row(...) with this ---
                      SizedBox(
                        height: 40,
                        child: Stack(
                          children: [
                            // centered drag handle
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Save button at top-right
                            Positioned(
                              right: 0,
                              top: 0,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(48, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  Provider.of<ScanHistoryState>(
                                    context,
                                    listen: false,
                                  ).editScan(
                                    widget.scanId,
                                    title: titleController.text,
                                    recognizedText: textController.text,
                                    allergensDetected: hasMatches,
                                    matchedAllergens: matchedAllergies,
                                  );
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Row: editable title (left) + status icon (right)
                      Row(
                        children: [
                          // left half: editable title (50%)
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: titleController,
                              decoration: InputDecoration(
                                hintText: 'Title',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              maxLines: 1,
                            ),
                          ),

                          // right half: status icon (50%)
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Icon(
                                hasMatches ? Icons.cancel : Icons.check_circle,
                                color: hasMatches ? Colors.red : Colors.green,
                                size: 56,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Image + allergen info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                widget.imageFile,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: hasMatches
                                ? Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: matchedAllergies
                                        .map(
                                          (allergy) => Chip(
                                            label: Text(
                                              allergy,
                                              maxLines: 2,
                                              softWrap: true,
                                            ),
                                            backgroundColor:
                                                Colors.red.shade100,
                                          ),
                                        )
                                        .toList(),
                                  )
                                : const Text(
                                    "No allergens detected",
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Recognized Text",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Expanded scrollable editable text area
                      Expanded(
                        child: SingleChildScrollView(
                          child: TextField(
                            controller: textController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Edit recognized text here...",
                            ),
                            onChanged: (_) {
                              // trigger rebuild of sheet UI to update matches
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GestureDetector(
        onTap: () => _showBottomSheet(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                blurRadius: 4,
                color: Color(0x1A000000),
                offset: Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.edit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
