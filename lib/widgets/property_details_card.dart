import 'package:flutter/material.dart';
import 'package:real_estate/models/property.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/models/property_details.dart';
import 'package:real_estate/models/amenity.dart'; // Import the Amenity model

class PropertyDetailsCard extends StatelessWidget {
  final Property property;
  final VoidCallback onDelete;
  final bool isLoading;

  const PropertyDetailsCard({
    super.key,
    required this.property,
    required this.onDelete,
    this.isLoading = false,
  });

  // Fetches property details from the 'property_details' collection
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

  // Fetches the owner/agent's name from the 'users' collection
  Future<String?> _fetchOwnerOrAgentName(String ownerId) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();
      if (userSnapshot.exists) {
        final data = userSnapshot.data();
        if (data != null) {
          return '${data['first_name']} ${data['last_name']}';
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching owner/agent name: $e');
      return null;
    }
  }

  // Fetches amenities from the 'property_amenities' collection, similar to DetailedPropertyPage
  Future<List<Amenity>> _fetchAmenities(String propertyId) async {
    try {
      final propertyAmenitiesSnapshot = await FirebaseFirestore.instance
          .collection('property_amenities')
          .where('property_id', isEqualTo: propertyId)
          .get();

      final amenityIds = propertyAmenitiesSnapshot.docs.map((doc) => doc['amenity_id'] as String).toList();
      if (amenityIds.isEmpty) {
        return [];
      }

      final amenityFutures = amenityIds.map((id) => FirebaseFirestore.instance.collection('amenities').doc(id).get());
      final amenityDocs = await Future.wait(amenityFutures);

      return amenityDocs.map((doc) => Amenity.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching amenities: $e');
      return [];
    }
  }

  // Dialog to show when the card is clicked
  void _showPropertyDetailsDialog(BuildContext context) async {
    final ownerNameFuture = _fetchOwnerOrAgentName(property.ownerId);
    final propertyDetailsFuture = _fetchPropertyDetails(property.pDetailsId);
    final amenitiesFuture = _fetchAmenities(property.propertyId);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Property Details'),
            content: FutureBuilder(
              future: Future.wait([ownerNameFuture, propertyDetailsFuture, amenitiesFuture]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return const Text('An error occurred while loading details.');
                }

                final ownerName = snapshot.data?[0] as String?;
                final details = snapshot.data?[1] as PropertyDetails?;
                final amenities = snapshot.data?[2] as List<Amenity>?;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Listed by: ${ownerName ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(property?.description ?? 'No description available.', textAlign: TextAlign.justify),
                      const SizedBox(height: 16),
                      const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (amenities != null && amenities.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: amenities.map((amenity) => Chip(label: Text(amenity.amenityName))).toList(),
                        )
                      else
                        const Text('No amenities listed.'),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format the price with a currency symbol and commas
    final priceFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final formattedPrice = priceFormatter.format(property.price);

    return InkWell(
      onTap: () => _showPropertyDetailsDialog(context),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Show a loading indicator or delete button
                  isLoading
                      ? const CircularProgressIndicator()
                      : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Delete Property',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                property.locationAddress,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              // Use FutureBuilder to fetch and display property details
              FutureBuilder<PropertyDetails?>(
                future: _fetchPropertyDetails(property.pDetailsId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    final details = snapshot.data!;
                    return Row(
                      children: [
                        const Icon(Icons.bed, color: Colors.brown),
                        const SizedBox(width: 4),
                        Text('${details.bhk} BHK'),
                        const Spacer(),
                        const Icon(Icons.shower, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('${details.bathrooms} Bath'),
                        const Spacer(),
                        const Icon(Icons.square_foot, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${property.size} sqm'),
                      ],
                    );
                  }
                  // Handle case where details are not found
                  return Row(
                    children: [
                      const Icon(Icons.square_foot, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${property.size} sqm'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Only For: $formattedPrice',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
