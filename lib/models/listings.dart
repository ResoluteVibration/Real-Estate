import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/models/enums.dart'; // Import enums for ListingStatus

/// Model for the 'listings' collection.
class Listing {
  final String listingId;
  final String propertyId;
  final String userId;
  final ListingStatus status;
  final DateTime listedAt;

  Listing({
    required this.listingId,
    required this.propertyId,
    required this.userId,
    required this.status,
    required this.listedAt,
  });

  // Creates a Listing object from a Firestore document.
  factory Listing.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Listing(
      listingId: snapshot.id,
      propertyId: data?['property_id'] as String,
      userId: data?['user_id'] as String,
      status: ListingStatus.values.firstWhere((e) => e.toString().split('.').last == data?['status']),
      listedAt: (data?['listed_at'] as Timestamp).toDate(),
    );
  }

  // Converts a Listing object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      "property_id": propertyId,
      "user_id": userId,
      "status": status.toString().split('.').last,
      "listed_at": Timestamp.fromDate(listedAt),
    };
  }
}