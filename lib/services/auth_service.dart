import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

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
        // user object might need refreshing after reload, but the one from stream might be stale regarding verification if we don't fetch fresh.
        // Actually, user.reload() refreshes the current instance in FirebaseAuth cache, but we should check the refreshed property.
        // However, `user` variable here is from the event. It's safer to get `_auth.currentUser` after reload or trust the event if it triggered by reload (which it usually doesn't).
        // Let's rely on the property. Ideally we should allow login ONLY if verified.
        
        if (!user.emailVerified) {
             // If not verified, we treat as not logged in for the app's purpose
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
      } else {
        // If doc doesn't exist (e.g. during registration race), we might wait or do nothing.
        // We assume register/signIn logic might also handle the emission in those cases.
      }
    } catch (e) {
      // Error logging can be added here if needed
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

  // Register with email, password, username, and level
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
        // Create new user document in Firestore (NO PASSWORD)
        final newUserMap = {
          'createdAt': DateTime.now().toIso8601String(),
          'dailyTime': '0',
          'email': email,
          // 'password': password, // REMOVED
          'lastLogin': DateTime.now().toIso8601String(),
          'level': level,
          'levelScore': '0',
          'username': username,
        };

        // Use uid as document ID
        await _firestore.collection('users').doc(user.uid).set(newUserMap);
        
        // Send verification email
        await user.sendEmailVerification();
        
        // Sign out immediately so they're not logged in automatically
        await _auth.signOut();
        
        // Return null or handle as needed to indicate "waiting for verification"
        // Since the return type is Future<UserModel?>, returning null is appropriate 
        // as we are effectively not "logging in" the user yet.
        return null; 
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user level and score
  Future<void> updateUserLevel(String uid, String newLevel, String score) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'level': newLevel,
        'levelScore': score,
      });
      // Refresh local user data
      await _fetchAndEmitUserData(uid);
    } catch (e) {
      rethrow;
    }
  }

  // Update user daily study goal
  Future<void> updateDailyStudyGoal(String uid, int hours) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'dailyStudyGoal': hours,
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
    // Listener will catch null and update stream
  }
  
  void dispose() {
    _userController.close();
  }
}
