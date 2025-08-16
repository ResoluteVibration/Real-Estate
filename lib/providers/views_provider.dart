// lib/providers/views_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ViewsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Increment view count only if user hasn't viewed before.
  Future<void> incrementView(String propertyId, String userId) async {
    final docRef = _firestore.collection('views').doc(propertyId);
    final today = _getTodayDateString();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        transaction.set(docRef, {
          'property_id': propertyId,
          'views_count': 1,
          'saved_count': 0,
          'enquiry_count': 0,
          'viewed_users': [userId],
          'daily_views': {today: 1},
          'daily_saves': {},
          'daily_enquiries': {},
        });
      } else {
        final data = snapshot.data()!;
        final viewedUsers = List<String>.from(data['viewed_users'] ?? []);

        if (!viewedUsers.contains(userId)) {
          viewedUsers.add(userId);
          final dailyViews = Map<String, dynamic>.from(data['daily_views'] ?? {});
          dailyViews.update(today, (value) => value + 1, ifAbsent: () => 1);

          transaction.update(docRef, {
            'views_count': (data['views_count'] ?? 0) + 1,
            'viewed_users': viewedUsers,
            'daily_views': dailyViews,
          });
        }
      }
    });
  }

  /// Increment or decrement save count (favourite)
  Future<void> updateSave(String propertyId, bool isSaved) async {
    final docRef = _firestore.collection('views').doc(propertyId);
    final today = _getTodayDateString();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        transaction.set(docRef, {
          'property_id': propertyId,
          'views_count': 0,
          'saved_count': isSaved ? 1 : 0,
          'enquiry_count': 0,
          'daily_views': {},
          'daily_saves': {today: isSaved ? 1 : 0},
          'daily_enquiries': {},
        });
      } else {
        final data = snapshot.data()!;
        final currentCount = data['saved_count'] ?? 0;
        final dailySaves = Map<String, dynamic>.from(data['daily_saves'] ?? {});

        if (isSaved) {
          dailySaves.update(today, (value) => value + 1, ifAbsent: () => 1);
        } else {
          if ((dailySaves[today] ?? 0) > 0) {
            dailySaves.update(today, (value) => value - 1);
          }
        }

        transaction.update(docRef, {
          'saved_count': isSaved ? currentCount + 1 : (currentCount > 0 ? currentCount - 1 : 0),
          'daily_saves': dailySaves,
        });
      }
    });
  }

  /// Increment enquiry count when "Contact Now" clicked
  Future<void> incrementEnquiry(String propertyId) async {
    final docRef = _firestore.collection('views').doc(propertyId);
    final today = _getTodayDateString();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        transaction.set(docRef, {
          'property_id': propertyId,
          'views_count': 0,
          'saved_count': 0,
          'enquiry_count': 1,
          'daily_views': {},
          'daily_saves': {},
          'daily_enquiries': {today: 1},
        });
      } else {
        final data = snapshot.data()!;
        final dailyEnquiries = Map<String, dynamic>.from(data['daily_enquiries'] ?? {});
        dailyEnquiries.update(today, (value) => value + 1, ifAbsent: () => 1);

        transaction.update(docRef, {
          'enquiry_count': (data['enquiry_count'] ?? 0) + 1,
          'daily_enquiries': dailyEnquiries,
        });
      }
    });
  }

  /// Get property stats stream (for View Responses page)
  Stream<DocumentSnapshot<Map<String, dynamic>>> getPropertyStats(String propertyId) {
    return _firestore.collection('views').doc(propertyId).snapshots();
  }
}