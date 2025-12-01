/// Camera OCR Page - Continuous Text Recognition with Word Matching
/// 
/// This page provides a real-time camera feed that continuously scans for text using ML Kit.
/// Users can optionally provide a list of words to search for, and the app will:
/// - Display all recognized text in a scrollable view
/// - Highlight matched words with green bounding boxes on the camera preview
/// - Show matched words in chips that turn green when found
/// 
/// The camera automatically starts scanning when initialized, processing frames
/// at approximately 1 frame per second to balance performance and responsiveness.

import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

/// Main page widget for camera-based OCR scanning
class CameraOCRPage extends StatefulWidget {
  const CameraOCRPage({super.key});

  @override
  State<CameraOCRPage> createState() => _CameraOCRPageState();
}

/// State class managing camera, OCR processing, and UI updates
class _CameraOCRPageState extends State<CameraOCRPage> {
  // ============================================================================
  // CAMERA & OCR COMPONENTS
  // ============================================================================
  
  /// Controller for managing the camera feed
  CameraController? _cameraController;
  
  /// Whether the camera has been successfully initialized
  bool _isInitialized = false;
  
  /// Whether an OCR operation is currently in progress (prevents overlapping processing)
  bool _isProcessing = false;
  
  /// ML Kit text recognizer instance for processing images
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  // ============================================================================
  // WORD MATCHING STATE
  // ============================================================================
  
  /// Controller for the text field where users enter words to search for
  final TextEditingController _wordListController = TextEditingController();
  
  /// List of words the user wants to find (parsed from comma-separated input)
  List<String> _userWords = [];
  
  /// Set of words that have been matched in the current frame
  Set<String> _matchedWords = {};
  
  /// Text blocks that contain matched words (used for drawing bounding boxes)
  List<TextBlock> _matchedTextBlocks = [];
  
  /// Size of the camera image (used for coordinate mapping to preview)
  Size? _imageSize;
  
  /// Full text recognized by OCR (displayed in the scrollable view)
  String _recognizedText = "";

  // ============================================================================
  // SCANNING STATE
  // ============================================================================
  
  /// Whether continuous scanning is currently active
  bool _isScanning = false;
  
  /// Timestamp of the last frame processing (for throttling)
  DateTime? _lastProcessTime;
  
  /// Minimum time between processing frames (1 second to avoid overloading)
  static const Duration _processingInterval = Duration(milliseconds: 100);
  
  /// Timer for processing throttling (currently unused but kept for potential future use)
  Timer? _processingTimer;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  @override
  void initState() {
    super.initState();
    // Initialize camera when page loads
    _initializeCamera();
  }

