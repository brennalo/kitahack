import 'package:flutter/material.dart';
import 'package:kitahack/lesson.dart';
import 'firebase_service.dart';

class Journey extends StatefulWidget {
  var cameras;
  Journey(this.cameras);

  @override
  State<Journey> createState() => _JourneyState();
}

class _JourneyState extends State<Journey> {
  final DatabaseService _databaseService = DatabaseService();
  final List<String> lessons = List.generate(8, (index) => 'Lesson ${index + 1}');
  int level = 0; // User's current level

  @override
  void initState() {
    super.initState();
    _initializeUserLevel();
  }

  // Initialize user's level
  Future<void> _initializeUserLevel() async {
    int userLevel = await _databaseService.fetchUserLevel();
    if (userLevel == 0) {
      setState(() {
        level = 1;
      });
      await _databaseService.updateUserLevel(1);
    } else {
      setState(() {
        level = userLevel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(
        backgroundColor: Colors.orange[600],
        title: Row(
          children: [
            Text('Level ${level}'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(lessons.length, (index) {
              bool isLocked = index >= level;
              return Padding(
                padding: EdgeInsets.only(
                    top: index == 0 ? 20 : 40,
                    left: index.isOdd ? 120 : 30,
                    right: index.isEven ? 120 : 30),
                child: ElevatedButton(
                  onPressed: isLocked
                      ? null
                      : () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => getPage(index + 1)),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    backgroundColor: isLocked ? Colors.blueGrey : Colors.orange[600],
                    foregroundColor: isLocked ? Colors.white : Colors.amber[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(
                    lessons[index],
                    style: TextStyle(fontSize: 25),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget getPage(int index) {
    return Lesson(widget.cameras, index);
  }
}
