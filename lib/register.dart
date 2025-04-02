import 'package:flutter/material.dart';
import 'package:kitahack/firebase_service.dart';
import 'package:kitahack/main.dart';
import 'login.dart';

class Register extends StatefulWidget{
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register>{
  TextEditingController emailText=TextEditingController();
  TextEditingController passwordText=TextEditingController();

  void register(){
    String email=emailText.text;
    String password=passwordText.text;

    if (email.isNotEmpty && password.isNotEmpty){
      //register action through firebase
      AuthService().signup(
        name: 'user',
        email: email,
        password: password,
        context:context
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
    }
  }


  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.amber[100],
      body:Center(
        child:Container(
          padding: const EdgeInsets.symmetric(vertical: 40,horizontal: 20),
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
                Text('Sign Up',
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
                  onPressed: register,
                  child: const Text('Sign Up'),
                ),
                TextButton(onPressed: (){
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Login(cameras)));},
                    child: Text ('Log In Here'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}