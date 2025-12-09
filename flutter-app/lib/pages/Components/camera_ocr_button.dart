import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraOCRButton extends StatefulWidget {
  final Function(String text)? onTextRecognized;

  const CameraOCRButton({super.key, this.onTextRecognized});

  @override
  State<CameraOCRButton> createState() => _CameraOCRButtonState();
}

class _CameraOCRButtonState extends State<CameraOCRButton> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _isProcessing = false;

  Future<void> _performScan() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);

    PermissionStatus status = await Permission.camera.status;

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Camera permission denied. Tap to enable in settings.',
          ),
          action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
        ),
      );
      return;
    }

    if (picked == null) return;

    setState(() => _isProcessing = true);

    final image = File(picked.path);
    final inputImage = InputImage.fromFile(image);

    try {
      final text = await textRecognizer.processImage(inputImage);

      widget.onTextRecognized?.call(text.text);
    } catch (e) {
      widget.onTextRecognized?.call("Error: $e");
    }

    setState(() => _isProcessing = false);
  }

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ElevatedButton(onPressed: _performScan, child: Icon(Icons.camera_alt)),
        if (_isProcessing)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
