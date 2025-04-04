import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class Translator extends StatefulWidget {
  final List<CameraDescription> cameras;
  const Translator(this.cameras, {super.key});

  @override
  State<Translator> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<Translator> {
  CameraController? _controller;
  String _result = '';
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];
  bool isProcessing = false;
  bool autoCapture = false;
  Timer? _autoCaptureTimer;
  final List<String> _languages = ['English', 'French', 'Chinese', 'Malay'];
  String _selectedLanguage = 'English';

  CameraLensDirection _currentLensDirection = CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final selectedCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == _currentLensDirection,
      orElse: () => widget.cameras.first,
    );

    _controller = CameraController(selectedCamera, ResolutionPreset.medium);
    await _controller!.initialize();
    setState(() {});

    _startAutoCapture();
  }

  void _startAutoCapture() {
    _autoCaptureTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (autoCapture && mounted) {
        _captureAndSendImage();
      }
    });
  }

  void _flipCamera() async {
    _currentLensDirection = _currentLensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    await _controller?.dispose();
    await _initializeCamera();
  }

  Future<void> _captureAndSendImage() async {
    if (_controller == null || !_controller!.value.isInitialized || isProcessing) return;
    if (!mounted) return;
    setState(() {
      _result = 'Analyzing...';
      isProcessing = true;
    });

    try {
      final directory = await getTemporaryDirectory();
      final filePath = path.join(directory.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

      final XFile file = await _controller!.takePicture();
      final bytes = await File(file.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      await _sendToGemini(base64Image);
    } catch (e) {
      if (!mounted) return;
      setState(() => _result = "Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isProcessing = false);
    }
  }

  Future<void> _sendToGemini(String base64Image) async {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              },
              {
                "text": "Recognize the sign language gesture in this image and respond with a simple, clear translation in $_selectedLanguage. Phrase only."
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (!mounted) return;
      setState(() {
        _result = text ?? "Could not understand the image.";
      });
    } else {
      if (!mounted) return;
      setState(() {
        _result = "Gemini API Error: ${response.body}";
      });
    }
  }

  @override
  void dispose() {
    _autoCaptureTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(
        backgroundColor: Colors.orange[600],
        title: const Text("Sign Language Translator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: _flipCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: "Translate to",
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              iconEnabledColor: Colors.orange,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              items: _languages.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                  _result = '';
               });
              },
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              "Auto Capture Every 5s",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            value: autoCapture,
            onChanged: (value) {
              setState(() {
                autoCapture = value;
              });
            },
            activeColor: Colors.orange,
            activeTrackColor: Colors.orangeAccent,
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[400],
          ),
          ElevatedButton(
            onPressed: _captureAndSendImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 3,
            ),
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  )
                : const Text(
                    "Capture & Translate Now",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text("Result: $_result", style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
