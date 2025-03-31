import 'package:flutter/material.dart';
import 'firebase_service.dart';

class Profile extends StatefulWidget{
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile>{
  TextEditingController nameText=TextEditingController();
  TextEditingController emailText=TextEditingController();
  int level=0;//get level from firebase
  bool isLoading = true; // Track loading state
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch data when screen loads
  }

  Future<void> _fetchUserProfile() async {
    Map<String, dynamic>? userData = await _databaseService.getUserProfile();
    if (userData != null) {
      setState(() {
        nameText.text = userData['name'] ?? 'Unknown';
        emailText.text = userData['email'] ?? '';
        level = userData['level'] ?? 0;
        isLoading = false;
      });
    }
  }

  void _updateProfile(){
    _databaseService.updateProfile(nameText.text, emailText.text, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.amber[100],
      body:Center(
        child:Container(
          padding: const EdgeInsets.symmetric(vertical: 40,horizontal: 20),
          decoration: BoxDecoration(
            color:Colors.orange[600],
            borderRadius: BorderRadius.circular(50),
            boxShadow:const[
              BoxShadow(
                color:Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          width:350,
          child:Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Profile',
                  style: TextStyle(
                    fontSize:35.0,
                    fontWeight: FontWeight.w600,
                    color:Colors.amber[100],
                  ),
                ),
                Divider(height:1,color:Colors.amber[100]),
                SizedBox(height:20.0),
                Row(
                  children: [
                    Icon(Icons.account_circle,size:85.0),
                    SizedBox(width:8.0),
                    Text('Level$level',style:TextStyle(fontSize: 30)),
                  ]
                ),
                SizedBox(height:20.0),
                TextField(
                  controller: nameText,
                  decoration: const InputDecoration(
                      filled:true,
                      fillColor: Colors.transparent,
                      labelText: 'Name',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.amberAccent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                      )
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailText,
                  decoration: const InputDecoration(
                      filled:true,
                      fillColor: Colors.transparent,
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.amberAccent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                      )
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style:ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[100],
                    foregroundColor: Colors.orange[600],
                    textStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500),
                  ),
                  onPressed: _updateProfile,
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}