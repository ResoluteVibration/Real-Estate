import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Model for the 'properties' collection.
class Property {
  final String propertyId;
  final String title;
  final String? description;
  final String locationAddress;
  final PropertyType propertyType;
  final int size;
  final double price;
  final bool isNegotiable;
  final ConstructionStatus constructionStatus;
  final String? readyBy;
  final Furnishing furnishing;
  final String pDetailsId;
  final String cityId; // Added for the new City dropdown
  final String ownerId;
  final DateTime createdAt;

  Property({
    required this.propertyId,
    required this.title,
    this.description,
    required this.locationAddress,
    required this.propertyType,
    required this.size,
    required this.price,
    required this.isNegotiable,
    required this.constructionStatus,
    this.readyBy,
    required this.furnishing,
    required this.pDetailsId,
    required this.cityId,
    required this.ownerId,
    required this.createdAt,
  });

  // Creates a Property object from a Firestore document.
  factory Property.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Property(
      propertyId: snapshot.id,
      title: data?['title'] as String,
      description: data?['description'] as String?,
      locationAddress: data?['location_address'] as String,
      propertyType: (data?['property_type'] as String).toPropertyTypeEnum(),
      size: (data?['size'] as num).toInt(),
      price: (data?['price'] as num).toDouble(),
      isNegotiable: data?['is_negotiable'] as bool,
      constructionStatus: (data?['construction_status'] as String).toConstructionStatusEnum(),
      readyBy: data?['ready_by'] as String?,
      furnishing: (data?['furnishing'] as String).toFurnishingEnum(),
      pDetailsId: data?['p_details_id'] as String,
      cityId: data?['city_id'] as String,
      ownerId: data?['owner_id'] as String,
      createdAt: (data?['created_at'] as Timestamp).toDate(),
    );
  }

  // Converts a Property object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'location_address': locationAddress,
      'property_type': propertyType.name,
      'size': size,
      'price': price,
      'is_negotiable': isNegotiable,
      'construction_status': constructionStatus.name,
      'ready_by': readyBy,
      'furnishing': furnishing.name,
      'p_details_id': pDetailsId,
      'city_id': cityId,
      'owner_id': ownerId,
      'created_at': createdAt,
    };
  }
}

// Extension to convert String to enum
extension on String {
  PropertyType toPropertyTypeEnum() {
    return PropertyType.values.firstWhere((e) => e.name == this, orElse: () => PropertyType.apartment);
  }
  ConstructionStatus toConstructionStatusEnum() {
    return ConstructionStatus.values.firstWhere((e) => e.name == this, orElse: () => ConstructionStatus.underConstruction);
  }
  Furnishing toFurnishingEnum() {
    return Furnishing.values.firstWhere((e) => e.name == this, orElse: () => Furnishing.unfurnished);
  }
}