  @override
  void dispose() {
    // Clean up resources when page is closed
    _stopScanning();
    _wordListController.dispose();
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  // ============================================================================
  // CAMERA INITIALIZATION
  // ============================================================================

  /// Initializes the camera and requests necessary permissions
  /// Automatically starts scanning once camera is ready
  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
      }
      return;
    }

    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available')),
          );
        }
        return;
      }

      // Create camera controller with medium resolution (balance between quality and performance)
      _cameraController = CameraController(
        cameras[0], // Use first available camera (usually back camera)
        ResolutionPreset.medium,
        enableAudio: false, // No audio needed for OCR
      );

      // Initialize the camera
      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // Automatically start continuous scanning once camera is initialized
        // This means scanning begins immediately without user interaction
        _startScanning();
      }
    } catch (e) {
      // Handle any errors during camera initialization
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  // ============================================================================
  // WORD LIST MANAGEMENT
  // ============================================================================

  /// Parses the user's input text field and updates the word list
  /// Clears previous matches when word list is updated
  void _updateWordList() {
    final text = _wordListController.text.trim();
    setState(() {
      // Split by comma, trim whitespace, convert to lowercase, and filter empty strings
      _userWords = text
          .split(',')
          .map((word) => word.trim().toLowerCase())
          .where((word) => word.isNotEmpty)
          .toList();
      
      // Clear previous matches and recognized text when word list changes
      _matchedWords.clear();
      _matchedTextBlocks.clear();
      _recognizedText = "";
    });
  }

  // ============================================================================
  // SCANNING CONTROL
  // ============================================================================

  /// Starts the continuous image stream from the camera
  /// Each frame will be processed by _processCameraFrame
  Future<void> _startScanning() async {
    // Safety checks: camera must be initialized and not already scanning
    if (!_isInitialized || _isScanning || _cameraController == null) return;

    try {
      setState(() {
        _isScanning = true;
      });

      // Start receiving camera frames continuously
      // The callback function will be called for each frame
      await _cameraController!.startImageStream(
        (CameraImage image) {
          // Process each frame as it arrives
          _processCameraFrame(image);
        },
      );
    } catch (e) {
      // If stream fails to start, show error and stop scanning
      if (mounted) {
        setState(() {
          _isScanning = false;
          _recognizedText = 'Error starting camera stream: $e';
        });
      }
    }
  }

  /// Stops the continuous image stream
  Future<void> _stopScanning() async {
    setState(() {
      _isScanning = false;
      _matchedTextBlocks.clear(); // Clear bounding boxes when stopping
    });
    await _cameraController?.stopImageStream();
  }

  // ============================================================================
  // OCR PROCESSING
  // ============================================================================

  /// Processes a single camera frame through OCR
  /// 
  /// Flow:
  /// 1. Throttles processing to avoid overwhelming the system
  /// 2. Converts CameraImage to InputImage format
  /// 3. Runs ML Kit text recognition
  /// 4. Extracts recognized text
  /// 5. Matches words if word list is provided
  /// 6. Updates UI with results
  Future<void> _processCameraFrame(CameraImage image) async {
    // Early return if scanning is stopped or already processing a frame
    if (!_isScanning || _isProcessing) return;

    // Throttle processing: only process one frame per _processingInterval
    // This prevents the system from being overwhelmed with too many OCR operations
    final now = DateTime.now();
    if (_lastProcessTime != null &&
        now.difference(_lastProcessTime!) < _processingInterval) {
      return; // Skip this frame, too soon since last processing
    }

    _lastProcessTime = now;

    // Mark as processing to prevent overlapping operations
    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Convert CameraImage (raw camera format) to InputImage (ML Kit format)
      final inputImage = _inputImageFromCameraImage(image);

      // Step 2: Run ML Kit text recognition on the image
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Step 3: Store image dimensions for coordinate mapping (needed for bounding boxes)
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      // Step 4: Extract the plain text string from the recognition result
      final recognizedTextString = recognizedText.text;

      // Step 5: Check for word matches (only if user provided words to search for)
      final newMatches = <String>{};      // Words that matched in this frame
      final matchedBlocks = <TextBlock>[]; // Text blocks containing matches

      if (_userWords.isNotEmpty) {
        // Split recognized text into individual words for matching
        final recognizedWords = recognizedText.text
            .toLowerCase()
            .split(RegExp(r'[\s\n\r\t,;:!?.]+')) // Split on whitespace and punctuation
            .where((word) => word.isNotEmpty)
            .toSet();

        // Check each text block (group of words detected together) for matches
        for (final block in recognizedText.blocks) {
          final blockText = block.text.toLowerCase();
          
          // Compare against each word in the user's search list
          for (final userWord in _userWords) {
            // Check if user word appears anywhere in this text block
            if (blockText.contains(userWord) || userWord.contains(blockText)) {
              newMatches.add(userWord);
              matchedBlocks.add(block); // Store block for drawing bounding box
              break; // Found a match, move to next block
            } else {
              // More granular check: compare individual words within the block
              final blockWords = blockText.split(RegExp(r'[\s\n\r\t,;:!?.]+'));
              for (final blockWord in blockWords) {
                // Match if: exact match, user word in block word, or block word in user word
                if (blockWord == userWord ||
                    blockWord.contains(userWord) ||
                    userWord.contains(blockWord)) {
                  newMatches.add(userWord);
                  matchedBlocks.add(block);
                  break;
                }
              }
              if (matchedBlocks.contains(block)) break; // Already matched this block
            }
          }
        }
      }

      // Step 6: Update UI with results
      if (mounted) {
        setState(() {
          _matchedWords = newMatches;              // Update matched words
          _matchedTextBlocks = matchedBlocks;      // Update blocks for bounding boxes
          _recognizedText = recognizedTextString;  // Update displayed text
          _isProcessing = false;                   // Mark processing as complete
        });
      }
    } catch (e) {
      // Handle any errors during OCR processing
      if (mounted) {
        setState(() {
          // Display error message in the scrollable text view (shown in red)
          _recognizedText = 'Error processing image: $e';
          _isProcessing = false;
          _matchedWords.clear();
          _matchedTextBlocks.clear();
        });
      }
    }
  }

  // ============================================================================
  // IMAGE FORMAT CONVERSION
  // ============================================================================

  /// Converts a CameraImage (from camera stream) to InputImage (for ML Kit)
  /// 
  /// Camera provides images in various formats (YUV420, NV21, BGRA8888)
  /// ML Kit needs a specific InputImage format with proper metadata
  InputImage _inputImageFromCameraImage(CameraImage image) {
    // Determine the image format based on camera's output format
    final format = image.format.group;
    InputImageFormat inputImageFormat;
    
    // Map camera format to ML Kit format
    if (format == ImageFormatGroup.yuv420) {
      inputImageFormat = InputImageFormat.yuv420;
    } else if (format == ImageFormatGroup.nv21) {
      inputImageFormat = InputImageFormat.nv21;
    } else if (format == ImageFormatGroup.bgra8888) {
      inputImageFormat = InputImageFormat.bgra8888;
    } else {
      // Default to YUV420 if format is unknown
      inputImageFormat = InputImageFormat.yuv420;
    }

    // Camera images come in "planes" (separate color channels)
    // Combine all planes into a single byte array
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // Create metadata describing the image
    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: InputImageRotation.rotation0deg, // Assume no rotation
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow, // Bytes per row in the first plane
    );

    // Create InputImage from the byte array and metadata
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );
  }

  // ============================================================================
  // UI BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Word Scanner"),
        actions: [
          // Pause/Resume button for manual control (optional)
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: _stopScanning,
              tooltip: 'Pause scanning',
            )
          else
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _startScanning,
              tooltip: 'Resume scanning',
            ),
        ],
      ),
      body: Column(
        children: [
          // ====================================================================
          // WORD LIST INPUT SECTION
          // ====================================================================
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter words to search for (comma-separated):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Text field for entering words
                TextField(
                  controller: _wordListController,
                  decoration: InputDecoration(
                    hintText: 'e.g., milk, eggs, nuts',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: _updateWordList,
                      tooltip: 'Update word list',
                    ),
                  ),
                  onSubmitted: (_) => _updateWordList(), // Update on Enter key
                ),
                // Display word chips (green if matched, grey if not matched)
                if (_userWords.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _userWords.map((word) {
                      final isMatched = _matchedWords.contains(word);
                      return Chip(
                        label: Text(word),
                        backgroundColor:
                            isMatched ? Colors.green[300] : Colors.grey[300],
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          // Remove word from list when X is clicked
                          _wordListController.text = _userWords
                              .where((w) => w != word)
                              .join(', ');
                          _updateWordList();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // ====================================================================
          // CAMERA PREVIEW SECTION
          // ====================================================================
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview (live feed)
                if (_isInitialized && _cameraController != null)
                  CameraPreview(_cameraController!)
                else
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                
                // Bounding boxes overlay: green rectangles around matched text
                if (_matchedTextBlocks.isNotEmpty && _imageSize != null)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: TextBlockPainter(
                          textBlocks: _matchedTextBlocks,
                          imageSize: _imageSize!,
                          previewSize: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                        ),
                      );
                    },
                  ),
                
                // Matches overlay: green banner showing which words were found
                if (_matchedWords.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Matches found:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _matchedWords.map((word) {
                              return Chip(
                                label: Text(
                                  word,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.green[700],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Processing indicator: shows spinner while OCR is running
                if (_isProcessing)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          
          // ====================================================================
          // SCANNED TEXT DISPLAY SECTION
          // ====================================================================
          Container(
            height: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scanned Text:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _recognizedText.isEmpty
                          ? 'No text detected yet. Start scanning to see recognized text.'
                          : _recognizedText,
                      style: TextStyle(
                        fontSize: 14,
                        // Show errors in red, normal text in black
                        color: _recognizedText.startsWith('Error')
                            ? Colors.red[700]
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER FOR BOUNDING BOXES
// ============================================================================

/// Custom painter that draws green bounding boxes around matched text on the camera preview
/// 
/// Handles coordinate transformation from image coordinates (where OCR detected text)
/// to preview coordinates (where the camera preview is displayed)
/// Accounts for different aspect ratios between image and preview
class TextBlockPainter extends CustomPainter {
  final List<TextBlock> textBlocks; // Text blocks to draw boxes around
  final Size imageSize;              // Size of the original camera image
  final Size previewSize;            // Size of the preview widget

  TextBlockPainter({
    required this.textBlocks,
    required this.imageSize,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create paint for drawing green bounding box outlines
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Calculate scale factors to map image coordinates to preview coordinates
    // This handles cases where the image and preview have different aspect ratios
    final imageAspectRatio = imageSize.width / imageSize.height;
    final previewAspectRatio = size.width / size.height;
    
    double scaleX, scaleY;
    double offsetX = 0, offsetY = 0;
    
    // Determine scaling strategy based on which dimension is the limiting factor
    if (previewAspectRatio > imageAspectRatio) {
      // Preview is wider than image - fit to height (letterboxing on sides)
      scaleY = size.height / imageSize.height;
      scaleX = scaleY; // Maintain aspect ratio
      offsetX = (size.width - imageSize.width * scaleX) / 2; // Center horizontally
    } else {
      // Preview is taller than image - fit to width (letterboxing on top/bottom)
      scaleX = size.width / imageSize.width;
      scaleY = scaleX; // Maintain aspect ratio
      offsetY = (size.height - imageSize.height * scaleY) / 2; // Center vertically
    }

    // Draw bounding box for each matched text block
    for (final block in textBlocks) {
      final rect = block.boundingBox;
      
      // Transform bounding box coordinates from image space to preview space
      final scaledRect = Rect.fromLTWH(
        rect.left * scaleX + offsetX,   // Scale and offset X coordinate
        rect.top * scaleY + offsetY,    // Scale and offset Y coordinate
        rect.width * scaleX,            // Scale width
        rect.height * scaleY,           // Scale height
      );

      // Draw green outline
      canvas.drawRect(scaledRect, paint);
      
      // Draw semi-transparent green fill for better visibility
      final fillPaint = Paint()
        ..color = Colors.green.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRect(scaledRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(TextBlockPainter oldDelegate) {
    // Only repaint if the data has actually changed
    return textBlocks != oldDelegate.textBlocks ||
        imageSize != oldDelegate.imageSize ||
        previewSize != oldDelegate.previewSize;
  }
}
