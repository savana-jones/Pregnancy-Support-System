import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class ScanReportScreen extends StatefulWidget {
  const ScanReportScreen({Key? key}) : super(key: key);

  @override
  _ScanReportScreenState createState() => _ScanReportScreenState();
}

class _ScanReportScreenState extends State<ScanReportScreen> {
  CameraController? _cameraController;
  late List<CameraDescription> cameras;
  bool _isCameraInitialized = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        print('No cameras found');
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndRecognizeText() async {
    if (!_cameraController!.value.isInitialized) {
      print('Error: Camera is not initialized');
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final imagePath = join(tempDir.path, '${DateTime.now()}.png');

    try {
      XFile picture = await _cameraController!.takePicture();
      await picture.saveTo(imagePath);

      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        _recognizedText = recognizedText.text;
      });

      await textRecognizer.close();

      print("Recognized text: $_recognizedText");
    } catch (e) {
      print('Error in capturing/recognizing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Your Report'),
      ),
      body: _isCameraInitialized
          ? Column(
              children: [
                // Camera Preview with Flexible widget
                Flexible(
                  flex: 4,
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),

                const SizedBox(height: 10),

                // Capture Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9370DB), // Light violet
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _captureAndRecognizeText,
                  icon: const Icon(Icons.camera_alt, color: Colors.black),
                  label: const Text(
                    'Capture & Scan Text',
                    style: TextStyle(
                      color: Colors.black, // Black text color
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Recognized text display in scrollable container
                Flexible(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: SingleChildScrollView(
                      child: Text(
                        _recognizedText.isEmpty
                            ? 'Scanned text will appear here'
                            : _recognizedText,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
