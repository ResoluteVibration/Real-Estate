// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import '../models/enums.dart';
import '../models/agent.dart'; // Import the Agent model

class AuthProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  Agent? _currentAgent;
  bool _isLoggingIn = false;
  bool _isRegistering = false;
  bool _isLoading = false; // Added for fetching/updating profile

  User? get currentUser => _currentUser;
  Agent? get currentAgent => _currentAgent;
  bool get isLoggingIn => _isLoggingIn;
  bool get isRegistering => _isRegistering;
  bool get isLoading => _isLoading;

  // This is the essential getter to provide the current user's ID
  // It is needed by the favorite and other pages.
  String? get userId => _currentUser?.userId;

  // Function to register a new user with optional agent details.
  Future<void> registerUser({
    required User user,
    String? licenseNumber,
    String? agencyName,
  }) async {
    _isRegistering = true;
    notifyListeners();
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('Email already in use.');
      }

      final batch = _firestore.batch();
      final userDocRef = _firestore.collection('users').doc();
      final newUser = user.copyWith(
        userId: userDocRef.id,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      batch.set(userDocRef, newUser.toFirestore());

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

      await batch.commit();

      _currentUser = newUser;
      if (newUser.userRole == UserRole.agent) {
        _currentAgent = Agent(
          agentId: newUser.userId,
          userId: newUser.userId,
          licenseNumber: licenseNumber!,
          agencyName: agencyName!,
        );
      } else {
        _currentAgent = null;
      }
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

      if (user.password == password) {
        _currentUser = user;
        if (user.userRole == UserRole.agent) {
          final agentDoc = await _firestore.collection('agents').doc(user.userId).get();
          if (agentDoc.exists) {
            _currentAgent = Agent.fromFirestore(agentDoc);
          }
        }
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

  // Function to fetch the full user profile including agent details.
  Future<void> fetchUserProfile() async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final userDoc = await _firestore.collection('users').doc(_currentUser!.userId).get();
      if (userDoc.exists) {
        _currentUser = User.fromFirestore(userDoc);
        if (_currentUser!.userRole == UserRole.agent) {
          final agentDoc = await _firestore.collection('agents').doc(_currentUser!.userId).get();
          if (agentDoc.exists) {
            _currentAgent = Agent.fromFirestore(agentDoc);
          } else {
            _currentAgent = null;
          }
        } else {
          _currentAgent = null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Function to update the user profile.
  Future<void> updateUserProfile({
    required User updatedUser,
    String? licenseNumber,
    String? agencyName,
  }) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final batch = _firestore.batch();
      final userDocRef = _firestore.collection('users').doc(updatedUser.userId);

      // Update the user document
      batch.update(userDocRef, updatedUser.toFirestore());

      // Handle agent-specific updates
      if (updatedUser.userRole == UserRole.agent) {
        final agentDocRef = _firestore.collection('agents').doc(updatedUser.userId);
        if (_currentAgent != null) {
          // Update existing agent profile
          final updatedAgent = _currentAgent!.copyWith(
            licenseNumber: licenseNumber,
            agencyName: agencyName,
          );
          batch.update(agentDocRef, updatedAgent.toFirestore());
        } else {
          // Create new agent profile
          final newAgent = Agent(
            agentId: updatedUser.userId,
            userId: updatedUser.userId,
            licenseNumber: licenseNumber!,
            agencyName: agencyName!,
          );
          batch.set(agentDocRef, newAgent.toFirestore());
        }
      } else if (_currentAgent != null) {
        // If user is no longer an agent, delete the agent document
        final agentDocRef = _firestore.collection('agents').doc(updatedUser.userId);
        batch.delete(agentDocRef);
      }

      await batch.commit();

      // Update local state after successful update
      _currentUser = updatedUser;
      if (updatedUser.userRole == UserRole.agent) {
        _currentAgent = Agent(
          agentId: updatedUser.userId,
          userId: updatedUser.userId,
          licenseNumber: licenseNumber!,
          agencyName: agencyName!,
        );
      } else {
        _currentAgent = null;
      }

    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the current user's role and, for agents, their professional details.
  Future<void> updateUserRole(String role, {String? licenseNumber, String? agencyName}) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final userRef = _firestore.collection('users').doc(_currentUser!.userId);
      final roleEnum = UserRole.values.firstWhere(
            (e) => e.name.toLowerCase() == role.toLowerCase(),
        orElse: () => UserRole.buyer,
      );

      // Update the user's role in Firestore without updated_at
      await userRef.update({
        'user_role': roleEnum.name,
      });

      // Update the local user object with the new role
      _currentUser = _currentUser!.copyWith(userRole: roleEnum);

      // Handle agent-specific updates if the new role is 'Agent'
      if (roleEnum == UserRole.agent) {
        final agentRef = _firestore.collection('agents').doc(_currentUser!.userId);
        final newAgent = Agent(
          agentId: _currentUser!.userId,
          userId: _currentUser!.userId,
          licenseNumber: licenseNumber!,
          agencyName: agencyName!,
        );

        // Use a transaction to ensure atomicity
        await _firestore.runTransaction((transaction) async {
          transaction.set(agentRef, newAgent.toFirestore(), SetOptions(merge: true));
        });

        // Update local state with new agent info
        _currentAgent = newAgent;
      } else if (_currentAgent != null) {
        // If the role is no longer 'Agent', delete the agent data
        final agentRef = _firestore.collection('agents').doc(_currentUser!.userId);
        await agentRef.delete();
        _currentAgent = null;
      }

    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
    } finally {
      _isLoading = false;
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
    _currentAgent = null;
    notifyListeners();
  }

  // Function to log out the current user.
  Future<void> logout() async {
    _currentUser = null;
    _currentAgent = null;
    notifyListeners();
  }
}
