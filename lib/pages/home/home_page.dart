// lib/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_estate/pages/home/drawer/post_property_page.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:real_estate/utils/database_seeder.dart';
import 'package:real_estate/widgets/property_card_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/theme/custom_colors.dart';
import 'package:real_estate/models/city.dart';
import 'package:real_estate/pages/home/profile/profile_page.dart';
import 'package:real_estate/models/enums.dart';
import 'package:real_estate/widgets/handlePostPropertyAction.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _animation;

  String _selectedDrawerItem = 'Home Page';
  final TextEditingController _searchController = TextEditingController();

  // Filter state
  double _minPrice = 0;
  double _maxPrice = 5000000;
  double _currentPrice = 5000000;
  PropertyType? _selectedType; // Changed to use PropertyType enum
  String? _selectedCityId;
  final Set<String> _selectedAmenities = {};
  List<String> _allAmenities = [];
  List<City> _allCities = [];

  Future<void> _fetchFilterData() async {
    try {
      final amenitiesSnapshot = await FirebaseFirestore.instance.collection('amenities').get();
      final citiesSnapshot = await FirebaseFirestore.instance.collection('cities').get();
      if (mounted) {
        setState(() {
          _allAmenities = amenitiesSnapshot.docs
              .map((doc) => doc['amenity_name'] as String)
              .toList();
          _allCities = citiesSnapshot.docs
              .map((doc) => City.fromFirestore(doc))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch filter data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _fetchFilterData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }


  void _selectDrawerItem(String item) {
    Navigator.pop(context);
    if (mounted) {
      setState(() {
        _selectedDrawerItem = item;
      });
    }

    switch (item) {
      case 'Post New Property':
        handlePostPropertyAction(context);
        break;
      case 'Populate Amenities':
        DatabaseSeeder.seedDatabase(context);
        break;
      case 'Log Out':
        Provider.of<AuthProvider>(context, listen: false).logout();
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
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

  void _openFilterDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Filter Properties', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 24),

                      // Price Slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Max Price: ₹${_currentPrice.toInt()}'),
                          Slider(
                            value: _currentPrice,
                            min: _minPrice,
                            max: _maxPrice,
                            divisions: 100,
                            label: _currentPrice.toStringAsFixed(0),
                            onChanged: (value) {
                              setModalState(() => _currentPrice = value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Property Type
                      Wrap(
                        spacing: 8,
                        children: PropertyType.values.map((type) { // Changed to use PropertyType enum
                          final selected = _selectedType == type;
                          return ChoiceChip(
                            label: Text(type.toCapitalizedString()),
                            selected: selected,
                            onSelected: (val) {
                              setModalState(() {
                                _selectedType = val ? type : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // City Dropdown
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                        isEmpty: _selectedCityId == null,
                        child: DropdownButton<String>(
                          value: _selectedCityId,
                          isExpanded: true,
                          underline: const SizedBox(),
                          menuMaxHeight: 200.0,
                          items: _allCities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city.cityId,
                              child: Text(city.cityName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              _selectedCityId = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amenities
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _allAmenities.map((amenity) {
                          final selected = _selectedAmenities.contains(amenity);
                          return FilterChip(
                            label: Text(amenity),
                            selected: selected,
                            onSelected: (val) {
                              setModalState(() {
                                if (val) {
                                  _selectedAmenities.add(amenity);
                                } else {
                                  _selectedAmenities.remove(amenity);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Find with Filters'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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
          icon: Icon(Icons.account_circle, color: Theme.of(context).colorScheme.onSecondary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSecondary),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondary)),
                    Text('Guest Profile',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondary)),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil('/welcome', (route) => false),
                      child: const Text('Login/Register Now'),
                    ),
                  ],
                ),
              )
                  : UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary),
                accountName: Text('${user?.firstName} ${user?.lastName}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary)),
                accountEmail: Text(user?.email ?? '',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary)),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user?.firstName[0] ?? 'U',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              buildDrawerItem(icon: Icons.home, title: 'Home Page'),
              buildDrawerItem(icon: Icons.search, title: 'Search Properties'),
              if (!isGuest) ...[
                const Divider(),
                buildDrawerItem(icon: Icons.star_border, title: 'Shortlisted/Favourite Properties'),
                buildDrawerItem(icon: Icons.contact_phone_outlined, title: 'Contacted Properties'),
                const Divider(),
                buildDrawerItem(icon: Icons.post_add, title: 'Post New Property'),
                if (user?.userRole == UserRole.agent || user?.userRole == UserRole.owner) ...[
                  buildDrawerItem(icon: Icons.visibility_outlined, title: 'View Responses'),
                  buildDrawerItem(icon: Icons.edit_note, title: 'My Listings'),
                ]
              ],
              const Divider(),
              buildDrawerItem(icon: Icons.apartment, title: 'Residential Properties'),
              buildDrawerItem(icon: Icons.business, title: 'Commercial Properties'),
              if (!isGuest) ...[
                const Divider(),
                buildDrawerItem(icon: Icons.cloud_upload_outlined, title: 'Populate Amenities'),
                buildDrawerItem(icon: Icons.logout, title: 'Log Out'),
              ],

            ],
          ),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search properties...',
                  prefixIcon: Icon(Icons.search,
                      color: Theme.of(context).colorScheme.onSurface),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.filter_list,
                        color: Theme.of(context).colorScheme.onSurface),
                    onPressed: _openFilterDrawer,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
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
            PropertyCardView(),
          ],
        ),
      ),
    );
  }
}
