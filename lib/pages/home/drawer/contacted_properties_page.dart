import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/property_with_images.dart';
import 'package:real_estate/models/contacted.dart';
import 'package:real_estate/models/property.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:real_estate/providers/contacted_provider.dart';
import 'package:real_estate/widgets/property_card.dart';

class ContactedPropertiesPage extends StatefulWidget {
  const ContactedPropertiesPage({super.key});

  @override
  State<ContactedPropertiesPage> createState() =>
      _ContactedPropertiesPageState();
}

class _ContactedPropertiesPageState extends State<ContactedPropertiesPage> {
  // A map to hold fetched properties to avoid re-fetching
  final Map<String, Property> _propertyCache = {};
  final Map<String, String?> _imageCache = {};

  /// Fetches a property and its first image from Firestore.
  Future<PropertyWithImages?> _fetchPropertyAndImage(String propertyId) async {
    // Check if the property is already in the cache
    if (_propertyCache.containsKey(propertyId)) {
      return PropertyWithImages(
        property: _propertyCache[propertyId]!,
        images: [_imageCache[propertyId]].whereType<String>().toList(),
      );
    }

    try {
      // Fetch property document
      final propertySnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .get();
      if (!propertySnapshot.exists) return null;
      final property = Property.fromFirestore(propertySnapshot);

      // Fetch the first image URL
      final imageQuery = await FirebaseFirestore.instance
          .collection('property_images')
          .where('property_id', isEqualTo: propertyId)
          .limit(1)
          .get();

      final imageUrl = imageQuery.docs.isNotEmpty
          ? imageQuery.docs.first.get('image_url') as String?
          : null;

      // Update cache
      _propertyCache[propertyId] = property;
      _imageCache[propertyId] = imageUrl;

      return PropertyWithImages(
          property: property, images: [imageUrl].whereType<String>().toList());
    } catch (e) {
      debugPrint("Error fetching property or image for ContactedPropertiesPage: $e");
      return null;
    }
  }

  /// Fetches all properties and their images for a list of contacted items.
  Future<List<PropertyWithImages>> _fetchPropertiesForContactedList(
      List<Contacted> contactedList) async {
    final futures = contactedList
        .map((contacted) => _fetchPropertyAndImage(contacted.propertyId))
        .toList();
    final results = await Future.wait(futures);
    return results.whereType<PropertyWithImages>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId!;
    final contactedProvider = Provider.of<ContactedProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacted Properties"),
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: StreamBuilder<List<Contacted>>(
        stream: contactedProvider.getUserContacted(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No contacted properties yet."));
          }

          final contactedList = snapshot.data!;

          return FutureBuilder<List<PropertyWithImages>>(
            future: _fetchPropertiesForContactedList(contactedList),
            builder: (context, propertySnapshot) {
              if (propertySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!propertySnapshot.hasData || propertySnapshot.data!.isEmpty) {
                return const Center(child: Text("No properties found."));
              }

              final propertiesWithImages = propertySnapshot.data!;
              return _buildPropertyListView(
                  propertiesWithImages, contactedProvider, userId);
            },
          );
        },
      ),
    );
  }

  Widget _buildPropertyListView(List<PropertyWithImages> propertiesWithImages,
      ContactedProvider contactedProvider, String userId) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: propertiesWithImages.length,
      itemBuilder: (context, index) {
        final item = propertiesWithImages[index];

        return Dismissible(
          key: Key(item.property.propertyId),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete, color: Colors.white, size: 28),
          ),
          onDismissed: (direction) async {
            // Immediate UI update: Show the snackbar and handle the list
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Property removed"),
                action: SnackBarAction(
                  label: "Undo",
                  onPressed: () {
                    // Re-add the property to the list in Firestore
                    contactedProvider.addContacted(userId, item.property.propertyId);
                  },
                ),
                backgroundColor: Colors.black87,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 3),
              ),
            );

            // Now, perform the Firestore delete in the background
            try {
              await contactedProvider.removeContacted(
                  userId, item.property.propertyId);
            } catch (e) {
              // If Firestore delete fails, show a new snackbar
              debugPrint("Failed to delete property from Firestore: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to remove property.")),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: PropertyCard(
              property: item.property,
              imageUrl: item.images.isNotEmpty ? item.images.first : null,
            ),
          ),
        );
      },
    );
  }
}