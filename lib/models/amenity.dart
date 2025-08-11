import 'package:cloud_firestore/cloud_firestore.dart';

class Amenity {
  final String amenityId;
  final String amenityName;

  Amenity({
    required this.amenityId,
    required this.amenityName,
  });

  // Creates an Amenity object from a Firestore document.
  factory Amenity.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Amenity(
      amenityId: snapshot.id,
      amenityName: data?['amenity_name'] as String,
    );
  }

  // Converts an Amenity object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      "amenity_name": amenityName,
    };
  }
}