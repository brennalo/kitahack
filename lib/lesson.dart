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
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];
  
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
      await Future.delayed(Duration(milliseconds: 300));
      try {
        final img.Image rgbImage = convertYUV420ToImage(image);
        int cropSize = rgbImage.width < rgbImage.height ? rgbImage.width : rgbImage.height;
        final img.Image cropped = img.copyCrop(
          rgbImage,
          (rgbImage.width - cropSize) ~/ 2,
          (rgbImage.height - cropSize) ~/ 2,
          cropSize,
          cropSize,
        );
        final img.Image resized = img.copyResize(cropped, width: 224, height: 224);
        final input = [
          List.generate(224, (y) => List.generate(224, (x) {
            final pixel = resized.getPixel(x, y);
            return [
              img.getRed(pixel) / 255.0,
              img.getGreen(pixel) / 255.0,
              img.getBlue(pixel) / 255.0,
            ];
          }))
        ];
        var output = List.generate(2034, (_) => List.filled(6, 0.0));
        interpreter.run(input, output);

        final prediction = List.filled(6, 0.0);
        for (var row in output) {
          for (int i = 0; i < 6; i++) {
            prediction[i] += row[i];
          }
        }
        for (int i = 0; i < 6; i++) {
          prediction[i] /= 2034;
        }
        final maxIndex = prediction.indexOf(prediction.reduce((a, b) => a > b ? a : b));
        final predictedLabel = labelMapping[maxIndex.toString()];
        final expected = questions[currentQuestion]['label'];
        print("Predicted: $predictedLabel | Expected: $expected");
        print("Prediction confidence: ${prediction[maxIndex]}");
        print("All scores: $prediction");

        if (prediction[maxIndex] > 0.5 &&
          predictedLabel.toLowerCase().trim() == expected.toLowerCase().trim()) {
            setState(() => showNextButton = true);
          } else {
            setState(() => showNextButton = false);
          }
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
      });
    } else {
      currentQuestion=0;
      nextStage();
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

  void completed(){
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Lesson Completed"),
        content: Text("Congratulations! You've finished the lesson."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
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