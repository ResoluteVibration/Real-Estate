// lib/widgets/property_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/theme/custom_colors.dart';
import 'package:real_estate/models/property.dart';
import 'package:real_estate/models/property_details.dart';
import 'package:real_estate/models/city.dart';
import 'package:real_estate/models/favourite.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:real_estate/pages/property/detailed_property_page.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:real_estate/providers/views_provider.dart'; // NEW


class PropertyCard extends StatefulWidget {
  final Property property;
  final String? imageUrl;

  const PropertyCard({
    super.key,
    required this.property,
    this.imageUrl,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  // Futures to fetch details and city are still here
  Future<PropertyDetails?>? _propertyDetailsFuture;
  Future<City?>? _cityFuture;

  @override
  void initState() {
    super.initState();
    _propertyDetailsFuture = _fetchPropertyDetails(widget.property.pDetailsId);
    _cityFuture = _fetchCity(widget.property.cityId);
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

  // Function to toggle a property as a favorite
  Future<void> _toggleFavourite(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null || userId == "guest_user_id") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log in to save.')),
      );
      return;
    }

    try {
      final favouriteRef = FirebaseFirestore.instance.collection('favourites');
      //final viewsProvider = Provider.of<ViewsProvider>(context, listen: false);

      final querySnapshot = await favouriteRef
          .where('user_id', isEqualTo: userId)
          .where('property_id', isEqualTo: widget.property.propertyId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Property is already a favorite, so remove it
        await favouriteRef.doc(querySnapshot.docs.first.id).delete();
        //await viewsProvider.updateSave(widget.property.propertyId, false); // decrement saved_count
      } else {
        // Property is not a favorite, so add it
        final newFavourite = Favourite(
          favouriteId: '', // Firestore will generate the ID
          propertyId: widget.property.propertyId,
          userId: userId,
          createdAt: DateTime.now(),
        );
        await favouriteRef.add(newFavourite.toFirestore());
        //await viewsProvider.updateSave(widget.property.propertyId, true); // increment saved_count
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update shortlist.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthProvider>(context).userId;

    return InkWell(
      onTap: () {//<-async
        //final authProvider = Provider.of<AuthProvider>(context, listen: false);
        //final userId = authProvider.userId ?? "guest_user_id";

        // Prevent self-views (owner shouldn't increment)
        //if (userId != widget.property.ownerId) {
          //await Provider.of<ViewsProvider>(context, listen: false)
         //     .incrementView(widget.property.propertyId, userId);
        //}

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetailedPropertyPage(property: widget.property),
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.imageUrl != null
                        ? CachedNetworkImage(
                      imageUrl: widget.imageUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        width: 120,
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey,
                        child: const Center(
                          // Icon for when an image fails to load
                          child: Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                        ),
                      ),
                    )
                        : Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Center(
                        // Icon for when there is no image available for the property
                        child: Icon(Icons.apartment, size: 80, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Property Details Section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title
                          Text(
                            widget.property.title,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: CustomColors.deepBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          // Location Address with City
                          FutureBuilder<City?>(
                            future: _cityFuture,
                            builder: (context, snapshot) {
                              String cityAndAddress = widget.property.locationAddress;
                              if (snapshot.hasData && snapshot.data != null) {
                                cityAndAddress = '${widget.property.locationAddress}, ${snapshot.data!.cityName}';
                              }
                              return Text(
                                cityAndAddress,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: CustomColors.mutedBlue,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          // Key Property Details (BHK, Bath, Size)
                          FutureBuilder<PropertyDetails?>(
                            future: _propertyDetailsFuture,
                            builder: (context, snapshot) {
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
                                    const SizedBox(width: 16),
                                    _buildDetailIcon(
                                      icon: Icons.square_foot,
                                      label: '${widget.property.size} sqft',
                                      color: CustomColors.mutedBlue,
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink(); // Hide if details not available
                            },
                          ),
                          const SizedBox(height: 8),
                          // Price
                          Text(
                            ' Only For: ₹${widget.property.price}',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          _buildDetailIcon(
                            icon: Icons.handshake_outlined,
                            label: widget.property.isNegotiable ? 'Negotiable': 'Not Negotiable',
                            color: CustomColors.mutedBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Favorite Button in the corner
            if (userId != null)
              Positioned(
                top: 4,
                right: 4,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('favourites')
                      .where('user_id', isEqualTo: userId)
                      .where('property_id', isEqualTo: widget.property.propertyId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final isFavourited = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    return IconButton(
                      icon: Icon(
                        isFavourited ? Icons.favorite : Icons.favorite_border,
                        color: isFavourited ? Colors.red : Colors.grey[700],
                        size: 24,
                      ),
                      onPressed: () => _toggleFavourite(context),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
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
}
