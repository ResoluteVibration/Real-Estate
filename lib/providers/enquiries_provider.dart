import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class EnquiriesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add or update enquiry when user clicks "Contact Now"
  Future<void> addOrUpdateEnquiry(String propertyId, String userId) async {
    final docRef = _firestore.collection('enquiries').doc('${propertyId}_$userId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        transaction.set(docRef, {
          'property_id': propertyId,
          'user_id': userId,
          'count': 1,
          'first_contacted_date': FieldValue.serverTimestamp(),
          'latest_contacted_date': FieldValue.serverTimestamp(),
        });
      } else {
        final data = snapshot.data()!;
        transaction.update(docRef, {
          'count': (data['count'] ?? 0) + 1,
          'latest_contacted_date': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Get all enquiries for a property
  Stream<QuerySnapshot<Map<String, dynamic>>> getEnquiriesForProperty(String propertyId) {
    return _firestore
        .collection('enquiries')
        .where('property_id', isEqualTo: propertyId)
        .snapshots();
  }
}
