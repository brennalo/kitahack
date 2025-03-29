import 'package:flutter/material.dart';
import 'package:kitahack2/profile.dart';
import 'login.dart';
import 'lesson.dart';
import 'register.dart';
import 'journey.dart';
import 'profile.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras=[];

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras=await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Language App',
      home: Login(cameras),
    );
  }
}

class MainFlow extends StatefulWidget{
  MainFlow(cameras);

  _MainFlowState createState() => _MainFlowState();
}
class _MainFlowState extends State<MainFlow>{
  int selectedpage=0;
  final List<Widget>_pages=[
    Journey(cameras),
    Profile(),
    Login(cameras),
  ];
  void changePage(int page){
    setState(() {
      selectedpage=page;
    });
  }

  Widget build(BuildContext context){
    return Scaffold(
      body: _pages[selectedpage],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedpage,
        onTap: changePage,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.sign_language), label: 'Lessons'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.exit_to_app), label: 'SignOut'),
        ],
      ),
    );
  }
}