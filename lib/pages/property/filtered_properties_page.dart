import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/models/enums.dart';
import 'package:real_estate/models/property.dart';
import 'package:real_estate/models/property_with_images.dart';
import 'package:real_estate/models/property_details.dart';
import 'package:real_estate/widgets/property_card.dart';

class FilteredPropertiesPage extends StatelessWidget {
  final PropertyType? propertyType;
  final String? cityId;
  final String? cityName;
  final String locationQuery;
  final int? rooms;
  final double minPrice;
  final double maxPrice;

  const FilteredPropertiesPage({
    super.key,
    this.propertyType,
    this.cityId,
    this.cityName,
    required this.locationQuery,
    this.rooms,
    required this.minPrice,
    required this.maxPrice,
  });

  @override
  Widget build(BuildContext context) {
    // Debug print for initial parameters
    print('FilteredPropertiesPage: Received parameters:');
    print('  - propertyType: $propertyType');
    print('  - cityId: $cityId');
    print('  - locationQuery: $locationQuery');
    print('  - rooms: $rooms');
    print('  - minPrice: $minPrice');
    print('  - maxPrice: $maxPrice');
    print('------------------------------------');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Filtered Results',
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        automaticallyImplyLeading: false, // Prevents the default back button
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, PropertyDetails>>(
          future: _fetchPropertyDetailsMap(),
          builder: (context, detailsSnapshot) {
            if (detailsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (detailsSnapshot.hasError) {
              return Center(child: Text('Error fetching property details: ${detailsSnapshot.error}'));
            }

            final propertyDetailsMap = detailsSnapshot.data ?? {};
            print('Debug: Fetched property details map with ${propertyDetailsMap.length} entries.');

            return StreamBuilder<QuerySnapshot<Property>>(
              stream: FirebaseFirestore.instance
                  .collection('properties')
                  .withConverter<Property>(
                fromFirestore: (snapshot, options) =>
                    Property.fromFirestore(snapshot),
                toFirestore: (property, options) => property.toFirestore(),
              )
                  .snapshots(),
              builder: (context, propertiesSnapshot) {
                if (propertiesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (propertiesSnapshot.hasError) {
                  print('Debug: Error from properties stream: ${propertiesSnapshot.error}');
                  return Center(child: Text('Error: ${propertiesSnapshot.error}'));
                }
                if (!propertiesSnapshot.hasData || propertiesSnapshot.data!.docs.isEmpty) {
                  print('Debug: No data or empty list from properties collection.');
                  return const Center(child: Text('No properties available.'));
                }

                final allPropertyDocs = propertiesSnapshot.data!.docs;
                print('Debug: Total properties fetched: ${allPropertyDocs.length}');

                final filteredProperties = allPropertyDocs.where((doc) {
                  final property = doc.data();

                  final bool typeMatch = propertyType == null || property.propertyType == propertyType;
                  final bool cityMatch = cityId == null || property.cityId == cityId;
                  final bool priceMatch = property.price >= minPrice && property.price <= maxPrice;
                  final bool locationMatch = locationQuery.isEmpty || property.locationAddress.toLowerCase().contains(locationQuery.toLowerCase());

                  // Now apply the rooms filter using the pre-fetched map
                  final PropertyDetails? details = propertyDetailsMap[property.pDetailsId];
                  final bool roomsMatch = rooms == null || (details != null && details.bhk >= rooms!);

                  // Debug print for each property's filter status
                  print('--- Property: ${property.propertyId} ---');
                  print('  - Type Match: $typeMatch');
                  print('  - City Match: $cityMatch');
                  print('  - Price Match: $priceMatch (Price: ${property.price})');
                  print('  - Location Match: $locationMatch (Location: ${property.locationAddress})');
                  print('  - Rooms Match: $roomsMatch (BHK: ${details?.bhk})');
                  print('  - Overall Match: ${typeMatch && cityMatch && priceMatch && locationMatch && roomsMatch}');

                  return typeMatch && cityMatch && priceMatch && locationMatch && roomsMatch;
                }).toList();

                print('Debug: Properties after filtering: ${filteredProperties.length}');

                if (filteredProperties.isEmpty) {
                  return const Center(child: Text('No properties match your filters.'));
                }

                return FutureBuilder<List<PropertyWithImages>>(
                  future: Future.wait(filteredProperties.map((doc) async {
                    final property = doc.data();

                    final imageSnapshot = await FirebaseFirestore.instance
                        .collection('property_images')
                        .where('property_id', isEqualTo: property.propertyId)
                        .get(const GetOptions(source: Source.serverAndCache));

                    final imageUrls = imageSnapshot.docs
                        .map((imgDoc) => imgDoc['image_url'] as String)
                        .toList();

                    return PropertyWithImages(
                      property: property,
                      images: imageUrls,
                    );
                  })),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (futureSnapshot.hasError) {
                      print('Debug: Error fetching images: ${futureSnapshot.error}');
                      return Center(
                          child: Text(
                              'Error fetching images: ${futureSnapshot.error}'));
                    }

                    final propertiesWithImages = futureSnapshot.data?.whereType<PropertyWithImages>().toList() ?? [];

                    if (propertiesWithImages.isEmpty) {
                      return const Center(child: Text('No properties match your rooms filter.'));
                    }

                    return ListView.builder(
                      itemCount: propertiesWithImages.length,
                      itemBuilder: (context, index) {
                        final item = propertiesWithImages[index];
                        return PropertyCard(
                          property: item.property,
                          imageUrl: item.images.isNotEmpty ? item.images.first : null,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Helper function to fetch all PropertyDetails once
  Future<Map<String, PropertyDetails>> _fetchPropertyDetailsMap() async {
    final snapshot = await FirebaseFirestore.instance.collection('property_details').get();
    return {
      for (final doc in snapshot.docs)
        doc.id: PropertyDetails.fromFirestore(doc)
    };
  }
}
