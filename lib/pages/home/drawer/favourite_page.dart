// lib/pages/home/drawer/favourite_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/models/property.dart';
import 'package:real_estate/models/favourite.dart'; // Using your Favourite model
import 'package:real_estate/providers/auth_provider.dart';
import 'package:real_estate/widgets/property_card_view.dart';
import 'package:real_estate/models/property_with_images.dart';

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Get the current user ID to fetch their favorites
    _currentUserId = Provider.of<AuthProvider>(context, listen: false).userId;
  }

  // A Future to fetch all favorited properties for the current user
  Future<List<PropertyWithImages>> _fetchFavouriteProperties() async {
    if (_currentUserId == null) {
      return [];
    }

    try {
      final favouriteSnapshot = await FirebaseFirestore.instance
          .collection('favourites')
          .where('user_id', isEqualTo: _currentUserId)
          .get();

      if (favouriteSnapshot.docs.isEmpty) {
        return [];
      }

      // First, get the list of favourite objects
      final favouriteDocuments = favouriteSnapshot.docs.map((doc) => Favourite.fromFirestore(doc)).toList();

      // Sort the list in memory by created_at in descending order
      favouriteDocuments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final propertyIds = favouriteDocuments.map((fav) => fav.propertyId).toList();

      final List<Future<PropertyWithImages>> propertyFutures = [];

      for (final propertyId in propertyIds) {
        propertyFutures.add(_fetchPropertyWithImages(propertyId));
      }

      return await Future.wait(propertyFutures);
    } catch (e) {
      debugPrint('Error fetching favourite properties: $e');
      return [];
    }
  }

  // A helper function to fetch a single property and its images
  Future<PropertyWithImages> _fetchPropertyWithImages(String propertyId) async {
    final propertyDoc = await FirebaseFirestore.instance.collection('properties').doc(propertyId).get();
    final imagesSnapshot = await FirebaseFirestore.instance
        .collection('property_images')
        .where('property_id', isEqualTo: propertyId)
        .limit(1)
        .get();

    final property = Property.fromFirestore(propertyDoc);
    final imageUrl = imagesSnapshot.docs.isNotEmpty ? imagesSnapshot.docs.first['image_url'] as String : null;

    return PropertyWithImages(property: property, images: imageUrl != null ? [imageUrl] : []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shortlisted Properties'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
      ),
      body: FutureBuilder<List<PropertyWithImages>>(
        future: _fetchFavouriteProperties(),
        builder: (context, snapshot) {
          if (_currentUserId == null) {
            return const Center(
              child: Text('Please log in to view your shortlisted properties.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final favouriteListings = snapshot.data;
          if (favouriteListings == null || favouriteListings.isEmpty) {
            return const Center(child: Text('You have not shortlisted any properties yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: favouriteListings.length,
            itemBuilder: (context, index) {
              final listing = favouriteListings[index];
              final imageUrl = listing.images.isNotEmpty ? listing.images[0] : null;

              // This is where we reuse the existing PropertyCardView widget
              return PropertyCardView(
                property: listing.property,
              );
            },
          );
        },
      ),
    );
  }
}
