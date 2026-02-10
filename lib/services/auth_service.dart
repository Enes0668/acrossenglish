import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controller to broadcast auth changes
  final _userController = StreamController<UserModel?>.broadcast();

  // Stream to listen to auth state changes
  Stream<UserModel?> get authStateChanges => _userController.stream;

  // Current user (cached)
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  AuthService._internal() {
    // Listen to Firebase Auth changes
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _currentUser = null;
        _userController.add(null);
      } else {
        // Reload user to get the latest emailVerified status
        await user.reload();
        
        if (!user.emailVerified) {
             _currentUser = null;
             _userController.add(null);
             return;
        }

        // Fetch user data from Firestore
        await _fetchAndEmitUserData(user.uid);
      }
    });
  }

  // Helper to fetch and emit
  Future<void> _fetchAndEmitUserData(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        _currentUser = UserModel.fromMap(docSnapshot.data()!, uid);
        _userController.add(_currentUser);
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      _userController.addError(e);
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = result.user;
      if (user != null) {
         if (!user.emailVerified) {
           await _auth.signOut();
           throw FirebaseAuthException(
             code: 'email-not-verified',
             message: 'Please verify your email before logging in.',
           );
         }

         // Update last login
         await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': DateTime.now().toIso8601String(),
         });
         
         // Fetch explicitly to return the User object
         final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
         if (docSnapshot.exists) {
           _currentUser = UserModel.fromMap(docSnapshot.data()!, user.uid);
           return _currentUser;
         }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Register
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String level,
  }) async {
    try {
      // Create user in FirebaseAuth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Create new user document in Firestore
        final newUserMap = {
          'createdAt': DateTime.now().toIso8601String(),
          'dailyTime': '0',
          'email': email,
          'lastLogin': DateTime.now().toIso8601String(),
          'level': level,
          'levelScore': '0',
          'username': username,
          'completedContentIds': [],
          'dailyStudyMinutes': 0, // 0 indicates not set
          'currentStreak': 0,
          'bestStreak': 0,
          'lastCompletedDate': '',
        };

        // Use uid as document ID
        await _firestore.collection('users').doc(user.uid).set(newUserMap);
        
        // Send verification email
        await user.sendEmailVerification();
        
        await _auth.signOut();
        return null; 
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user level and score
  Future<void> updateUserProgress(String uid, {
    List<String>? completedContentIds,
    String? level,
    String? levelScore,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if(completedContentIds != null) data['completedContentIds'] = completedContentIds;
      if(level != null) data['level'] = level;
      if(levelScore != null) data['levelScore'] = levelScore;

      if(data.isNotEmpty) {
          await _firestore.collection('users').doc(uid).update(data);
          // Refresh local user data
          await _fetchAndEmitUserData(uid);
      }
    } catch (e) {
      debugPrint("Error updating user progress: $e");
      rethrow;
    }
  }

  // Update user daily study minutes
  Future<void> updateDailyStudyMinutes(String uid, int minutes) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'dailyStudyMinutes': minutes,
      });
      // Refresh local user data
      await _fetchAndEmitUserData(uid);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  void dispose() {
    _userController.close();
  }
}
