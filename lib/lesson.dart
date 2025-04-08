import 'package:camera_platform_interface/src/types/camera_description.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';
import 'dart:typed_data';

List<double> extractLandmarkFeatures(List<List<double>> landmarks, String handednessLabel) {
  List<double> features = [];

  // 1. Absolute normalized coordinates (x, y, z)
  for (var landmark in landmarks) {
    features.addAll(landmark); // Each landmark = [x, y, z]
  }

  // 2. Normalize to wrist (landmark 0)
  var wrist = landmarks[0];
  List<List<double>> normalizedLandmarks = landmarks.map((point) {
    return [
      point[0] - wrist[0],
      point[1] - wrist[1],
      point[2] - wrist[2],
    ];
  }).toList();

  // 3. Tip distances from wrist (normalized space)
  for (var tipIndex in [4, 8, 12, 16, 20]) {
    var tip = normalizedLandmarks[tipIndex];
    double distance = sqrt(tip[0] * tip[0] + tip[1] * tip[1] + tip[2] * tip[2]);
    features.add(distance);
  }

  // 4. Angles between joints
  double calculateAngle(List<double> p1, List<double> p2, List<double> p3) {
    var v1 = [
      p1[0] - p2[0],
      p1[1] - p2[1],
      p1[2] - p2[2],
    ];
    var v2 = [
      p3[0] - p2[0],
      p3[1] - p2[1],
      p3[2] - p2[2],
    ];

    double norm1 = sqrt(v1[0]*v1[0] + v1[1]*v1[1] + v1[2]*v1[2]);
    double norm2 = sqrt(v2[0]*v2[0] + v2[1]*v2[1] + v2[2]*v2[2]);

    if (norm1 == 0 || norm2 == 0) return 0.0;

    double dot = v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2];
    double cosAngle = dot / (norm1 * norm2);
    cosAngle = cosAngle.clamp(-1.0, 1.0); // Avoid NaN
    return acos(cosAngle); // returns angle in radians
  }

  List<List<int>> fingerTriplets = [
    [1, 2, 4],    // Thumb: CMC → MCP → TIP
    [5, 6, 8],    // Index: MCP → PIP → TIP
    [9, 10, 12],  // Middle
    [13, 14, 16], // Ring
    [17, 18, 20], // Pinky
  ];

  for (var triplet in fingerTriplets) {
    features.add(calculateAngle(
      normalizedLandmarks[triplet[0]],
      normalizedLandmarks[triplet[1]],
      normalizedLandmarks[triplet[2]],
    ));
  }

  // 5. Add handedness (Right = 1.0, Left = 0.0)
  features.add(handednessLabel == 'Right' ? 1.0 : 0.0);

  return features;
}

Future<Map<String, dynamic>> runMediaPipeOnImage(CameraImage image) async {
  // TEMP: return mock data so your code compiles and runs
  return {
    'landmarks': List.generate(21, (i) => [0.1 * i, 0.2 * i, 0.05 * i]), // 21 dummy landmarks
    'handedness': 'Right',
  };
}


enum LessonStage {learning, button, camera}
class Lesson extends StatefulWidget{
  final int level;
  List<CameraDescription> cameras;
  Lesson(this.cameras,this.level);
  
  @override
  State<Lesson> createState() => _LessonState();
}

class _LessonState extends State<Lesson>{
  LessonStage currentStage = LessonStage.learning;
  var currentQuestion = 0;
  bool _isLoading = true;
  bool modelReady = false;
  bool showNextButton = false;
  bool _isProcessing = false;
  List<Map<String, dynamic>> questions = [];
  final DatabaseService _databaseService = DatabaseService();
  TextEditingController _controller = new TextEditingController();
  late CameraController cameraController;
  late Interpreter interpreter;
  Map<String, dynamic> labelMapping = {};
  
  @override
  void initState() {
    super.initState();
    fetchLessons();
    initCamera().then((_) {
      loadModelAndLabels();
    });
  }

