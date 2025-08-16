import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the 'enquiries' collection (one per user–property pair).
class Enquiry {
  final String propertyId;
  final String userId;
  final int count;                      // how many times user enquired
  final DateTime firstContactedDate;
  final DateTime latestContactedDate;

  Enquiry({
    required this.propertyId,
    required this.userId,
    required this.count,
    required this.firstContactedDate,
    required this.latestContactedDate,
  });

  /// Creates an Enquiry object from a Firestore document.
  factory Enquiry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Enquiry(
      propertyId: data?['property_id'] as String,
      userId: data?['user_id'] as String,
      count: data?['count'] as int? ?? 0,
      firstContactedDate: (data?['first_contacted_date'] as Timestamp).toDate(),
      latestContactedDate: (data?['latest_contacted_date'] as Timestamp).toDate(),
    );
  }

  /// Converts an Enquiry object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      "property_id": propertyId,
      "user_id": userId,
      "count": count,
      "first_contacted_date": Timestamp.fromDate(firstContactedDate),
      "latest_contacted_date": Timestamp.fromDate(latestContactedDate),
    };
  }
}
