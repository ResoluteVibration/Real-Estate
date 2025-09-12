import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/enums.dart';
import '../models/agent.dart'; // Import the Agent model

class AuthProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  Agent? _currentAgent;
  bool _isLoggingIn = false;
  bool _isRegistering = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  Agent? get currentAgent => _currentAgent;
  bool get isLoggingIn => _isLoggingIn;
  bool get isRegistering => _isRegistering;
  bool get isLoading => _isLoading;

  String? get userId => _currentUser?.userId;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  static const String _userIdKey = 'userId';

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _saveUserToPrefs(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  Future<void> _removeUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString(_userIdKey);
    if (savedUserId != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(savedUserId).get();
        if (userDoc.exists) {
          _currentUser = User.fromFirestore(userDoc);
          if (_currentUser!.userRole == UserRole.agent) {
            final agentDoc =
            await _firestore.collection('agents').doc(_currentUser!.userId).get();
            if (agentDoc.exists) {
              _currentAgent = Agent.fromFirestore(agentDoc);
            }
          }
          notifyListeners();
        } else {
          _removeUserFromPrefs();
        }
      } catch (e) {
        debugPrint('Error loading user from local storage: $e');
        _removeUserFromPrefs();
      }
    }
  }

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
        avatarUrl: user.avatarUrl ?? '',
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

      await _saveUserToPrefs(_currentUser!.userId);
    } catch (e) {
      debugPrint('Registration Error: $e');
      rethrow;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

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
          final agentDoc =
          await _firestore.collection('agents').doc(user.userId).get();
          if (agentDoc.exists) {
            _currentAgent = Agent.fromFirestore(agentDoc);
          }
        }
        await _saveUserToPrefs(_currentUser!.userId);
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

  /// 🔑 Verify if the entered password matches the current user's password
  Future<bool> verifyPassword(String currentPassword) async {
    if (_currentUser == null) return false;
    return _currentUser!.password == currentPassword;
  }

  /// 🔑 Update password in Firestore and locally
  Future<void> updatePassword(String newPassword) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final userRef = _firestore.collection('users').doc(_currentUser!.userId);

      await userRef.update({'password': newPassword});

      // Update local cache
      _currentUser = _currentUser!.copyWith(password: newPassword);

      notifyListeners();
    } catch (e) {
      debugPrint("Error updating password: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> fetchUserProfile() async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final userDoc =
      await _firestore.collection('users').doc(_currentUser!.userId).get();
      if (userDoc.exists) {
        _currentUser = User.fromFirestore(userDoc);
        if (_currentUser!.userRole == UserRole.agent) {
          final agentDoc =
          await _firestore.collection('agents').doc(_currentUser!.userId).get();
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

      batch.update(userDocRef, updatedUser.toFirestore());

      if (updatedUser.userRole == UserRole.agent) {
        final agentDocRef =
        _firestore.collection('agents').doc(updatedUser.userId);
        if (_currentAgent != null) {
          final updatedAgent = _currentAgent!.copyWith(
            licenseNumber: licenseNumber,
            agencyName: agencyName,
          );
          batch.update(agentDocRef, updatedAgent.toFirestore());
        } else {
          final newAgent = Agent(
            agentId: updatedUser.userId,
            userId: updatedUser.userId,
            licenseNumber: licenseNumber!,
            agencyName: agencyName!,
          );
          batch.set(agentDocRef, newAgent.toFirestore());
        }
      } else if (_currentAgent != null) {
        final agentDocRef =
        _firestore.collection('agents').doc(updatedUser.userId);
        batch.delete(agentDocRef);
      }

      await batch.commit();

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

  Future<void> updateUserRole(String role,
      {String? licenseNumber, String? agencyName}) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final userRef =
      _firestore.collection('users').doc(_currentUser!.userId);
      final roleEnum = UserRole.values.firstWhere(
            (e) => e.name.toLowerCase() == role.toLowerCase(),
        orElse: () => UserRole.buyer,
      );

      await userRef.update({
        'user_role': roleEnum.name,
      });

      _currentUser = _currentUser!.copyWith(userRole: roleEnum);

      if (roleEnum == UserRole.agent) {
        final agentRef =
        _firestore.collection('agents').doc(_currentUser!.userId);
        final newAgent = Agent(
          agentId: _currentUser!.userId,
          userId: _currentUser!.userId,
          licenseNumber: licenseNumber!,
          agencyName: agencyName!,
        );

        await _firestore.runTransaction((transaction) async {
          transaction.set(agentRef, newAgent.toFirestore(), SetOptions(merge: true));
        });

        _currentAgent = newAgent;
      } else if (_currentAgent != null) {
        final agentRef =
        _firestore.collection('agents').doc(_currentUser!.userId);
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
      avatarUrl: '', // default empty for guest
    );
    _currentAgent = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _currentAgent = null;
    await _removeUserFromPrefs();
    notifyListeners();
  }

  // A new method for an admin to make another user an admin.
  Future<void> makeUserAdmin(String userId) async {
    if (_currentUser == null || !isAdmin) {
      throw Exception('Permission denied: Only admins can perform this action.');
    }
    _isLoading = true;
    notifyListeners();
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({'isAdmin': true});
    } catch (e) {
      debugPrint('Error promoting user to admin: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // A new method for an admin to revoke another user's admin privileges.
  Future<void> revokeUserAdmin(String userId) async {
    if (_currentUser == null || !isAdmin) {
      throw Exception('Permission denied: Only admins can perform this action.');
    }
    _isLoading = true;
    notifyListeners();
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({'isAdmin': false});
    } catch (e) {
      debugPrint('Error revoking admin privileges: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // A new method for an admin to delete a user.
  Future<void> deleteUser(String userId) async {
    if (_currentUser == null || !isAdmin) {
      throw Exception('Permission denied: Only admins can perform this action.');
    }
    _isLoading = true;
    notifyListeners();
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.delete();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // A new method for an admin to edit a user's city.
  Future<void> adminUpdateUserCity(String userId, String cityId) async {
    if (_currentUser == null || !isAdmin) {
      throw Exception('Permission denied: Only admins can perform this action.');
    }
    _isLoading = true;
    notifyListeners();
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({'city_id': cityId});
    } catch (e) {
      debugPrint('Error updating user city as admin: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
