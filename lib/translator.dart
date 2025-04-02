import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Translator extends StatefulWidget {
  final List<CameraDescription> cameras;
  const Translator(this.cameras, {super.key});

  @override
  State<Translator> createState() => _TranslatorState();
}

class _TranslatorState extends State<Translator> {
  CameraController? _controller;
  String detectedSigns = "";
  String translatedText = "";
  String selectedLanguage = "English";

  final List<String> languages = ["English", "Spanish", "French", "Chinese"];
  final String apiKey = "AIzaSyCnwULQK61BzgGzRtHp9ftkYk2YHc0ktD0";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Find the front camera
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras[0], // fallback to first if no front cam
    );
    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
      _startFakeDetection(); // Trigger detection after camera ready
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void _startFakeDetection() {
    Future.delayed(const Duration(seconds: 5), () async {
      List<String> fakeSigns = ["I", "LOVE", "YOU"];
      setState(() {
        detectedSigns = fakeSigns.join(" ");
      });
      String translated = await _translateSigns(fakeSigns, selectedLanguage);
      setState(() {
        translatedText = translated;
      });
    });
  }

  Future<String> _translateSigns(List<String> signs, String language) async {
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyCnwULQK61BzgGzRtHp9ftkYk2YHc0ktD0';
    final prompt = """
      You are an ASL interpreter. Convert the following ASL sign labels to a complete sentence in $language:${signs.join(" ")},
    """;
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyCnwULQK61BzgGzRtHp9ftkYk2YHc0ktD0'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final result = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return result ?? "Translation not found.";
    } else {
      try {
        final error = jsonDecode(response.body);
        final message = error['error']?['message'] ?? 'Unknown error';
        return "Translation failed: $message";
      } catch (_) {
        return "Translation failed. Please try again.";
      }
    }
  }

  @override
  void dispose() {
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
        title: const Text('Sign Language Translator'),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: const InputDecoration(labelText: "Select Language"),
              items: languages
                  .map((lang) =>
                      DropdownMenuItem(value: lang, child: Text(lang)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value!;
                  translatedText = "";
                });
                _startFakeDetection(); // Re-trigger translation with new lang
              },
            ),
          ),
          const SizedBox(height: 16),
          Text("Detected: $detectedSigns"),
          const SizedBox(height: 8),
          Text("Translation: $translatedText",
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
