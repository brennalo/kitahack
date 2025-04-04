import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:kitahack/profile.dart';
=======
import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:kitahack/profile.dart';
import 'package:kitahack/translator.dart';
>>>>>>> Stashed changes
import 'login.dart';
import 'journey.dart';
import 'package:camera/camera.dart';
import 'firebase_options.dart';

List<CameraDescription> cameras=[];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
<<<<<<< Updated upstream
=======
  await dotenv.load();
>>>>>>> Stashed changes
  await Firebase.initializeApp(
    options: (DefaultFirebaseOptions.currentPlatform)
  ); // Initialize Firebase
  cameras = await availableCameras(); // Initialize cameras
  runApp(const MyApp()); // Start your app
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
<<<<<<< Updated upstream
=======
    Translator(cameras),
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        items: const[
          BottomNavigationBarItem(icon: Icon(Icons.sign_language), label: 'Lessons'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.exit_to_app), label: 'SignOut'),
=======
        type: BottomNavigationBarType.fixed, 
        selectedFontSize: 10, 
        unselectedFontSize: 10,
        iconSize: 20, 
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sign_language),
            label: 'Lessons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.translate),
            label: 'Translate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
>>>>>>> Stashed changes
        ],
      ),
    );
  }
}