  Future<void> initCamera() async {
    final frontCamera = widget.cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );
    cameraController = CameraController(frontCamera, ResolutionPreset.low);
    await cameraController.initialize();
    setState(() {});
    await Future.delayed(Duration(seconds: 3));
    startImageStream();
  }

  void fetchLessons() async {
    String level = "level${widget.level}"; 
    List<Map<String, dynamic>>? data = await _databaseService.fetchLessonData(level).timeout(Duration(seconds: 5));
    if (data != null) {
      setState(() {
        questions = data;
        _isLoading = false; // Stop loading
      });
    }
  }

  Future<void> loadModelAndLabels() async {
    final modelData = await rootBundle.load('assets/sign_language_model.tflite');
    final modelBytes = modelData.buffer.asUint8List();
    interpreter = Interpreter.fromBuffer(modelBytes);
    final jsonStr = await rootBundle.loadString('assets/label_mapping.json');
    labelMapping = json.decode(jsonStr);
    setState(() {
      modelReady = true;
    });
  }

  void startImageStream() {
  cameraController.startImageStream((CameraImage image) async {
    if (_isProcessing || !modelReady) return;

    _isProcessing = true;
    
    try {
      final result = await runMediaPipeOnImage(image);
      if (result == null || result['landmarks'] == null) {
        _isProcessing = false;
        return;
      }

      List<List<double>> landmarks = List<List<double>>.from(result['landmarks']);
      String handedness = result['handedness'];

      List<double> input = extractLandmarkFeatures(landmarks, handedness);

      var inputTensor = [Float32List.fromList(input)];
      var output = List.filled(labelMapping.length, 0.0).reshape([1, labelMapping.length]);

      interpreter.run(inputTensor.reshape([1, 74]), output);

      int predictedIndex = 0;
      double maxScore = output[0][0];

      for (int i = 1; i < output[0].length; i++) {
        if (output[0][i] > maxScore) {
          maxScore = output[0][i];
          predictedIndex = i;
        }
      }
      String predictedLabel = labelMapping["$predictedIndex"];
      String correctAnswer = questions[currentQuestion]['answer'];

      print("Prediction: $predictedLabel (Score: ${maxScore.toStringAsFixed(3)})");
      print("Expected: $correctAnswer");

      // Add 5 seconds delay after each frame before showing "Next" button
      await Future.delayed(Duration(seconds: 3));

      setState(() {
        showNextButton = true;
      });
    } catch (e) {
      print("Detection error: $e");
    }
    _isProcessing = false;
  });
}


  img.Image convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;
    final img.Image imgBuffer = img.Image.rgb(width, height); // RGB constructor

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final int indexY = y * width + x;
        if (indexY >= image.planes[0].bytes.length ||
          uvIndex >= image.planes[1].bytes.length ||
          uvIndex >= image.planes[2].bytes.length) {
            continue;
        }

        final int yVal = image.planes[0].bytes[indexY];
        final int uVal = image.planes[1].bytes[uvIndex];
        final int vVal = image.planes[2].bytes[uvIndex];

        int r = (yVal + 1.370705 * (vVal - 128)).round();
        int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128)).round();
        int b = (yVal + 1.732446 * (uVal - 128)).round();

        imgBuffer.setPixel(x, y, img.getColor(
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
        ));
      }
    }
    return imgBuffer;
  }

  void dispose(){
    _controller.dispose();
    cameraController.stopImageStream();
    cameraController.dispose();
    super.dispose();
  }

  void buttonClicked(String text){
    setState(()
    {_controller.text=text;
    });
  }

  void nextQuestion(){
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        showNextButton = false;
      });
    } else {
      currentQuestion=0;
      nextStage();
      showNextButton = false;
    }
  }
  
  void nextStage() {
    setState(() {
      if (currentStage == LessonStage.learning) {
        currentStage = LessonStage.button;
      } else if (currentStage == LessonStage.button) {
        currentStage = LessonStage.camera;
      } else {
        completed();
      }
    });
  }

  void completed() async {
    int currentLevel = await _databaseService.fetchUserLevel();
    if (widget.level + 1 > currentLevel) {
      await _databaseService.updateUserLevel(widget.level + 1); // unlock next level
    }
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Lesson Completed"),
        content: Text("Congratulations! You've finished the lesson."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // closes the dialog
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context); // back to Journey page
  }

  void checkAnswer(String answer){
    //if answer = correct from firebase
    if (answer == questions[currentQuestion]['answer']) {
      if (currentQuestion < questions.length - 1) {
        setState(() {
          currentQuestion++; // Move to next question
        });
      } else {
        currentQuestion=0;
        nextStage(); // Move to next stage or complete
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong Answer')));
    }
  }

  @override
  Widget build(BuildContext context){
    if (_isLoading || questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.amber[100],
        appBar: AppBar(backgroundColor: Colors.orange[600]),
        body: Center(child: CircularProgressIndicator()),
     );
    }
    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(
        backgroundColor: Colors.orange[600],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.center,
            children:[
              if (currentStage==LessonStage.learning) ... [
                Text('Lets learn this word',
                    style: TextStyle(color: Colors.black,
                        fontSize: 25.0,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 5.0,),
                Divider(
                  height: 1.0,
                  color: Colors.amber,
                ),
                SizedBox(height:15.0,),
                Image.asset(questions[currentQuestion]['image'], height: 150),
                Text(questions[currentQuestion]['answer'],style:TextStyle(fontSize: 30)),
                SizedBox(height:20),
                FloatingActionButton(backgroundColor: Colors.green[600],foregroundColor: Colors.white,
                    onPressed : nextQuestion,
                    child: Text('Next')),
              ]
              else if(currentStage==LessonStage.button) ... [
                Text('What does this sign means?',
                    style: TextStyle(color: Colors.black,
                        fontSize: 25.0,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 5.0,),
                Divider(
                  height: 1.0,
                  color: Colors.amber,
                ),
                SizedBox(height:15.0,),
                Image.asset(questions[currentQuestion]['image'], height: 150),
                SizedBox(height:20,),
                TextField(
                  controller:_controller,
                  decoration: InputDecoration(border: UnderlineInputBorder(),
                    labelText: 'Enter your answer here',
                  ),
                ),
                SizedBox(height:20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: (questions.isNotEmpty && questions[currentQuestion]['option'] != null)
                  ? List.generate(questions[currentQuestion]['option'].length, (index) {
                    return SizedBox(
                      width: 100, // Set fixed width for consistency
                      child: FloatingActionButton(backgroundColor: Colors.orange[600],foregroundColor: Colors.amber[100],
                        onPressed: () {
                          buttonClicked(questions[currentQuestion]['option'][index]);
                        },
                        child: Text(questions[currentQuestion]['option'][index]),
                      ),
                    );
                  })
                  : [],
                ),
                SizedBox(height:30),
                Container(width:200.0,height:50.0,
                  child: FloatingActionButton(backgroundColor: Colors.green[600],foregroundColor: Colors.white,
                      onPressed : (){checkAnswer(_controller.text);},
                      child: Text('Check')),
                ),
                ] else if (currentStage==LessonStage.camera)...[
                Text('What does this sign means?',
                    style: TextStyle(color: Colors.black,
                        fontSize: 25.0,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 5.0,),
                Divider(
                  height: 1.0,
                  color: Colors.amber,
                ),
                SizedBox(height:15.0,),
                Image.asset(questions[currentQuestion]['image'], height: 150),
                SizedBox(height:5.0),
                cameraController.value.isInitialized? AspectRatio(
                  aspectRatio: cameraController.value.aspectRatio,
                  child: CameraPreview(cameraController),
                )
                : Container(),
                SizedBox(height: 20),
                if (showNextButton)
                ElevatedButton(
                  onPressed: nextQuestion,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                  child: Text('Next', style: TextStyle(color: Colors.white)),
                )
                else
                Column(
                  children: [
                    CircularProgressIndicator(color: Colors.orange[800]),
                    SizedBox(height: 10),
                    Text(
                      'Scanning sign...',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ]
            ]
        ),
      ),
    );
  }
}