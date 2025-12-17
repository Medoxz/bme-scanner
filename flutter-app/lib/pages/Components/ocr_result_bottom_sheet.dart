import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AllergyState.dart';

class OCRResultBottomSheet extends StatefulWidget {
  final File imageFile;
  final String recognizedText;

  const OCRResultBottomSheet({
    super.key,
    required this.imageFile,
    required this.recognizedText,
  });

  @override
  State<OCRResultBottomSheet> createState() => _OCRResultBottomSheetState();
}

class _OCRResultBottomSheetState extends State<OCRResultBottomSheet> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.recognizedText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAllergies = context.watch<AllergyState>().selectedAllergies;

    final lowerText = _textController.text.toLowerCase();

    final List<String> matchedAllergies = selectedAllergies
        .where((allergy) => lowerText.contains(allergy.toLowerCase()))
        .toList();

    final bool hasMatches = matchedAllergies.isNotEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              /// Centered status icon (no text)
              Center(
                child: Icon(
                  hasMatches ? Icons.cancel : Icons.check_circle,
                  color: hasMatches ? Colors.red : Colors.green,
                  size: 56,
                ),
              ),

              const SizedBox(height: 16),

              /// Image + allergen info side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Scanned image
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(widget.imageFile, fit: BoxFit.cover),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// Allergen details
                  Expanded(
                    flex: 1,
                    child: hasMatches
                        ? Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: matchedAllergies
                                .map(
                                  (allergy) => Chip(
                                    label: Text(allergy),
                                    backgroundColor: Colors.red.shade100,
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Edit recognized text here...",
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
