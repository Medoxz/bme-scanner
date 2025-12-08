import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraOCRPage extends StatefulWidget {
  const CameraOCRPage({super.key});

  @override
  State<CameraOCRPage> createState() => _CameraOCRPageState();
}

class _CameraOCRPageState extends State<CameraOCRPage> {
  File? _imageFile;
  String _recognizedText = "";
  bool _isProcessing = false;

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<void> _performScan() async {
    PermissionStatus status = await Permission.camera.request();
    print(status);

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
      }
      return;
    }

    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);

    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _recognizedText = "";
      _isProcessing = true;
    });

    final inputImage = InputImage.fromFile(_imageFile!);

    try {
      final RecognizedText text = await textRecognizer.processImage(inputImage);

      setState(() {
        _recognizedText = text.text;
      });
    } catch (e) {
      setState(() {
        _recognizedText = "Error: $e";
      });
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera OCR")),

      floatingActionButton: FloatingActionButton(
        onPressed: _performScan,
        child: const Icon(Icons.camera_alt),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_imageFile != null) Image.file(_imageFile!, height: 250),

            const SizedBox(height: 16),

            if (_isProcessing) const CircularProgressIndicator(),

            const SizedBox(height: 16),
            const Text(
              "Recognized Text:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _recognizedText.isEmpty ? "No scan yet." : _recognizedText,
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
