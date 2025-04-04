import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'main.dart';

class AuthService{
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required BuildContext context
  }) async {
    try {
      
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email:email,
        password:password,
      );

      User? user = userCredential.user;

      if (user != null){
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name':name,
          'email':email,
          'createdAt': DateTime.now().toString(),
          'level':null,
          'completedLevels' :[],
        });
      }
      Fluttertoast.showToast(
        msg: 'Sign Up Successful!',toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,backgroundColor: Colors.green,
        textColor: Colors.white,fontSize: 14.0,
      );
      // Navigate to login screen or main screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
      );
    } on FirebaseAuthException catch(e){
      String message ='';
      if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email.';
      } else if (e.code == 'weak-password') {
        message = 'Your password is too weak.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else {
        message = 'Signup failed. Please try again.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black45,
        textColor: Colors.white12,
        fontSize: 14.0, 
      );
    }
  }

  Future<User?> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user; 
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Incorrect password. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return null; // Return null if login fails
    }
  }
}

class DatabaseService{
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // fetch user data
  Future<Map<String, dynamic>?> getUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _db.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
    }
    return null; // Return null if no user or data found
  }

  Future<void> updateProfile(String name, String email, BuildContext context) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Update email in Firebase Authentication
        await user.updateEmail(email.trim());

        // Update Firestore
        await _db.collection('users').doc(user.uid).update({
          'name': name.trim(),
          'email': email.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating email: $e')),
        );
      }
    }
  }
  
  // fetch user level
  Future<int> fetchUserLevel() async {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      try {
        DocumentSnapshot snapshot = await _db.collection('users').doc(uid).get();
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

<<<<<<< Updated upstream
        return data?['level'] ?? 1; // Default level is 1 if not found
=======
        return data?['level'] ?? 1;
>>>>>>> Stashed changes
      } catch (e) {
        print("Error fetching user level: $e");
      }
    }
    return 1; // Return default level if user not found
  }

  // realtime update user level.
  Future<void> updateUserLevel(int newLevel) async {
    String uid = _auth.currentUser?.uid ?? '';
  
    if (uid.isNotEmpty) {
      DocumentReference userRef = _db.collection('users').doc(uid);
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
      //fetch user data
      DocumentSnapshot snapshot = await userRef.get();
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      int currentLevel = data?['level'] ?? 1;
      List<dynamic> completedLevels = data?['completedLevels'] ?? [];
      //append new level
      if (!completedLevels.contains(newLevel)) {
        completedLevels.add(newLevel);
      }

      int updatedLevel = newLevel > currentLevel ? newLevel : currentLevel;

      // Update Firestore with the new level and list
      await userRef.update({
        'level': updatedLevel, 
        'completedLevels': completedLevels, // Store completed levels
      });
    }
  }

  // fetch lesson
  Future<List<Map<String, dynamic>>?> fetchLessonData(String level) async {
    try {
      QuerySnapshot snapshot = await _db
        .collection('QuizData')
        .doc(level)
        .collection('lesson')
        .orderBy('index', descending: false)
        .get();

        if(snapshot.docs.isEmpty){
          print("No lessons found for level: $level");
        }
        
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching lesson data: $e');
    }
    return null;
  }
}