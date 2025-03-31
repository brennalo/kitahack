import 'package:camera_platform_interface/src/types/camera_description.dart';
import 'package:flutter/material.dart';
import 'package:kitahack/lesson.dart';
import 'package:kitahack/main.dart';
import 'profile.dart';
import 'login.dart';
import 'firebase_service.dart';


class Journey extends StatefulWidget{
  var cameras;
  Journey(this.cameras);

  @override
  State<Journey> createState() => _JourneyState();
}

class _JourneyState extends State<Journey>{
  //List<String> lessons=['1','2','3'];
  final DatabaseService _databaseService = DatabaseService();
  final List<String> lessons = List.generate(8, (index) => 'Lesson ${index + 1}');
  int level=0; //get level
  
  @override
  void initState() {
    super.initState();
    _databaseService.fetchUserLevel().then((lvl) {
      setState(() {
        level = lvl;
      });
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar:AppBar(
        backgroundColor: Colors.orange[600],
        title:Row(
          children: [
            Text('Level ${level}'),
          ],

        )
      ),
      body:SingleChildScrollView(
        child:Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(lessons.length, (index) {
              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 20 : 40, left: index.isOdd ? 120 : 30, right: index.isEven ? 120 : 30),
                child: ElevatedButton(
                  onPressed:index>1?null: () async{
                    await _databaseService.updateUserLevel(index + 1);
                    Navigator.push(
                      context,MaterialPageRoute(builder: (context)=>getPage(index)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    backgroundColor: index>1?Colors.blueGrey:Colors.orange[600],
                    foregroundColor:index>1?Colors.white:Colors.amber[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(lessons[index], style: TextStyle(fontSize: 25)),
                ),
              );
            }),
          ),
        )
      ),
    );
  }

  Widget getPage(int index) {
    switch (index){
      case 0: return Lesson(cameras);
      case 1: return Lesson(cameras);
      default:return Journey(cameras);
    }
  }
}