import 'package:cloud_firestore/cloud_firestore.dart';


/// Model for the 'favourites' collection.
class Favourite {
  final String favouriteId;
  final String propertyId;
  final String userId;
  final DateTime createdAt;

  Favourite({
    required this.favouriteId,
    required this.propertyId,
    required this.userId,
    required this.createdAt,
  });

  // Creates a Favourite object from a Firestore document.
  factory Favourite.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Favourite(
      favouriteId: snapshot.id,
      propertyId: data?['property_id'] as String,
      userId: data?['user_id'] as String,
      createdAt: (data?['created_at'] as Timestamp).toDate(),
    );
  }

  // Converts a Favourite object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      "property_id": propertyId,
      "user_id": userId,
      "created_at": Timestamp.fromDate(createdAt),
    };
  }
}