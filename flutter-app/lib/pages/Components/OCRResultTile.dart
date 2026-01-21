import 'dart:io';
import 'package:bme_scanner/pages/Components/HighlightTextController.dart';
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
    final HighlightTextController textController = HighlightTextController(
      matchedAllergies: [],
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
                  final List<dynamic> rawKruis =
                      (a['kruisreacties'] as List<dynamic>?) ?? [];
                  final List<dynamic> rawAll = [...rawSyns, ...rawKruis];
                  // include the parent name itself plus all synonyms
                  final Iterable<String> allCandidates = [
                    parent,
                    ...rawAll.map((s) => s.toString()),
                  ];
                  return allCandidates.map(
                    (syn) => {'allergy': parent, 'synonym': syn},
                  );
                })
                .toList();

            List<Map<String, String>> matchedAllergies = selectedAllergySynonyms
                .where(
                  (allergy) =>
                      lowerText.contains(allergy['synonym']!.toLowerCase()),
                )
                .map(
                  (allergy) => allergy,
                )
                .toSet()
                .toList();

            List<Map<String, String>> distinctMatchedAllergies = matchedAllergies
                .fold<List<Map<String, String>>>([], (acc, allergy) {
              if (!acc.any((a) => a['synonym'] == allergy['synonym'])) {
                acc.add(allergy);
              }
              return acc;
            });

            textController.matchedAllergies = distinctMatchedAllergies;

            List<String> matchedAllergiesText = distinctMatchedAllergies
                .map((e) => '${e['synonym']} \n( van: ${e['allergy']})')
                .toList();

            bool hasMatches = matchedAllergiesText.isNotEmpty;

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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top area: centered drag handle + Save at top-right
                            SizedBox(
                              height: 40,
                              child: Stack(
                                children: [
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
                                          matchedAllergens: matchedAllergiesText,
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

                            // Title (left) + Status icon (right)
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: titleController,
                                    decoration: InputDecoration(
                                      hintText: 'Title',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Center(
                                      child: Icon(
                                        hasMatches
                                            ? Icons.cancel
                                            : Icons.check_circle,
                                        color: hasMatches
                                            ? Colors.red
                                            : Colors.green,
                                        size: 56,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Image + allergen info: give image a fixed height so layout is predictable
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      height: 150,
                                      child: Image.file(
                                        widget.imageFile,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: hasMatches
                                      ? Column(
                                          children: [
                                            Text(
                                              "Gedetecteerde allergenen:",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red.shade700,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                final double maxChipWidth =
                                                    constraints.maxWidth * 0.9;
                                                return Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: matchedAllergiesText.map((
                                                    allergy,
                                                  ) {
                                                    return ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                            maxWidth:
                                                                maxChipWidth,
                                                          ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 10,
                                                            ),
                                                        margin:
                                                            const EdgeInsets.only(
                                                              bottom: 0,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .red
                                                              .shade100,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          allergy,
                                                          softWrap: true,
                                                          maxLines: null,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                );
                                              },
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          "Geen allergenen gedetecteerd",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            const Text(
                              "Herkende tekst",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Editable text area — do NOT wrap this in its own scroll view.
                            // It will grow with content and the whole sheet will scroll.
                            TextField(
                              controller: textController,
                              maxLines:
                                  null, // allow multiline and let sheet scroll
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Bewerk herkende tekst hier...",
                              ),
                              onChanged: (_) {
                                setState(
                                  () {},
                                ); // update matches when text changes
                              },
                            ),

                            // Delete scan button
                            SizedBox(height: 24),
                            // bottom right aligned
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  // open popup to confirm deletion
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Verwijder scan'),
                                      content: const Text(
                                        'Weet je zeker dat je deze scan wilt verwijderen?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Annuleren'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Provider.of<ScanHistoryState>(
                                              context,
                                              listen: false,
                                            ).removeScan(widget.scanId);
                                            Navigator.of(context)
                                                .pop(); // close dialog
                                            Navigator.of(context)
                                                .pop(); // close bottom sheet
                                          },
                                          child: const Text(
                                            'Verwijder',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Verwijder scan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

    // Read the scan entry from ScanHistoryState (if present) to show allergensDetected
    final scanHistory = context.watch<ScanHistoryState>();
    final scan = scanHistory.history.firstWhere(
      (s) => s.id == widget.scanId,
      orElse: () => ScanResult(
        id: widget.scanId,
        title: widget.title,
        recognizedText: widget.recognizedText,
        imagePath: widget.imageFile.path,
        allergensDetected: false,
        matchedAllergens: [],
        timestamp: DateTime.now(),
      ),
    );

    final bool hasMatches = scan.allergensDetected;

    final subtitle = timeAgo(scan.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
              children: [
                // Left thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Image.file(
                      widget.imageFile,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 28),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Status icon + edit button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Keep a small edit affordance (tapping either the tile or this opens sheet)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => _showBottomSheet(context),
                      tooltip: 'Bewerk scan',
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      hasMatches ? Icons.cancel : Icons.check_circle,
                      color: hasMatches ? Colors.red : Colors.green,
                      size: 50,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Used for getting the "time ago" string
  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 60) return 'Nu net';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m geleden';
    if (diff.inHours < 24) return '${diff.inHours}u geleden';
    if (diff.inDays < 7) return '${diff.inDays}d geleden';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w geleden';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}ma geleden';
    return '${(diff.inDays / 365).floor()}j geleden';
  }
}
