import 'package:cloud_firestore/cloud_firestore.dart';

class Contacted {
  final String contactedId;   // Firestore doc ID
  final String propertyId;    // ID of the contacted property
  final String userId;        // ID of the user who contacted
  final Timestamp contactedAt; // Timestamp when contact happened

  Contacted({
    required this.contactedId,
    required this.propertyId,
    required this.userId,
    required this.contactedAt,
  });

  factory Contacted.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Contacted(
      contactedId: doc.id,
      propertyId: data['propertyId'] ?? '',
      userId: data['userId'] ?? '',
      contactedAt: data['contactedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'userId': userId,
      'contactedAt': contactedAt,
    };
  }
}
