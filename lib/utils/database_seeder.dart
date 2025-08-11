import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DatabaseSeeder {
  // Make the seedDatabase method static
  static Future<void> seedDatabase(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // Check if collections are already populated to prevent duplication
    final amenitiesSnapshot = await firestore.collection('amenities').limit(1).get();
    final detailsSnapshot = await firestore.collection('property_details').limit(1).get();

    if (amenitiesSnapshot.docs.isNotEmpty || detailsSnapshot.docs.isNotEmpty) {
      Fluttertoast.showToast(msg: 'Database is already seeded.');
      return;
    }

    // Seed Amenities Collection
    final amenitiesCollection = firestore.collection('amenities');
    final List<String> amenityNames = [
      'All Amenities',
      'Swimming Pool',
      'Clubhouse',
      'Gym',
      'Kids Play Area',
      'Landscaped Gardens',
      'Tennis Court',
      'Library',
      'Conference Room',
      'Pet Friendly',
      'Shopping Centre',
      'Restaurant',
      'Jogging Track',
      'Indoor Games',
      'Intercom Facility',
    ];

    for (final name in amenityNames) {
      final docRef = amenitiesCollection.doc();
      batch.set(docRef, {'amenity_name': name});
    }

    // Seed Property Details Collection (for BHK, Bathrooms, Balcony)
    final propertyDetailsCollection = firestore.collection('property_details');
    final List<Map<String, dynamic>> detailsData = [
      {'bhk': 1, 'bathrooms': 1, 'balconies': 0},
      {'bhk': 1, 'bathrooms': 1, 'balconies': 1},
      {'bhk': 2, 'bathrooms': 1, 'balconies': 0},
      {'bhk': 2, 'bathrooms': 1, 'balconies': 1},
      {'bhk': 2, 'bathrooms': 2, 'balconies': 1},
      {'bhk': 2, 'bathrooms': 2, 'balconies': 2},
      {'bhk': 3, 'bathrooms': 2, 'balconies': 1},
      {'bhk': 3, 'bathrooms': 2, 'balconies': 2},
      {'bhk': 3, 'bathrooms': 3, 'balconies': 2},
      {'bhk': 3, 'bathrooms': 3, 'balconies': 3},
      {'bhk': 4, 'bathrooms': 3, 'balconies': 2},
      {'bhk': 4, 'bathrooms': 4, 'balconies': 3},
      {'bhk': 5, 'bathrooms': 4, 'balconies': 3},
      {'bhk': 5, 'bathrooms': 5, 'balconies': 4},
      {'bhk': 6, 'bathrooms': 6, 'balconies': 5},
    ];

    for (final data in detailsData) {
      final docRef = propertyDetailsCollection.doc();
      batch.set(docRef, data);
    }

    try {
      await batch.commit();
      Fluttertoast.showToast(msg: 'Database seeded successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to seed database: $e');
    }
  }
}
