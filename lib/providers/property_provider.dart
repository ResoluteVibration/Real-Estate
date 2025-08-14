// lib/providers/property_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:real_estate/models/property.dart';
import 'package:real_estate/models/property_image.dart';
import 'package:real_estate/models/property_with_images.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:image_picker/image_picker.dart';

class PropertyProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<PropertyWithImages> _userListings = [];
  bool _isLoading = false;
  String? _error;

  List<PropertyWithImages> get userListings => _userListings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches all properties and their images posted by a specific user in an efficient way.
  Future<void> fetchUserListings(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Step 1: Fetch all property documents for the user
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: userId)
          .get();

      final properties = propertiesSnapshot.docs
          .map((doc) => Property.fromFirestore(doc))
          .toList();

      if (properties.isEmpty) {
        _userListings = [];
        notifyListeners();
        return;
      }

      final propertyIds = properties.map((p) => p.propertyId).toList();

      // Step 2: Fetch all image documents for all the fetched properties in one query
      final imagesSnapshot = await _firestore
          .collection('property_images')
          .where('property_id', whereIn: propertyIds)
          .get();

      final allPropertyImages = imagesSnapshot.docs
          .map((doc) => PropertyImage.fromFirestore(doc))
          .toList();

      // Step 3: Combine the data into a list of PropertyWithImages objects
      _userListings = properties.map((property) {
        final imagesForProperty = allPropertyImages
            .where((img) => img.propertyId == property.propertyId)
            .map((img) => img.imageUrl)
            .toList();
        return PropertyWithImages(property: property, images: imagesForProperty);
      }).toList();

    } on FirebaseException catch (e) {
      _error = 'Failed to fetch listings: ${e.message}';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a property, its images from storage, and related documents from Firestore.
  Future<void> deleteListing(String propertyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final propertyRef = _firestore.collection('properties').doc(propertyId);

      // Step 1: Get image documents to delete from storage and Firestore
      final imagesSnapshot = await _firestore
          .collection('property_images')
          .where('property_id', isEqualTo: propertyId)
          .get();

      final batch = _firestore.batch();

      // Step 2: Delete images from Firebase Storage
      for (final doc in imagesSnapshot.docs) {
        final imageUrl = doc.data()['image_url'] as String;
        try {
          final imageRef = _storage.refFromURL(imageUrl);
          await imageRef.delete();
          debugPrint('Deleted image from storage: $imageUrl');
        } catch (e) {
          debugPrint('Failed to delete image from storage: $e');
        }

        // Step 3: Add image document deletion to the batch
        batch.delete(doc.reference);
      }

      // Step 4: Add property document deletion to the batch
      batch.delete(propertyRef);

      // Step 5: Commit the batch to perform all deletions atomically
      await batch.commit();
      debugPrint('Property and associated image documents deleted successfully.');

      // Step 6: Update the local list
      _userListings.removeWhere((pwi) => pwi.property.propertyId == propertyId);

    } on FirebaseException catch (e) {
      _error = 'Failed to delete listing: ${e.message}';
      debugPrint(_error);
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates an existing property listing and its associated data (amenities and images).
  Future<void> updateListing({
    required String propertyId,
    required Property updatedProperty,
    required List<String> oldAmenityIds,
    required List<String> newAmenityIds,
    required List<String> existingImageUrls,
    required List<String> deletedImageUrls,
    required List<XFile> newImages,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final propertyDocRef = _firestore.collection('properties').doc(propertyId);

      // 1. Update the main property document
      batch.set(propertyDocRef, updatedProperty.toFirestore());

      // 2. Manage amenities: delete old ones, add new ones
      final amenitiesToDelete = oldAmenityIds.where((id) => !newAmenityIds.contains(id)).toList();
      final amenitiesToAdd = newAmenityIds.where((id) => !oldAmenityIds.contains(id)).toList();

      if (amenitiesToDelete.isNotEmpty) {
        final querySnapshot = await _firestore.collection('property_amenities')
            .where('property_id', isEqualTo: propertyId)
            .where('amenity_id', whereIn: amenitiesToDelete)
            .get();
        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      for (final amenityId in amenitiesToAdd) {
        final amenityDocRef = _firestore.collection('property_amenities').doc();
        batch.set(amenityDocRef, {
          'property_id': propertyId,
          'amenity_id': amenityId,
        });
      }

      // 3. Manage images: delete old ones, upload new ones
      // Delete images from Firebase Storage and their Firestore documents
      if (deletedImageUrls.isNotEmpty) {
        final imagesSnapshot = await _firestore.collection('property_images')
            .where('property_id', isEqualTo: propertyId)
            .where('image_url', whereIn: deletedImageUrls)
            .get();

        for (final doc in imagesSnapshot.docs) {
          final imageUrl = doc.data()['image_url'] as String;
          try {
            final imageRef = _storage.refFromURL(imageUrl);
            await imageRef.delete();
            debugPrint('Deleted image from storage: $imageUrl');
          } catch (e) {
            debugPrint('Failed to delete image from storage: $e');
          }
          batch.delete(doc.reference);
        }
      }

      // Upload new images and add their documents to the batch
      if (newImages.isNotEmpty) {
        for (final imageXFile in newImages) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageXFile.name}';
          final storageRef = _storage.ref().child('properties/$propertyId/images/$fileName');
          String downloadUrl;
          if (kIsWeb) {
            final bytes = await imageXFile.readAsBytes();
            final uploadTask = storageRef.putData(bytes);
            final snapshot = await uploadTask.whenComplete(() {});
            downloadUrl = await snapshot.ref.getDownloadURL();
          } else {
            final imageFile = File(imageXFile.path);
            final uploadTask = storageRef.putFile(imageFile);
            final snapshot = await uploadTask.whenComplete(() {});
            downloadUrl = await snapshot.ref.getDownloadURL();
          }
          final imageDocRef = _firestore.collection('property_images').doc();
          batch.set(imageDocRef, {
            'property_id': propertyId,
            'image_url': downloadUrl,
            'uploaded_at': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      // 4. Update the local list
      // This is a simple but effective way to refresh the data
      await fetchUserListings(updatedProperty.ownerId);

    } on FirebaseException catch (e) {
      _error = 'Failed to update listing: ${e.message}';
      debugPrint(_error);
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
