import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/models/enums.dart';
import 'package:real_estate/models/property.dart';
import 'package:real_estate/models/property_details.dart'; // Import PropertyDetails model
import 'package:real_estate/theme/custom_colors.dart';
import 'package:real_estate/providers/city_provider.dart';
import '../../property/filtered_properties_page.dart';

class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  // Filters State
  PropertyType? _selectedPropertyType;
  String? _selectedCityId;
  final TextEditingController _locationController = TextEditingController();
  int? _selectedRooms;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  // The price range has been expanded to a factor of 50,000
  // 1,000,000 * 50,000 = 50,000,000,000
  RangeValues _priceRangeValues = const RangeValues(0, 50000000000);
  int _matchingPropertiesCount = 0;

  // City data for validation and filtering
  final Map<String, String> _cityIdToName = {};
  Timer? _debounce;
  StreamSubscription? _querySubscription;
  Map<String, PropertyDetails>? _propertyDetailsMap;

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with the new, wider range values
    _minPriceController.text = _priceRangeValues.start.round().toString();
    _maxPriceController.text = _priceRangeValues.end.round().toString();

    _minPriceController.addListener(_onPriceRangeChanged);
    _maxPriceController.addListener(_onPriceRangeChanged);
    _locationController.addListener(_onFilterChanged);

    // Initial fetch of cities and property details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cityProvider = Provider.of<CityProvider>(context, listen: false);
      if (cityProvider.cities.isEmpty) {
        cityProvider.fetchCities().then((_) {
          _populateCityMap(cityProvider);
          _fetchAndSetPropertyDetails();
        });
      } else {
        _populateCityMap(cityProvider);
        _fetchAndSetPropertyDetails();
      }
    });
  }

  void _populateCityMap(CityProvider cityProvider) {
    _cityIdToName.clear();
    for (var city in cityProvider.cities) {
      _cityIdToName[city.cityId] = city.cityName.toLowerCase();
    }
  }

  Future<void> _fetchAndSetPropertyDetails() async {
    final snapshot = await FirebaseFirestore.instance.collection('property_details').get();
    setState(() {
      _propertyDetailsMap = {
        for (final doc in snapshot.docs)
          doc.id: PropertyDetails.fromFirestore(doc)
      };
    });
    // Once details are fetched, update the count
    _updateMatchingPropertiesCount();
  }

  void _onPriceRangeChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final double minPrice = double.tryParse(_minPriceController.text) ?? 0;
      final double maxPrice = double.tryParse(_maxPriceController.text) ?? 50000000000;
      setState(() {
        _priceRangeValues = RangeValues(minPrice, maxPrice);
      });
      _updateMatchingPropertiesCount();
    });
  }

  void _onFilterChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _updateMatchingPropertiesCount();
    });
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _locationController.dispose();
    _debounce?.cancel();
    _querySubscription?.cancel();
    super.dispose();
  }

  void _updateMatchingPropertiesCount() {
    // Only proceed if property details have been fetched
    if (_propertyDetailsMap == null) {
      return;
    }

    _querySubscription?.cancel();

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('properties');

    // Apply Firestore-level filters
    if (_selectedPropertyType != null) {
      query = query.where('property_type', isEqualTo: _selectedPropertyType!.name);
    }
    if (_selectedCityId != null) {
      query = query.where('city_id', isEqualTo: _selectedCityId);
    }

    query = query
        .where('price', isGreaterThanOrEqualTo: _priceRangeValues.start)
        .where('price', isLessThanOrEqualTo: _priceRangeValues.end);

    _querySubscription = query.snapshots().listen((snapshot) {
      // Client-side filtering for location address and rooms
      final filteredDocs = snapshot.docs.where((doc) {
        final property = Property.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        final locationQuery = _locationController.text.trim().toLowerCase();

        // Location filter
        final locationMatch = locationQuery.isEmpty || property.locationAddress.toLowerCase().contains(locationQuery);

        // Rooms filter using the pre-fetched map
        final PropertyDetails? details = _propertyDetailsMap![property.pDetailsId];
        final bool roomsMatch = _selectedRooms == null || (details != null && details.bhk >= _selectedRooms!);

        return locationMatch && roomsMatch;
      }).toList();

      setState(() {
        _matchingPropertiesCount = filteredDocs.length;
      });
    });
  }

  void _onSearchPressed() {
    final selectedCityName = _selectedCityId != null ? Provider.of<CityProvider>(context, listen: false).cities.firstWhere((city) => city.cityId == _selectedCityId).cityName : null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilteredPropertiesPage(
          propertyType: _selectedPropertyType,
          cityId: _selectedCityId,
          cityName: selectedCityName,
          locationQuery: _locationController.text.trim(),
          rooms: _selectedRooms,
          minPrice: _priceRangeValues.start,
          maxPrice: _priceRangeValues.end,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cityProvider = Provider.of<CityProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Filters',
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Property type', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    // Property Type Selection
                    Wrap(
                      spacing: 8.0,
                      children: PropertyType.values.map((type) {
                        final isSelected = _selectedPropertyType == type;
                        return ChoiceChip(
                          label: Text(type.toCapitalizedString()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPropertyType = selected ? type : null;
                              _updateMatchingPropertiesCount();
                            });
                          },
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text('Location', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    // City Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      value: _selectedCityId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Any'),
                        ),
                        ...cityProvider.cities.map((city) {
                          return DropdownMenuItem<String>(
                            value: city.cityId,
                            child: Text(city.cityName),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCityId = newValue;
                        });
                        _updateMatchingPropertiesCount();
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'e.g. 123 Main St',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Rooms', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    // Rooms Selection
                    Row(
                      children: [1, 2, 3, 4].map((rooms) {
                        final isSelected = _selectedRooms == rooms;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(rooms == 4 ? '4+' : '$rooms'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedRooms = selected ? rooms : null;
                                  _updateMatchingPropertiesCount();
                                });
                              },
                              selectedColor: Theme.of(context).colorScheme.primary,
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text('Price Range', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min Price',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max Price',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                        trackHeight: 6.0,
                        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10.0),
                      ),
                      child: RangeSlider(
                        values: _priceRangeValues,
                        // The max value for the slider has also been updated
                        min: 0,
                        max: 50000000000,
                        divisions: 1000,
                        labels: RangeLabels(
                          _priceRangeValues.start.round().toString(),
                          _priceRangeValues.end.round().toString(),
                        ),
                        onChanged: (RangeValues values) {
                          setState(() {
                            _priceRangeValues = values;
                            _minPriceController.text = values.start.round().toString();
                            _maxPriceController.text = values.end.round().toString();
                          });
                          _updateMatchingPropertiesCount();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // See Results Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSearchPressed,
                child: Text('See results ($_matchingPropertiesCount)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
