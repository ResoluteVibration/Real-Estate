// lib/pages/property/detailed_property_page.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:real_estate/models/property.dart';
import 'package:real_estate/models/property_details.dart';
import 'package:real_estate/models/city.dart';
import 'package:real_estate/models/amenity.dart';
import 'package:real_estate/models/user.dart';
import 'package:real_estate/theme/custom_colors.dart';

class DetailPropertyPage extends StatefulWidget {
  final Property property;

  const DetailPropertyPage({super.key, required this.property});

  @override
  State<DetailPropertyPage> createState() => _DetailPropertyPageState();
}

class _DetailPropertyPageState extends State<DetailPropertyPage> {
  Future<String?> _fetchPropertyImageUrl(String propertyId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('property_images')
          .where('property_id', isEqualTo: propertyId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['image_url'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching image URL: $e');
      return null;
    }
  }

  Future<PropertyDetails?> _fetchPropertyDetails(String pDetailsId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('property_details')
          .doc(pDetailsId)
          .get();
      if (snapshot.exists) {
        return PropertyDetails.fromFirestore(snapshot);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching property details: $e');
      return null;
    }
  }

  Future<City?> _fetchCity(String cityId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cities')
          .doc(cityId)
          .get();
      if (snapshot.exists) {
        return City.fromFirestore(snapshot);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching city: $e');
      return null;
    }
  }

  Future<List<Amenity>> _fetchAmenities(String propertyId) async {
    try {
      final propertyAmenitySnapshot = await FirebaseFirestore.instance
          .collection('property_amenities')
          .where('property_id', isEqualTo: propertyId)
          .get();

      final List<String> amenityIds = propertyAmenitySnapshot.docs
          .map((doc) => doc.data()['amenity_id'] as String)
          .toList();

      if (amenityIds.isEmpty) {
        return [];
      }

      final amenitiesSnapshot = await FirebaseFirestore.instance
          .collection('amenities')
          .where(FieldPath.documentId, whereIn: amenityIds)
          .get();

      return amenitiesSnapshot.docs.map((doc) => Amenity.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching amenities: $e');
      return [];
    }
  }

  Future<User?> _fetchOwner(String ownerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
      if (snapshot.exists) {
        return User.fromFirestore(snapshot);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching owner: $e');
      return null;
    }
  }

  void _showContactDialog(User owner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Contact ${owner.firstName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildContactRow(
                context,
                Icons.phone,
                'Phone Number',
                owner.phoneNumber,
              ),
              const SizedBox(height: 16),
              _buildContactRow(
                context,
                Icons.quick_contacts_dialer_outlined,
                'WhatsApp Number',
                owner.whatsappNumber,
              ),
            ],
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

  Widget _buildContactRow(BuildContext context, IconData icon, String label, String number) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),
                const SizedBox(width: 8),
                Text(number, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.grey),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: number));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Number copied to clipboard!')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final property = widget.property;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.black),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded, color: Colors.black),
            onPressed: () {
              // TODO: Implement favorite functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String?>(
              future: _fetchPropertyImageUrl(property.propertyId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 350,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: snapshot.data!,
                        height: 350,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 350,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 350,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.apartment, size: 100, color: Colors.grey),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Open for sale',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Container(
                    height: 350,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.apartment, size: 100, color: Colors.grey),
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    property.title.isNotEmpty ? property.title : "Not Available",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: CustomColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Location
                  FutureBuilder<City?>(
                    future: _fetchCity(property.cityId),
                    builder: (context, snapshot) {
                      String locationText = property.locationAddress.isNotEmpty
                          ? property.locationAddress
                          : "Not Available";

                      if (snapshot.hasData && snapshot.data != null) {
                        locationText = "${property.locationAddress}, ${snapshot.data!.cityName}";
                      }

                      return Text(
                        locationText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: CustomColors.mutedGreen,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Price and details
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "\₹${property.price.toStringAsFixed(0)}",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: CustomColors.darkGreen,
                          ),
                        ),
                      ),
                      FutureBuilder<PropertyDetails?>(
                        future: _fetchPropertyDetails(property.pDetailsId),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final details = snapshot.data!;
                            return Row(
                              children: [
                                _buildDetailItem(context, "${details.bhk} Beds"),
                                _buildDetailItem(context, "${details.bathrooms} Bath"),
                                _buildDetailItem(context, "${property.size} m²"),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    "Overview",
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.description ?? "Not Available",
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),

                  const SizedBox(height: 24),

                  // Amenities
                  Text(
                    "Amenities",
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Amenity>>(
                    future: _fetchAmenities(property.propertyId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text(
                          "No amenities listed",
                          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                        );
                      }
                      return Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: snapshot.data!.map((amenity) {
                          return Chip(
                            label: Text(amenity.amenityName),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final owner = await _fetchOwner(property.ownerId);
                        if (owner != null) {
                          _showContactDialog(owner);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Owner details not available.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColors.darkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        "Contact Now",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildDetailItem(BuildContext context, String text) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}
