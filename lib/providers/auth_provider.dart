// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import '../models/enums.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  bool _isLoggingIn = false;
  bool _isRegistering = false;

  User? get currentUser => _currentUser;
  bool get isLoggingIn => _isLoggingIn;
  bool get isRegistering => _isRegistering;

  // Function to register a new user.
  Future<void> registerUser(User user) async {
    _isRegistering = true;
    notifyListeners();
    try {
      // Check if user with this email already exists.
      final querySnapshot = await _firestore.collection('users').where('email', isEqualTo: user.email).get();
      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('Email already in use.');
      }

      // Add the new user to Firestore.
      final docRef = await _firestore.collection('users').add(user.toFirestore());
      final newUser = user.copyWith(userId: docRef.id);
      _currentUser = newUser;
    } catch (e) {
      debugPrint('Registration Error: $e');
      rethrow;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

  // Function to log in a user.
  Future<void> loginUser(String email, String password) async {
    _isLoggingIn = true;
    notifyListeners();
    try {
      // Find the user with the given email.
      final querySnapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('User not found.');
      }

      final doc = querySnapshot.docs.first;
      final userData = doc.data();
      final user = User.fromFirestore(doc);

      // Check if the password matches.
      // This is a simple text-based password check as requested.
      if (user.password == password) {
        _currentUser = user;
      } else {
        throw Exception('Incorrect password.');
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  // Function to log in as a guest for development purposes.
  void loginAsGuest() {
    _currentUser = User(
      userId: 'guest_user_id',
      userRole: UserRole.buyer,
      firstName: 'Guest',
      lastName: 'User',
      email: 'guest@example.com',
      password: '',
      phoneNumber: '',
      whatsappNumber: '',
      address: '',
      cityId: '',
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
    notifyListeners();
  }

  // Function to log out the current user.
  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
}