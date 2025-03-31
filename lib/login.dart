import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kitahack/firebase_service.dart';
import 'main.dart';
import 'register.dart';

class Login extends StatefulWidget {
  final List<dynamic> cameras; // Explicitly define type
  const Login(this.cameras, {super.key}); // Add super.key
  @override
  State<Login> createState() => _LoginState();
}


class _LoginState extends State<Login>{
  TextEditingController emailText=TextEditingController();
  TextEditingController passwordText=TextEditingController();
  final AuthService _auth = AuthService();

  void login() async {
  String email = emailText.text;
  String password = passwordText.text;
  if (email.isNotEmpty && password.isNotEmpty) {
    try {
      User? user = await _auth.signin(email: email, password: password, context: context);
      if (user != null) { 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainFlow(widget.cameras)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred. Please try again.'), backgroundColor: Colors.red),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter email and password'), backgroundColor: Colors.orange),
    );
  }
}

  void register(){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Register()),
      );
  }

  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.amber[100],
      body:Center(
        child:Container(
          padding: const EdgeInsets.fromLTRB(40.0,20.0,40.0,20.0),
          decoration: BoxDecoration(
            color:Colors.orange[600],
            borderRadius: BorderRadius.circular(12),
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
                Text('Log In',
                  style: TextStyle(
                    fontSize:35.0,
                    fontWeight: FontWeight.w600,
                    color:Colors.amber[100],
                  ),
                ),
                SizedBox(height:20.0),
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
                TextField(
                  controller: passwordText,
                  obscureText: true,
                  decoration: const InputDecoration(
                    filled:true,
                    fillColor: Colors.transparent,
                    labelText: 'Password',
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
                  onPressed: login,
                  child: const Text('Login'),
                ),
                TextButton(onPressed: register, child: Text ('Dont have an account? Sign up'))
              ],
            ),
          ),
      ),
    ),
    );
  }
}