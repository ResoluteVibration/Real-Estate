// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import '../models/enums.dart';
import '../models/agent.dart'; // Import the Agent model

class AuthProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  bool _isLoggingIn = false;
  bool _isRegistering = false;

  User? get currentUser => _currentUser;
  bool get isLoggingIn => _isLoggingIn;
  bool get isRegistering => _isRegistering;

  // Function to register a new user with optional agent details.
  Future<void> registerUser({
    required User user,
    String? licenseNumber,
    String? agencyName,
  }) async {
    _isRegistering = true;
    notifyListeners();
    try {
      // Check if user with this email already exists.
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('Email already in use.');
      }

      // Use a batch to ensure both user and agent (if applicable) are created atomically.
      final batch = _firestore.batch();
      final userDocRef = _firestore.collection('users').doc(); // Create a new document reference

      // Add the new user to Firestore using a batch set operation.
      // We'll create a new User object with the Firestore-generated ID.
      final newUser = user.copyWith(
        userId: userDocRef.id,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      batch.set(userDocRef, newUser.toFirestore());

      // If the user is an agent, create and save the agent model as well.
      if (newUser.userRole == UserRole.agent &&
          licenseNumber != null &&
          agencyName != null) {
        final agentDocRef = _firestore.collection('agents').doc(newUser.userId);
        final newAgent = Agent(
          agentId: newUser.userId,
          userId: newUser.userId,
          licenseNumber: licenseNumber,
          agencyName: agencyName,
        );
        batch.set(agentDocRef, newAgent.toFirestore());
      }

      // Commit the batch to save all changes.
      await batch.commit();

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
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('User not found.');
      }

      final doc = querySnapshot.docs.first;
      final user = User.fromFirestore(doc);

      // Check if the password matches.
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
