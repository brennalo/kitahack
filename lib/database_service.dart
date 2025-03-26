import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
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
        });
      }
    } on FirebaseAuthException catch(e){
      String message ='';
      if(e.code == 'email-already-in-use'){
        message = 'An account already exists with this email.';
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

  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email:email,
        password:password,
      );
    } on FirebaseAuthException catch(e){
      String message ='';
      if (e.code == 'invalid-email'){
        message = 'No user found for that email.';
      }
      else if(e.code == 'invalid-credential'){
        message = 'Wrong password provided.';
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
}

class DatabaseService{
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // fetch user data
  Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  //update user data
  Future<void> updateUserProfile(String name) async {
  try {
    final user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': name,
      });
      print('User profile updated successfully');
    }
  } catch (e) {
      print('Error updating profile: $e');
    }
  }
  
  // realtime update user level.
  Future<void> updateUserLevel(int newLevel) async {
    String uid = _auth.currentUser?.uid ?? '';
  
    if (uid.isNotEmpty) {
      DocumentReference userRef = _db.collection('users').doc(uid);

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

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching lesson data: $e');
    }
    return null;
  }

  //fetch lesson data
  Future<List<Map<String, dynamic>>?> fetchQuizData(String level) async {
    try {
      QuerySnapshot snapshot = await _db
        .collection('QuizData')
        .doc(level)
        .collection('optionquiz')
        .orderBy('index', descending: false)
        .get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching lesson data: $e');
    }
    return null;
  }

  //fetch camera quiz
  Future<List<Map<String, dynamic>>?> fetchCameraQuizData(String level) async {
    try {
      QuerySnapshot snapshot = await _db
        .collection('QuizData')
        .doc(level)
        .collection('cameraquiz')
        .orderBy('index', descending: false)
        .get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching lesson data: $e');
    }
    return null;
  }
}
