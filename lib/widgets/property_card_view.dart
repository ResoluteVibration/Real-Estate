// lib/pages/home/drawer/property_view_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/theme/custom_colors.dart';
import 'package:real_estate/models/property.dart';
import 'package:real_estate/models/property_details.dart';
import 'package:real_estate/models/city.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:real_estate/pages/property/detailed_property_page.dart';

class PropertyCardView extends StatelessWidget {
  const PropertyCardView({
    super.key,
  });

  // Future to fetch the first property image URL from Firestore.
  Future<String?> _fetchPropertyImageUrl(String propertyId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('property_images')
          .where('property_id', isEqualTo: propertyId)
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['image_url'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching property image URL: $e');
      return null;
    }
  }

  // Future to fetch the property details (BHK, bathrooms, etc.)
  Future<PropertyDetails?> _fetchPropertyDetails(String pDetailsId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('property_details')
          .doc(pDetailsId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.exists) {
        return PropertyDetails.fromFirestore(snapshot);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching property details: $e');
      return null;
    }
  }

  // Future to fetch the city details
  Future<City?> _fetchCity(String cityId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cities')
          .doc(cityId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.exists) {
        return City.fromFirestore(snapshot);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching city: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyRef = FirebaseFirestore.instance.collection('properties');

    // Build the query to fetch all properties
    Query<Map<String, dynamic>> query = propertyRef.orderBy('created_at', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Placeholder card shown while data is loading
          return ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [_buildPlaceholderCard()],
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        // Convert to Property objects without any filtering
        final properties = docs
            .map((doc) => Property.fromFirestore(doc))
            .toList();

        if (properties.isEmpty) {
          // If no properties are found, show the placeholder text
          return const Center(child: Text('No properties found.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            return _buildPropertyCard(context, property);
          },
        );
      },
    );
  }

  Widget _buildPropertyCard(BuildContext context, Property property) {
    return InkWell( // Use InkWell to make the card clickable
      onTap: () {
        // Navigate to the DetailPropertyPage when the card is tapped
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetailPropertyPage(property: property),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
        color: CustomColors.cardColor,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Property Image
              FutureBuilder<String?>(
                future: _fetchPropertyImageUrl(property.propertyId),
                builder: (context, urlSnapshot) {
                  if (urlSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (urlSnapshot.hasData && urlSnapshot.data != null) {
                    return CachedNetworkImage(
                      imageUrl: urlSnapshot.data!,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.apartment, size: 80, color: Colors.grey),
                      ),
                    );
                  }
                },
              ),
              // Property Details Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CustomColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Location Address
                    FutureBuilder<City?>(
                      future: _fetchCity(property.cityId),
                      builder: (context, snapshot) {
                        String cityAndAddress = property.locationAddress;
                        if (snapshot.hasData && snapshot.data != null) {
                          cityAndAddress = '${property.locationAddress}, ${snapshot.data!.cityName}';
                        }
                        return Text(
                          cityAndAddress,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            color: CustomColors.mutedGreen,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Key Property Details (BHK, Bath, Size)
                    FutureBuilder<PropertyDetails?>(
                      future: _fetchPropertyDetails(property.pDetailsId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final details = snapshot.data!;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDetailIcon(
                                icon: Icons.king_bed_rounded,
                                label: '${details.bhk} BHK',
                                color: CustomColors.mutedGreen,
                              ),
                              _buildDetailIcon(
                                icon: Icons.bathtub_rounded,
                                label: '${details.bathrooms} Bath',
                                color: CustomColors.mutedGreen,
                              ),
                              _buildDetailIcon(
                                icon: Icons.crop_square,
                                label: '${property.size} sqft',
                                color: CustomColors.mutedGreen,
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink(); // Hide if details not available
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget to build the icon and label for property details.
  Widget _buildDetailIcon({required IconData icon, required String label, required Color color}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: color,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // A simple placeholder card to show when no data is available
  Widget _buildPlaceholderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      color: CustomColors.cardColor,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: Text(
              'Property Here',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
