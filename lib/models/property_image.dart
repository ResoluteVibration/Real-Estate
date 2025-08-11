// lib/models/property_image.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the 'property_images' collection.
class PropertyImage {
  final String propertyImageId;
  final String propertyId;
  final String imageUrl;
  final DateTime uploadedAt;

  PropertyImage({
    required this.propertyImageId,
    required this.propertyId,
    required this.imageUrl,
    required this.uploadedAt,
  });

  // Creates a PropertyImage object from a Firestore document.
  factory PropertyImage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return PropertyImage(
      propertyImageId: snapshot.id,
      propertyId: data?['property_id'] as String,
      imageUrl: data?['image_url'] as String,
      uploadedAt: (data?['uploaded_at'] as Timestamp).toDate(),
    );
  }

  // Converts a PropertyImage object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      'property_id': propertyId,
      'image_url': imageUrl,
      'uploaded_at': uploadedAt,
    };
  }
}
