import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      
      // The listener in constructor will pick this up, but we can return _currentUser
      // waiting for the listener might be tricky, so we can manual fetch to return fast.
      // However, to keep it simple, we await the stream? No, return value logic:
      
      final User? user = result.user;
      if (user != null) {
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
        
        // Fetch and cache manually to ensure immediate availability
        _currentUser = UserModel.fromMap(newUserMap, user.uid);
        _userController.add(_currentUser);
        return _currentUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; 
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;
      
      if (user != null) {
        // Check if user exists in Firestore
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

        if (docSnapshot.exists) {
           await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': DateTime.now().toIso8601String(),
          });
          _currentUser = UserModel.fromMap(docSnapshot.data()!, user.uid);
        } else {
          // Create new user from Google details
          final newUserMap = {
            'createdAt': DateTime.now().toIso8601String(),
            'dailyTime': '0',
            'email': user.email ?? '',
            // 'password': '', // REMOVED
            'lastLogin': DateTime.now().toIso8601String(),
            'level': 'Beginner', // Default for Google Sign In
            'levelScore': '0',
            'username': user.displayName ?? 'Google User',
          };

          await _firestore.collection('users').doc(user.uid).set(newUserMap);
          _currentUser = UserModel.fromMap(newUserMap, user.uid);
        }

        _userController.add(_currentUser);
        return _currentUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    // Listener will catch null and update stream
  }
  
  void dispose() {
    _userController.close();
  }
}
