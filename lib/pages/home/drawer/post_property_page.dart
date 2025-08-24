// lib/pages/home/drawer/post_property_page.dart
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
import '../../../providers/auth_provider.dart';
import '../../../theme/custom_colors.dart';
import '../../../widgets/city_dropdown.dart';
import '../../../providers/city_provider.dart'; // ✅ New import

class PostPropertyPage extends StatefulWidget {
  const PostPropertyPage({super.key});
  @override
  State<PostPropertyPage> createState() => _PostPropertyPageState();
}

class _PostPropertyPageState extends State<PostPropertyPage> {
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
// For Images - Change the type to `XFile` for platform-independent handling
  final List<XFile> _selectedImages = [];
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CityProvider>(context, listen: false).fetchCities();
    });
  }
// Fetch predefined data for dropdowns
  Future<void> _fetchDropdownData() async {
    try {
      final detailsSnapshot = await _firestore.collection('property_details').get();
      final amenitiesSnapshot = await _firestore.collection('amenities').get();
      // final citiesSnapshot = await _firestore.collection('cities').get(); // ❌ Removed
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
// Function to pick images from the gallery
  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }
// Helper function to clear the form fields
  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _locationAddressController.clear();
    _sizeController.clear();
    _priceController.clear();
    _readyByController.clear();
    setState(() {
      _selectedPropertyType = null;
      _selectedConstructionStatus = null;
      _selectedFurnishingStatus = null;
      _isNegotiable = false;
      _selectedPropertyDetailsId = null;
      _selectedCityId = null;
      _selectedAmenityIds.clear();
      _selectedImages.clear();
      _isUploading = false;
      _propertyTypeHasError = false;
      // _cityHasError = false; // ❌ Removed
      _pDetailsHasError = false;
      _constructionStatusHasError = false;
      _furnishingHasError = false;
    });
  }
// Function to show the success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Property Posted'),
          content: const Text('Property Listed'),
          actions: [
            TextButton(
              child: const Text('Add More'),
              onPressed: () {
                _clearForm();
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                Navigator.of(context).pop(); // Navigate back to the home page
              },
            ),
          ],
        );
      },
    );
  }
// The main function to submit the form and save all data to Firestore
  Future<void> _submitForm() async {
// Manually validate dropdowns before the form
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ownerId = authProvider.currentUser?.userId;
      if (ownerId == null || ownerId == "guest_user_id") {
        Fluttertoast.showToast(msg: 'Please log in to post a property.');
        setState(() {
          _isUploading = false;
        });
        return;
      }
      try {
        final batch = _firestore.batch();
        final propertyDocRef = _firestore.collection('properties').doc();
        final propertyId = propertyDocRef.id;
        final newProperty = Property(
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
          ownerId: ownerId,
          createdAt: DateTime.now(),
          readyBy: _selectedConstructionStatus == ConstructionStatus.underConstruction
              ? _readyByController.text
              : null,
        );
        batch.set(propertyDocRef, newProperty.toFirestore());
// Save selected amenities to the 'property_amenities' collection in the batch
        if (_selectedAmenityIds.isNotEmpty) {
          for (final amenityId in _selectedAmenityIds) {
            final amenityDocRef = _firestore.collection('property_amenities').doc();
            batch.set(amenityDocRef, {
              'property_id': propertyId,
              'amenity_id': amenityId,
            });
          }
        }
        if (_selectedImages.isNotEmpty) {
          print('Starting image upload for property ID: $propertyId');
          for (final imageXFile in _selectedImages) {
            try {
              final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageXFile.name}';
              final storageRef = _storage.ref().child('properties/$propertyId/images/$fileName');
              String downloadUrl;
              if (kIsWeb) {
                final bytes = await imageXFile.readAsBytes();
                final uploadTask = storageRef.putData(bytes);
                final snapshot = await uploadTask.whenComplete(() {});
                downloadUrl = await snapshot.ref.getDownloadURL();
              } else {
                final imageFile = File(imageXFile.path);
                final uploadTask = storageRef.putFile(imageFile);
                final snapshot = await uploadTask.whenComplete(() {});
                downloadUrl = await snapshot.ref.getDownloadURL();
              }
              final imageDocRef = _firestore.collection('property_images').doc();
              batch.set(imageDocRef, {
                'property_id': propertyId,
                'image_url': downloadUrl,
                'uploaded_at': FieldValue.serverTimestamp(),
              });
              print('Successfully uploaded and added image URL to batch for: $fileName');
            } catch (e) {
              print('Error uploading image or adding to batch: $e');
              Fluttertoast.showToast(msg: 'Error uploading image: $e');
            }
          }
        }
        print('Attempting to commit Firestore batch...');
        await batch.commit();
        print('Batch committed successfully!');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Property Posted Successfully!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          // Navigate back after showing the snackbar
          Navigator.of(context).pop();
        }
      } on FirebaseException catch (e) {
        print('Firebase Exception while posting property: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to post property (Firebase): ${e.message}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        print('General Exception while posting property: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to post property: $e',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Post a New Property',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
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
                  hintText: 'Descriptions beautiful always highlights the property',
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
// City Dropdown - ✅ REPLACED
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
                      // Use the new extension method to format the string
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
                        // Clear the readyBy field if not "Under Construction"
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
                          color: CustomColors.textPrimary,
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
// Image Picker Section (Now optional)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Property Images (Optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CustomColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Images'),
                      ),
                      const SizedBox(height: 16),
                      _selectedImages.isNotEmpty
                          ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
// Display image using its path on mobile and a memory image on web
                          if (kIsWeb) {
// On web, use a FutureBuilder to asynchronously load bytes
                            return FutureBuilder<Uint8List>(
                              future: _selectedImages[index].readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                } else {
                                  return const Center(child: CircularProgressIndicator());
                                }
                              },
                            );
                          } else {
// On other platforms, use Image.file with the path
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                File(_selectedImages[index].path),
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                        },
                      )
                          : const Text('No images selected.'),
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
                    : const Text('Post Property'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}