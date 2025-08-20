import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_estate/pages/home/drawer/post_property_page.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:real_estate/utils/database_seeder.dart';
import 'package:real_estate/widgets/property_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/pages/home/profile/profile_page.dart';
import 'package:real_estate/models/enums.dart';
import 'package:real_estate/widgets/handlePostPropertyAction.dart';
import 'package:real_estate/models/property_with_images.dart';
import 'package:real_estate/models/property.dart';
import '../../providers/city_provider.dart';
import 'drawer/listings_page.dart';
import 'drawer/favourite_page.dart';
import 'package:real_estate/theme/custom_colors.dart';
import 'drawer/filters_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedDrawerItem = 'Home Page';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  // For mapping cityId → cityName
  final Map<String, String> _cityIdToName = {};

  @override
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Load city names from provider once available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cityProvider = Provider.of<CityProvider>(context, listen: false);
      if (cityProvider.cities.isEmpty) {
        cityProvider.fetchCities().then((_) {
          _populateCityMap(cityProvider);
        });
      } else {
        _populateCityMap(cityProvider);
      }
    });
  }

  void _populateCityMap(CityProvider cityProvider) {
    _cityIdToName.clear();
    for (var city in cityProvider.cities) {
      _cityIdToName[city.cityId] = city.cityName.toLowerCase();
    }
    setState(() {}); // Refresh UI with city names
  }


  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _selectDrawerItem(String item) {
    Navigator.pop(context);
    setState(() => _selectedDrawerItem = item);

    switch (item) {
      case 'Search Properties':
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => const FiltersPage()));
        break;
      case 'Shortlisted/Favourite Properties':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const FavouritePage()));
        break;
      case 'Post New Property':
        handlePostPropertyAction(context);
        break;
      case 'My Listings':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ListingsPage()));
        break;
      case 'Log Out':
        Provider.of<AuthProvider>(context, listen: false).logout();
        Navigator.pushNamedAndRemoveUntil(
            context, '/welcome', (route) => false);
        break;
      case 'Populate Amenities':
        DatabaseSeeder.seedDatabase(context);
        break;
    }
  }

  Widget buildDrawerItem({required IconData icon, required String title}) {
    final isSelected = _selectedDrawerItem == title;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => _selectDrawerItem(title),
    );
  }

  Widget _buildHomePageContent() {
    return Column(
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(30),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search properties...',
              hintStyle: TextStyle(color: CustomColors.mutedBlue.withOpacity(0.7)),
              prefixIcon: Icon(Icons.search,
                  color: Theme.of(context).colorScheme.onSurface),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: const BorderSide(color: CustomColors.mutedBlue, width: 2.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: const BorderSide(color: CustomColors.deepBlue, width: 2.0),
              ),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              filled: true,
              fillColor: CustomColors.surface,
            ),
          ),
        ),

        const SizedBox(height: 32),
        Text(
          'All Properties',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Property>>(
            stream: FirebaseFirestore.instance
                .collection('properties')
                .withConverter<Property>(
              fromFirestore: (snapshot, options) =>
                  Property.fromFirestore(snapshot),
              toFirestore: (property, options) => property.toFirestore(),
            )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No properties available.'));
              }

              final propertyDocs = snapshot.data!.docs;

              final filteredDocs = propertyDocs.where((doc) {
                final property = doc.data();
                final cityName = _cityIdToName[property.cityId] ?? '';
                if (_searchQuery.isEmpty) return true;
                return property.title.toLowerCase().contains(_searchQuery) ||
                    (property.description?.toLowerCase() ?? '')
                        .contains(_searchQuery) ||
                    property.locationAddress
                        .toLowerCase()
                        .contains(_searchQuery) ||
                    cityName.contains(_searchQuery);
              }).toList();

              return FutureBuilder<List<PropertyWithImages>>(
                future: Future.wait(filteredDocs.map((doc) async {
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
                  if (futureSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (futureSnapshot.hasError) {
                    return Center(
                        child: Text(
                            'Error fetching images: ${futureSnapshot.error}'));
                  }
                  if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                    return const Center(child: Text('No Property Matches the Search'));
                  }


                  final propertiesWithImages = futureSnapshot.data!;
                  return ListView.builder(
                    itemCount: propertiesWithImages.length,
                    itemBuilder: (context, index) {
                      final item = propertiesWithImages[index];
                      return PropertyCard(
                        property: item.property,
                        imageUrl: item.images.isNotEmpty
                            ? item.images.first
                            : null,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isGuest = user?.userId == 'guest_user_id';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          isGuest ? 'Welcome, Guest!' : 'Welcome, ${user?.firstName}!',
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        leading: IconButton(
          icon: Icon(Icons.account_circle,
              color: Theme.of(context).colorScheme.onSecondary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu,
                color: Theme.of(context).colorScheme.onSecondary),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          child: Column(
            children: [
              isGuest
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                color: Theme.of(context).colorScheme.secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondary)),
                    Text('Guest Profile',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondary)),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/welcome', (route) => false),
                      child: const Text('Login/Register Now'),
                    ),
                  ],
                ),
              )
                  : UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary),
                accountName: Text(
                    '${user?.firstName} ${user?.lastName}',
                    style: TextStyle(
                        color:
                        Theme.of(context).colorScheme.onSecondary)),
                accountEmail: Text(user?.email ?? '',
                    style: TextStyle(
                        color:
                        Theme.of(context).colorScheme.onSecondary)),
                currentAccountPicture: CircleAvatar(
                  backgroundColor:
                  Theme.of(context).colorScheme.primary,
                  child: Text(
                    user?.firstName[0] ?? 'U',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                      color:
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              buildDrawerItem(icon: Icons.home, title: 'Home Page'),
              buildDrawerItem(icon: Icons.search, title: 'Search Properties'),
              if (!isGuest) ...[
                const Divider(),
                buildDrawerItem(
                    icon: Icons.star_border,
                    title: 'Shortlisted/Favourite Properties'),
                buildDrawerItem(
                    icon: Icons.contact_phone_outlined,
                    title: 'Contacted Properties'),
                const Divider(),
                buildDrawerItem(
                    icon: Icons.post_add, title: 'Post New Property'),
                if (user?.userRole == UserRole.agent ||
                    user?.userRole == UserRole.owner) ...[
                  buildDrawerItem(
                      icon: Icons.visibility_outlined, title: 'View Responses'),
                  buildDrawerItem(icon: Icons.edit_note, title: 'My Listings'),
                ]
              ],
              if (!isGuest) ...[
                const Divider(),
                buildDrawerItem(icon: Icons.cloud_upload_outlined, title: 'Populate Amenities'),
              ],
              buildDrawerItem(icon: Icons.logout, title: 'Log Out'),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildHomePageContent(),
      ),
    );
  }
}
