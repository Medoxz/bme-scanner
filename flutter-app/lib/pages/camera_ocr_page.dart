import 'package:bme_scanner/pages/Components/camera_ocr_button.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'Components/OCRResultTile.dart';
import 'Components/ScanHistoryState.dart';
import 'Components/AllergyState.dart';

class CameraOCRPage extends StatefulWidget {
  const CameraOCRPage({super.key});

  @override
  State<CameraOCRPage> createState() => _CameraOCRPageState();
}

class _CameraOCRPageState extends State<CameraOCRPage> {
  @override
  Widget build(BuildContext context) {
    final scanHistory = context.watch<ScanHistoryState>();

    return Scaffold(
      appBar: AppBar(title: const Text("Camera OCR")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Camera OCR button
            CameraOCRButton(
              onTextRecognized: (text, image) {
                // Compute allergens
                final selectedAllergies = context
                    .read<AllergyState>()
                    .selectedAllergies;
                final lowerText = text.toLowerCase();

                List<Map<String, String>> selectedAllergySynonyms = context
                    .read<AllergyState>()
                    .allergies
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

                final matchedAllergens = selectedAllergySynonyms
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

                final allergensDetected = matchedAllergens.isNotEmpty;

                // Add scan to history
                context.read<ScanHistoryState>().addScan(
                  title: "Scan ${scanHistory.history.length + 1}",
                  recognizedText: text,
                  imageFile: image,
                  allergensDetected: allergensDetected,
                  matchedAllergens: matchedAllergens,
                  timestamp: DateTime.now(),
                );
              },
              onPermissionDenied: () {
                final messenger = ScaffoldMessenger.of(context);
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text("Allow camera access."),
                    action: SnackBarAction(
                      label: "Settings",
                      onPressed: openAppSettings,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            /// Scan history list
            Expanded(
              child: scanHistory.history.isEmpty
                  ? const Center(
                      child: Text(
                        "No scans yet.",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: scanHistory.history.length,
                      itemBuilder: (context, index) {
                        final scan = scanHistory.history[index];
                        return OCRResultTile(
                          scanId: scan.id,
                          title: scan.title,
                          recognizedText: scan.recognizedText,
                          imageFile: scan.imageFile,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
