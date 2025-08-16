// lib/widgets/listing_card.dart
import 'package:flutter/material.dart';
import 'package:real_estate/models/property_with_images.dart';
import 'package:provider/provider.dart';
import 'package:real_estate/providers/property_provider.dart';
import 'package:real_estate/theme/custom_colors.dart';
import 'package:real_estate/models/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/models/property_details.dart';
import 'package:real_estate/models/city.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:real_estate/pages/property/edit_property_page.dart';

class ListingCard extends StatelessWidget {
  final PropertyWithImages listing;

  const ListingCard({super.key, required this.listing});

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await Provider.of<PropertyProvider>(context, listen: false).deleteListing(listing.property.propertyId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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

  /// Helper widget to build the icon and label for property details.
  Widget _buildDetailIcon({required IconData icon, required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: color,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = listing.property;
    final imageUrl = listing.images.isNotEmpty
        ? listing.images[0]
        : 'https://placehold.co/200x200/E5E7EB/4B5563?text=No+Image';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          debugPrint('Tapped on card for property ID: ${property.propertyId}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Property Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: CustomColors.textPrimary
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        // Action buttons
                        Row(
                          children: [
                            IconButton(
                              iconSize: 20,
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // Navigate to the edit property page
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditPropertyPage(
                                      propertyWithImages: listing,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              iconSize: 20,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location
                    FutureBuilder<City?>(
                      future: _fetchCity(property.cityId),
                      builder: (context, snapshot) {
                        String cityAndAddress = property.locationAddress;
                        if (snapshot.hasData && snapshot.data != null) {
                          cityAndAddress = '${property.locationAddress}, ${snapshot.data!.cityName}';
                        }
                        return Text(
                          cityAndAddress,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: CustomColors.mutedBlue),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Bed, Bath, Sqft and Balconies
                    FutureBuilder<PropertyDetails?>(
                      future: _fetchPropertyDetails(property.pDetailsId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Text('Error fetching details', style: TextStyle(color: Colors.red));
                        }

                        if (snapshot.hasData && snapshot.data != null) {
                          final details = snapshot.data!;
                          return Row(
                            children: [
                              _buildDetailIcon(
                                icon: Icons.king_bed_rounded,
                                label: '${details.bhk}',
                                color: CustomColors.mutedBlue,
                              ),
                              const SizedBox(width: 16),
                              _buildDetailIcon(
                                icon: Icons.bathtub_rounded,
                                label: '${details.bathrooms}',
                                color: CustomColors.mutedBlue,
                              ),
                              if (details.balconies != null && details.balconies! > 0) ...[
                                const SizedBox(width: 16),
                                _buildDetailIcon(
                                  icon: Icons.balcony,
                                  label: '${details.balconies}',
                                  color: CustomColors.mutedBlue,
                                ),
                              ],
                              const SizedBox(width: 16),
                              _buildDetailIcon(
                                icon: Icons.crop_square,
                                label: '${property.size} sqft',
                                color: CustomColors.mutedBlue,
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 8),

                    // Price
                    Text(
                      'Available for: ₹${property.price}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
}
