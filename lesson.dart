import 'package:camera_platform_interface/src/types/camera_description.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

enum LessonStage {learning, button, camera}
class Lesson extends StatefulWidget{
  List<CameraDescription> cameras;

  Lesson(this.cameras);

  @override
  State<Lesson> createState() => _LessonState();
}

class _LessonState extends State<Lesson>{
  LessonStage currentStage=LessonStage.learning;

  var currentQuestion=0;
  //maybe can terus convert firebase data into list of mapped string
  final List<Map<String, dynamic>> questions = [
    {
      'image': 'assets/1.jpg',
      'options': ['hello', 'goodbye', 'thankyou'],
      'answer': 'goodbye'
    },
    {
      'image': 'assets/2.jpg',
      'options': ['hello', 'goodbye', 'thankyou'],
      'answer': 'hello'
    },
    {
      'image': 'assets/3.jpg',
      'options': ['hello', 'goodbye', 'thankyou'],
      'answer': 'thankyou'
    },
  ];

  TextEditingController _controller = new TextEditingController();
  late CameraController cameraController;
  
  void initState(){
    super.initState();
    cameraController=new CameraController(widget.cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((_){
      if(!mounted){
        return;
      }
      setState(() {});
    });
  }

  void dispose(){
    _controller?.dispose();
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
                Row(crossAxisAlignment:CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Colors.orange[600],foregroundColor: Colors.amber[100]),
                        onPressed: () { buttonClicked("hello"); }, child: Text('hello')),
                    ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Colors.orange[600],foregroundColor: Colors.amber[100]),
                        onPressed:() { buttonClicked("goodbye"); }, child: Text('goodbye')),
                    ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Colors.orange[600],foregroundColor: Colors.amber[100]),
                        onPressed: () { buttonClicked("thankyou"); }, child: Text('thankyou')),
                  ],
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
                : Container()
              ]
            ]
        ),
      ),
    );
  }
}