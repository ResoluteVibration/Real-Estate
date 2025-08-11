import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the 'property_amenity' collection.
class PropertyAmenity {
  final String propertyAmenityId;
  final String propertyId;
  final String amenityId;

  PropertyAmenity({
    required this.propertyAmenityId,
    required this.propertyId,
    required this.amenityId,
  });

  // Creates a PropertyAmenity object from a Firestore document.
  factory PropertyAmenity.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return PropertyAmenity(
      propertyAmenityId: snapshot.id,
      propertyId: data?['property_id'] as String,
      amenityId: data?['amenity_id'] as String,
    );
  }

  // Converts a PropertyAmenity object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      "property_id": propertyId,
      "amenity_id": amenityId,
    };
  }
}
