// lib/models/property_details.dart
import 'package:cloud_firestore/cloud_firestore.dart';
/// Model for the 'property_details' collection. This is for predefined property details.

class PropertyDetails {
  final String pDetailsId;
  final int bhk;
  final int bathrooms;
  final int balconies;


  PropertyDetails({
    required this.pDetailsId,
    required this.bhk,
    required this.bathrooms,
    required this.balconies,
  });

// Creates a PropertyDetails object from a Firestore document.

  factory PropertyDetails.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return PropertyDetails(
      pDetailsId: snapshot.id,
      bhk: data?['bhk'] as int,
      bathrooms: data?['bathrooms'] as int,
      balconies: data?['balconies'] as int,
    );
  }

// Converts a PropertyDetails object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      'bhk': bhk,
      'bathrooms': bathrooms,
      'balconies': balconies,
    };
  }
}