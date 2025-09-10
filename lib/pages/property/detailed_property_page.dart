// lib/pages/property/detailed_property_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/models/property.dart';
import 'package:real_estate/models/property_details.dart';
import 'package:real_estate/models/favourite.dart';
import 'package:real_estate/models/amenity.dart';
import 'package:real_estate/models/enums.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:real_estate/theme/custom_colors.dart';
import 'package:real_estate/models/city.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

import '../../providers/contacted_provider.dart';

class DetailedPropertyPage extends StatefulWidget {
  final Property property;

  const DetailedPropertyPage({
    super.key,
    required this.property,
  });

  @override
  State<DetailedPropertyPage> createState() => _DetailedPropertyPageState();
}

class _DetailedPropertyPageState extends State<DetailedPropertyPage> {
  // Futures to fetch data from Firestore
  late Future<PropertyDetails?> _propertyDetailsFuture;
  late Future<List<String>> _propertyImagesFuture;
  late Future<List<Amenity>> _propertyAmenitiesFuture;
  late Future<City?> _cityFuture;
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();
    _propertyDetailsFuture = _fetchPropertyDetails(widget.property.pDetailsId);
    _propertyImagesFuture = _fetchPropertyImages(widget.property.propertyId);
    _propertyAmenitiesFuture = _fetchAmenities(widget.property.propertyId);
    _cityFuture = _fetchCity(widget.property.cityId);
    _userFuture = _fetchUser(widget.property.ownerId);
  }

  /// Fetches property details from the 'property_details' collection
  Future<PropertyDetails?> _fetchPropertyDetails(String pDetailsId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('property_details').doc(pDetailsId).get();
      return snapshot.exists ? PropertyDetails.fromFirestore(snapshot) : null;
    } catch (e) {
      debugPrint('Error fetching property details: $e');
      return null;
    }
  }

  /// Fetches property images from the 'property_images' collection
  Future<List<String>> _fetchPropertyImages(String propertyId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('property_images').where('property_id', isEqualTo: propertyId).get();
      return snapshot.docs.map((doc) => doc['image_url'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching property images: $e');
      return [];
    }
  }

  /// Fetches amenities from the 'property_amenities' collection
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

  /// Fetches the city details from the 'cities' collection
  Future<City?> _fetchCity(String cityId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('cities').doc(cityId).get();
      return snapshot.exists ? City.fromFirestore(snapshot) : null;
    } catch (e) {
      debugPrint('Error fetching city: $e');
      return null;
    }
  }

  /// Fetches the user details from the 'users' collection
  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchUser(String userId) async {
    return FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  // Function to toggle a property as a favorite
  Future<void> _toggleFavourite(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null || userId == "guest_user_id") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to shortlist properties.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final favouriteRef = FirebaseFirestore.instance.collection('favourites');
      final querySnapshot = await favouriteRef
          .where('user_id', isEqualTo: userId)
          .where('property_id', isEqualTo: widget.property.propertyId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await favouriteRef.doc(querySnapshot.docs.first.id).delete();
      } else {
        final newFavourite = Favourite(
          favouriteId: '',
          propertyId: widget.property.propertyId,
          userId: userId,
          createdAt: DateTime.now(),
        );
        await favouriteRef.add(newFavourite.toFirestore());
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update shortlist.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Displays a dialog with the property owner's contact details.
  Future<void> _showContactDialog() async {
    try {
      final userSnapshot = await _userFuture;

      if (userSnapshot == null || !userSnapshot.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Contact details not available.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final userData = userSnapshot.data()!;
      final firstName = userData['first_name'] ?? 'Owner';
      final phone = userData['phone_number'] ?? 'N/A';
      final whatsapp = userData['whatsapp_number'] ?? 'N/A';

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Contact $firstName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Phone Number:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(phone),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: phone));
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Phone number copied to clipboard!', style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.black87,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('WhatsApp Number:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(whatsapp),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: whatsapp));
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('WhatsApp number copied to clipboard!', style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.black87,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
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
    } catch (e) {
      debugPrint('Error showing contact dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred while fetching contact details.', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: CustomColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The Hero Image section, which is a Stack of widgets
            _buildHeroImageSection(),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and property details row
                  _buildPriceSection(),

                  const SizedBox(height: 16),

                  // Details section (newly moved to prevent overflow)
                  _buildDetailsSection(),

                  const SizedBox(height: 24),

                  // Description section
                  Text(
                    'About This Property',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: CustomColors.deepBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.property.description ?? 'No description provided.',
                    style: const TextStyle(fontSize: 16, color: CustomColors.mutedBlue),
                  ),

                  const SizedBox(height: 24),

                  // Construction Status Chip
                  _buildConstructionStatusChip(),

                  const SizedBox(height: 24),

                  // Amenities section
                  _buildAmenitiesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final userId = authProvider.userId;

            if (userId == null || userId == "guest_user_id") {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please log in to contact.', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }

            // ✅ Add to contacted collection and handle owner check
            try {
              final contactedProvider = Provider.of<ContactedProvider>(context, listen: false);
              final resultMessage = await contactedProvider.addContacted(userId, widget.property.propertyId);

              // Use the result message to determine the action
              if (resultMessage == null) {
                // Case 1: Success - Property was newly added to contacted list.
                // Now show the contact dialog.
                _showContactDialog();
              } else if (resultMessage == "You cannot contact your own property.") {
                // Case 2: User is the owner - Show a specific error and prevent dialog.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(resultMessage, style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (resultMessage == "Property already contacted.") {
                // Case 3: Property was already contacted - Just show the dialog without a snackbar.
                _showContactDialog();
                // The snackbar that you wanted to remove has been deleted from here.
              }
            } catch (e) {
              debugPrint("Error saving contacted property: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Failed to save contacted property.', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'For more info Contact',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the top hero image section with all the overlaid UI elements.
  Widget _buildHeroImageSection() {
    final userId = Provider.of<AuthProvider>(context).userId;

    return FutureBuilder<List<String>>(
      future: _propertyImagesFuture,
      builder: (context, snapshot) {
        final imageUrl = snapshot.data?.isNotEmpty == true ? snapshot.data!.first : null;
        return Stack(
          children: [
            // Main image with placeholder
            Container(
              height: 400,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                child: imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                    ),
                  ),
                )
                    : Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.apartment, size: 150, color: Colors.grey),
                  ),
                ),
              ),
            ),

            // Overlaid UI at the top
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                  // Favorite Button
                  if (userId != null)
                    StreamBuilder<QuerySnapshot>(
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
                            color: isFavourited ? Colors.red : Colors.white,
                          ),
                          onPressed: () => _toggleFavourite(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Overlaid title and address at the bottom
            Positioned(
              bottom: 24,
              left: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.property.title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
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
                          fontSize: 16,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the price section, including the price per sqft.
  Widget _buildPriceSection() {
    // Calculate price per sqft, handling potential division by zero
    final pricePerSqft = widget.property.size > 0
        ? (widget.property.price / widget.property.size).toStringAsFixed(2)
        : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: CustomColors.mutedBlue,
          ),
        ),
        Text(
          '₹${widget.property.price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹$pricePerSqft per sqft',
          style: const TextStyle(
            fontSize: 14,
            color: CustomColors.mutedBlue,
          ),
        ),
      ],
    );
  }

  /// Builds the property details section with icons (BHK, Bathrooms, Size).
  Widget _buildDetailsSection() {
    return FutureBuilder<PropertyDetails?>(
      future: _propertyDetailsFuture,
      builder: (context, snapshot) {
        final details = snapshot.data;
        if (details == null) {
          return const SizedBox.shrink();
        }
        return Row(
          children: [
            _buildDetailIcon(
              icon: Icons.king_bed_rounded,
              label: '${details.bhk} BHK',
            ),
            const SizedBox(width: 16),
            _buildDetailIcon(
              icon: Icons.bathtub_rounded,
              label: '${details.bathrooms} Bath',
            ),
            const SizedBox(width: 16),
            _buildDetailIcon(
              icon: Icons.balcony,
              label: '${details.bathrooms} Balcony',
            ),
            const SizedBox(width: 16),
            _buildDetailIcon(
              icon: Icons.square_foot,
              label: '${widget.property.size} sqft',
            ),
          ],
        );
      },
    );
  }

  /// Builds the amenities section with a FutureBuilder.
  Widget _buildAmenitiesSection() {
    return FutureBuilder<List<Amenity>>(
      future: _propertyAmenitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final amenities = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amenities',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: CustomColors.deepBlue,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: amenities.map((amenity) {
                return Chip(
                  label: Text(amenity.amenityName),
                  backgroundColor: CustomColors.cardColor,
                  side: const BorderSide(color: CustomColors.mutedBlue),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  /// Helper widget to build the Construction Status chip.
  Widget _buildConstructionStatusChip() {
    final constructionStatus = widget.property.constructionStatus;
    String label = '';

    if (constructionStatus != null){
      label = 'Status: ';
    };

    label = '$label ${constructionStatus.toCapitalizedString()}';


    if (constructionStatus == ConstructionStatus.underConstruction && widget.property.readyBy != null) {
      label = '$label (Ready by: ${widget.property.readyBy})';
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: CustomColors.deepBlue),
      ),
      backgroundColor: CustomColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: CustomColors.mutedBlue),
      ),
    );
  }

  /// Helper widget to build the icon and label for property details in the new layout.
  Widget _buildDetailIcon({required IconData icon, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: CustomColors.background,
          child: Icon(icon, color: CustomColors.deepBlue, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: CustomColors.mutedBlue,
          ),
        ),
      ],
    );
  }
}