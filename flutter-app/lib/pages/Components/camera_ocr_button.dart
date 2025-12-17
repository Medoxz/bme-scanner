import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:permission_handler/permission_handler.dart';

class CameraOCRButton extends StatefulWidget {
  final Function(String text, File image)? onTextRecognized;
  final Function()? onPermissionDenied;

  const CameraOCRButton({
    super.key,
    this.onTextRecognized,
    this.onPermissionDenied,
  });

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
    XFile? picked;
    try {
      picked = await _picker.pickImage(source: ImageSource.camera);
    } catch (e) {
      widget.onPermissionDenied?.call();
      return;
    }

    // PermissionStatus status = await Permission.camera.status;

    // if (!status.isGranted) {
    //   widget.onPermissionDenied?.call();
    //   return;
    // }

    if (picked == null) return;

    setState(() => _isProcessing = true);

    final image = File(picked.path);
    final inputImage = InputImage.fromFile(image);

    try {
      final text = await textRecognizer.processImage(inputImage);

      widget.onTextRecognized?.call(text.text, image);
    } catch (e) {
      widget.onTextRecognized?.call("Error: $e", image);
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
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Stack(
        children: [
          Positioned.fill(
            child: ElevatedButton(
              onPressed: _performScan,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 24, color: Colors.white),
                  SizedBox(width: 8),
                  const Text(
                    "Scan Product",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
