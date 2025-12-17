import 'dart:io';
import 'package:bme_scanner/pages/Components/camera_ocr_button.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Components/ocr_result_bottom_sheet.dart';

class CameraOCRPage extends StatefulWidget {
  const CameraOCRPage({super.key});

  @override
  State<CameraOCRPage> createState() => _CameraOCRPageState();
}

class _CameraOCRPageState extends State<CameraOCRPage> {
  File? _imageFile;
  String _recognizedText = "No scan yet.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera OCR")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CameraOCRButton(
              onTextRecognized: (text, image) {
                setState(() {
                  _recognizedText = text;
                  _imageFile = image;
                });

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (_) => OCRResultBottomSheet(
                    imageFile: image,
                    recognizedText: text,
                  ),
                );
              },
              onPermissionDenied: () {
                final messenger = ScaffoldMessenger.of(context);
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text("Allow camera access."),
                    action: SnackBarAction(
                      label: "Settings",
                      onPressed: openAppSettings,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            if (_imageFile != null) Image.file(_imageFile!, height: 250),

            const SizedBox(height: 16),
            const Text(
              "Recognized Text:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _recognizedText.isEmpty
                      ? "No Recognized text."
                      : _recognizedText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
