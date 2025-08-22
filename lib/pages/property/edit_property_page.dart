// lib/pages/property/edit_property_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import '../../../models/enums.dart';
import '../../../models/property.dart';
import '../../../models/amenity.dart';
import '../../../models/property_details.dart';
import '../../../models/city.dart';
import '../../../models/property_with_images.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/city_dropdown.dart'; // ✅ New import
import '../../../providers/city_provider.dart';
import '../../theme/custom_colors.dart'; // ✅ New import


class EditPropertyPage extends StatefulWidget {
  final PropertyWithImages propertyWithImages;
  const EditPropertyPage({super.key, required this.propertyWithImages});
  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}
class _EditPropertyPageState extends State<EditPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // Form field controllers and variables
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationAddressController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _readyByController = TextEditingController();
  PropertyType? _selectedPropertyType;
  ConstructionStatus? _selectedConstructionStatus;
  Furnishing? _selectedFurnishingStatus;
  bool _isNegotiable = false;
  // For PropertyDetails (BHK, Bathrooms, Balcony)
  List<PropertyDetails> _allPropertyDetails = [];
  String? _selectedPropertyDetailsId;
  // For Cities
  // List<City> _allCities = []; // ❌ Removed
  String? _selectedCityId;
  // For Amenities
  List<Amenity> _allAmenities = [];
  final List<String> _selectedAmenityIds = [];
  // For Images - Managing existing, new, and deleted images
  final List<String> _existingImageUrls = [];
  final List<String> _deletedImageUrls = [];
  final List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  // State variables for manual dropdown validation errors
  bool _propertyTypeHasError = false;
  // bool _cityHasError = false; // ❌ Removed
  bool _pDetailsHasError = false;
  bool _constructionStatusHasError = false;
  bool _furnishingHasError = false;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    _initializeFormFields();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CityProvider>(context, listen: false).fetchCities();
    });
  }

  void _initializeFormFields() {
    final property = widget.propertyWithImages.property;
    final images = widget.propertyWithImages.images;
    _titleController.text = property.title;
    _descriptionController.text = property.description ?? '';
    _locationAddressController.text = property.locationAddress;
    _sizeController.text = property.size.toString();
    _priceController.text = property.price.toString();
    _readyByController.text = property.readyBy ?? '';
    _selectedPropertyType = property.propertyType;
    _selectedConstructionStatus = property.constructionStatus;
    _selectedFurnishingStatus = property.furnishing;
    _isNegotiable = property.isNegotiable;
    _selectedCityId = property.cityId;
    _selectedPropertyDetailsId = property.pDetailsId;
    _existingImageUrls.addAll(images);

    _firestore.collection('property_amenities')
        .where('property_id', isEqualTo: property.propertyId)
        .get().then((snapshot) {
      if (mounted) {
        setState(() {
          _selectedAmenityIds.addAll(snapshot.docs.map((doc) => doc['amenity_id'] as String));
        });
      }
    });
  }

  // Fetch predefined data for dropdowns
  Future<void> _fetchDropdownData() async {
    try {
      final detailsSnapshot = await _firestore.collection('property_details').get();
      final amenitiesSnapshot = await _firestore.collection('amenities').get();
      // final citiesSnapshot = await _firestore.collection('cities').get(); // ❌ Removed
      if (mounted) {
        setState(() {
          _allPropertyDetails = detailsSnapshot.docs
              .map((doc) => PropertyDetails.fromFirestore(doc))
              .toList();
          _allAmenities = amenitiesSnapshot.docs
              .map((doc) => Amenity.fromFirestore(doc))
              .toList();
          // _allCities = citiesSnapshot.docs // ❌ Removed
          //     .map((doc) => City.fromFirestore(doc))
          //     .toList();
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to fetch dropdown data: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationAddressController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _readyByController.dispose();
    super.dispose();
  }

  // Function to pick new images from the gallery
  Future<void> _pickNewImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images);
      });
    }
  }

  // Function to remove an image
  void _removeImage(String? url, XFile? xFile) {
    setState(() {
      if (url != null) {
        _existingImageUrls.remove(url);
        _deletedImageUrls.add(url);
      }
      if (xFile != null) {
        _newImages.remove(xFile);
      }
    });
  }

  // Function to show the success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Property Updated'),
          content: const Text('Your property has been successfully updated!'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                Navigator.of(context).pop(); // Navigate back
              },
            ),
          ],
        );
      },
    );
  }

  // The main function to submit the form and save all data to Firestore
  Future<void> _submitForm() async {
    setState(() {
      _propertyTypeHasError = _selectedPropertyType == null;
      // _cityHasError = _selectedCityId == null; // ❌ Removed
      _pDetailsHasError = _selectedPropertyDetailsId == null;
      _constructionStatusHasError = _selectedConstructionStatus == null;
      _furnishingHasError = _selectedFurnishingStatus == null;
    });

    if (_formKey.currentState?.validate() ?? false &&
        !_propertyTypeHasError &&
        // !_cityHasError && // ❌ Removed
        !_pDetailsHasError &&
        !_constructionStatusHasError &&
        !_furnishingHasError) {
      if (_isUploading) return;
      setState(() {
        _isUploading = true;
      });
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      final propertyId = widget.propertyWithImages.property.propertyId;

      try {
        final oldAmenityIdsSnapshot = await _firestore
            .collection('property_amenities')
            .where('property_id', isEqualTo: propertyId)
            .get();
        final oldAmenityIds = oldAmenityIdsSnapshot.docs.map((doc) => doc['amenity_id'] as String).toList();

        final updatedProperty = Property(
          propertyId: propertyId,
          propertyType: _selectedPropertyType!,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          locationAddress: _locationAddressController.text,
          size: int.tryParse(_sizeController.text) ?? 0,
          price: double.tryParse(_priceController.text) ?? 0,
          isNegotiable: _isNegotiable,
          constructionStatus: _selectedConstructionStatus!,
          furnishing: _selectedFurnishingStatus!,
          pDetailsId: _selectedPropertyDetailsId!,
          cityId: _selectedCityId!,
          ownerId: widget.propertyWithImages.property.ownerId,
          createdAt: widget.propertyWithImages.property.createdAt,
          readyBy: _selectedConstructionStatus == ConstructionStatus.underConstruction
              ? _readyByController.text
              : null,
        );

        await propertyProvider.updateListing(
          propertyId: propertyId,
          updatedProperty: updatedProperty,
          oldAmenityIds: oldAmenityIds,
          newAmenityIds: _selectedAmenityIds,
          existingImageUrls: _existingImageUrls,
          deletedImageUrls: _deletedImageUrls,
          newImages: _newImages,
        );

        _showSuccessDialog();
      } on FirebaseException catch (e) {
        Fluttertoast.showToast(msg: 'Failed to update property (Firebase): ${e.message}');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to update property: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Property',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: CustomColors.mutedBlue),
                decoration: const InputDecoration(
                  labelText: 'Property Name',
                  hintText: 'e.g., Antilia',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the property name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Description (Optional)
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: CustomColors.mutedBlue),
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g., A detailed description...',
                ),
              ),
              const SizedBox(height: 16),
              // Location Address
              TextFormField(
                controller: _locationAddressController,
                style: TextStyle(color: CustomColors.mutedBlue),
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g., 123 Main St, New York, NY',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the location address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // ✅ City Dropdown - REPLACED
              CityDropdown(
                selectedCity: _selectedCityId,
                onCitySelected: (value) {
                  setState(() {
                    _selectedCityId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Property Type Dropdown
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Property Type',
                  border: const OutlineInputBorder(),
                  errorText: _propertyTypeHasError ? 'Please select a property type' : null,
                ),
                isEmpty: _selectedPropertyType == null,
                child: DropdownButton<PropertyType>(
                  value: _selectedPropertyType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  menuMaxHeight: 200.0,
                  items: PropertyType.values.map((type) {
                    return DropdownMenuItem<PropertyType>(
                      value: type,
                      child: Text(type.toCapitalizedString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPropertyType = value;
                      if (value != null) _propertyTypeHasError = false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Property Details Dropdown
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Bedrooms, Bathrooms, Balcony',
                  border: const OutlineInputBorder(),
                  errorText: _pDetailsHasError ? 'Please select property details' : null,
                ),
                isEmpty: _selectedPropertyDetailsId == null,
                child: DropdownButton<String>(
                  value: _selectedPropertyDetailsId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  menuMaxHeight: 200.0,
                  items: _allPropertyDetails.map((details) {
                    return DropdownMenuItem<String>(
                      value: details.pDetailsId,
                      child: Text('${details.bhk} BHK, ${details.bathrooms} Bathrooms, ${details.balconies} Balconies'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPropertyDetailsId = value;
                      if (value != null) _pDetailsHasError = false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Size
              TextFormField(
                controller: _sizeController,
                style: TextStyle(color: CustomColors.mutedBlue),
                decoration: const InputDecoration(
                  labelText: 'Size (sq ft)',
                  hintText: 'e.g., 1200',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the size';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid integer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Price
              TextFormField(
                controller: _priceController,
                style: TextStyle(color: CustomColors.mutedBlue),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: 'e.g., 500000',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Is Negotiable
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Price is Negotiable?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isNegotiable,
                    onChanged: (value) {
                      setState(() => _isNegotiable = value);
                    },
                    activeColor: colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Construction Status Dropdown
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Construction Status',
                  border: const OutlineInputBorder(),
                  errorText: _constructionStatusHasError ? 'Please select a construction status' : null,
                ),
                isEmpty: _selectedConstructionStatus == null,
                child: DropdownButton<ConstructionStatus>(
                  value: _selectedConstructionStatus,
                  isExpanded: true,
                  underline: const SizedBox(),
                  menuMaxHeight: 200.0,
                  items: ConstructionStatus.values.map((status) {
                    return DropdownMenuItem<ConstructionStatus>(
                      value: status,
                      child: Text(status.toCapitalizedString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedConstructionStatus = value;
                      if (value != null) {
                        _constructionStatusHasError = false;
                        if (value != ConstructionStatus.underConstruction) {
                          _readyByController.clear();
                        }
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Conditionally display the "Ready By" field
              if (_selectedConstructionStatus == ConstructionStatus.underConstruction)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _readyByController,
                    style: TextStyle(color: CustomColors.mutedBlue),
                    decoration: const InputDecoration(
                      labelText: 'Ready By (Optional)',
                      hintText: 'e.g., 2024-12-31',
                    ),
                  ),
                ),
              // Furnishing Dropdown
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Furnishing Status',
                  border: const OutlineInputBorder(),
                  errorText: _furnishingHasError ? 'Please select a furnishing status' : null,
                ),
                isEmpty: _selectedFurnishingStatus == null,
                child: DropdownButton<Furnishing>(
                  value: _selectedFurnishingStatus,
                  isExpanded: true,
                  underline: const SizedBox(),
                  menuMaxHeight: 200.0,
                  items: Furnishing.values.map((furnishing) {
                    return DropdownMenuItem<Furnishing>(
                      value: furnishing,
                      child: Text(furnishing.toCapitalizedString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFurnishingStatus = value;
                      if (value != null) _furnishingHasError = false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),
              // Amenities Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amenities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _allAmenities.map((amenity) {
                          return ChoiceChip(
                            label: Text(amenity.amenityName),
                            selected: _selectedAmenityIds.contains(amenity.amenityId),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAmenityIds.add(amenity.amenityId);
                                } else {
                                  _selectedAmenityIds.remove(amenity.amenityId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Image Picker Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Property Images',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickNewImages,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add New Images'),
                      ),
                      const SizedBox(height: 16),
                      if (_existingImageUrls.isNotEmpty || _newImages.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _existingImageUrls.length + _newImages.length,
                          itemBuilder: (context, index) {
                            if (index < _existingImageUrls.length) {
                              final imageUrl = _existingImageUrls[index];
                              return _buildImageWidget(
                                Image.network(imageUrl, fit: BoxFit.cover),
                                    () => _removeImage(imageUrl, null),
                              );
                            } else {
                              final newImageIndex = index - _existingImageUrls.length;
                              final imageXFile = _newImages[newImageIndex];
                              return _buildImageWidget(
                                kIsWeb
                                    ? FutureBuilder<Uint8List>(
                                  future: imageXFile.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                    } else {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                  },
                                )
                                    : Image.file(File(imageXFile.path), fit: BoxFit.cover),
                                    () => _removeImage(null, imageXFile),
                              );
                            }
                          },
                        )
                      else
                        const Text('No images selected.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Submit Button
              ElevatedButton(
                onPressed: _isUploading ? null : _submitForm,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Update Property'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(Widget image, VoidCallback onDelete) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: image,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}