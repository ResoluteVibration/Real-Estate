import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contacted.dart';
import 'package:flutter/foundation.dart';

class ContactedProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache storage
  final Map<String, List<Contacted>> _cachedContactedProperties = {};

  // New private method to fetch the ownerId of a property
  Future<String?> _getOwnerId(String propertyId) async {
    try {
      final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
      if (propertyDoc.exists) {
        return propertyDoc.get('owner_id') as String?;
      }
    } catch (e) {
      debugPrint('Error fetching property ownerId: $e');
    }
    return null;
  }

  /// Add a contacted property (only once per user-property pair)
  Future<String?> addContacted(String userId, String propertyId) async {
    try {
      // Step 1: Check if the user is the owner of the property
      final ownerId = await _getOwnerId(propertyId);
      if (ownerId != null && userId == ownerId) {
        return "You cannot contact your own property.";
      }

      // Step 2: Check if the property has already been contacted by the user
      final query = await _firestore
          .collection('contacted')
          .where('userId', isEqualTo: userId)
          .where('propertyId', isEqualTo: propertyId)
          .get();

      if (query.docs.isEmpty) {
        await _firestore.collection('contacted').add({
          'userId': userId,
          'propertyId': propertyId,
          'contactedAt': Timestamp.now(),
        });

        // Invalidate cache so UI refreshes
        _cachedContactedProperties.remove(userId);
        notifyListeners();
        return null; // Success, no error message
      } else {
        return "Property already contacted.";
      }
    } catch (e) {
      debugPrint('Error adding contacted property: $e');
      rethrow;
    }
  }

  /// Stream contacted properties (sorted in Dart, not Firestore)
  Stream<List<Contacted>> getUserContacted(String userId) {
    return _firestore
        .collection('contacted')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list =
      snapshot.docs.map((doc) => Contacted.fromFirestore(doc)).toList();

      // 🔹 Sort client-side by contactedAt (newest first)
      list.sort((a, b) => b.contactedAt.compareTo(a.contactedAt));

      _cachedContactedProperties[userId] = list;
      return list;
    });
  }

  /// Get cached contacted properties (if available)
  List<Contacted>? getCachedContacted(String userId) {
    return _cachedContactedProperties[userId];
  }

  /// Delete a contacted property entry
  Future<void> removeContacted(String userId, String propertyId) async {
    try {
      final query = await _firestore
          .collection('contacted')
          .where('userId', isEqualTo: userId)
          .where('propertyId', isEqualTo: propertyId)
          .get();

      for (var doc in query.docs) {
        await _firestore.collection('contacted').doc(doc.id).delete();
      }

      // Update cache
      _cachedContactedProperties[userId]?.removeWhere(
              (contacted) => contacted.propertyId == propertyId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error removing contacted property: $e");
      rethrow;
    }
  }

  /// Clear cache (on logout)
  void clearCache() {
    _cachedContactedProperties.clear();
  }
}