// lib/pages/home/profile/edit_profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/enums.dart';
import '../../../models/user.dart';
import '../../../models/agent.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/city_provider.dart';

// Extension to capitalize enum names for display
extension StringExtension on String {
  String toCapitalizedString() {
    if (isEmpty) {
      return '';
    }
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _addressController;
  late TextEditingController _licenseNumberController;
  late TextEditingController _agencyNameController;

  bool _whatsappSameAsPhone = true;
  String? _selectedCityId;
  UserRole? _selectedUserRole;
  bool _isDataInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cityProvider = Provider.of<CityProvider>(context, listen: false);

      // Fetch user profile and cities
      await authProvider.fetchUserProfile();
      await cityProvider.fetchCities();

      _initializeControllers();
    });
  }

  void _initializeControllers() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final _currentUser = authProvider.currentUser;
    final _currentAgent = authProvider.currentAgent;

    if (_currentUser != null) {
      _firstNameController = TextEditingController(text: _currentUser.firstName);
      _lastNameController = TextEditingController(text: _currentUser.lastName);
      _emailController = TextEditingController(text: _currentUser.email);
      _phoneController = TextEditingController(text: _currentUser.phoneNumber);
      _whatsappController = TextEditingController(text: _currentUser.whatsappNumber);
      _addressController = TextEditingController(text: _currentUser.address);

      _whatsappSameAsPhone = (_currentUser.phoneNumber == _currentUser.whatsappNumber);

      _selectedCityId = _currentUser.cityId;
      _selectedUserRole = _currentUser.userRole;

      if (_currentAgent != null) {
        _licenseNumberController = TextEditingController(text: _currentAgent.licenseNumber);
        _agencyNameController = TextEditingController(text: _currentAgent.agencyName);
      } else {
        _licenseNumberController = TextEditingController();
        _agencyNameController = TextEditingController();
      }

      setState(() {
        _isDataInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _agencyNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCitySelection(BuildContext context, String? value) async {
    if (value == 'list_new_city') {
      final newCityName = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          final newCityController = TextEditingController();
          return AlertDialog(
            title: const Text('List Your City'),
            content: TextField(
              controller: newCityController,
              decoration: const InputDecoration(hintText: "Enter new city name"),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(newCityController.text);
                },
                child: const Text('Add City'),
              ),
            ],
          );
        },
      );

      if (newCityName != null && newCityName.isNotEmpty) {
        final cityProvider = Provider.of<CityProvider>(context, listen: false);
        final newCity = await cityProvider.addCity(newCityName);
        if (newCity != null) {
          setState(() {
            _selectedCityId = newCity.cityId;
          });
        }
      }
    } else {
      setState(() {
        _selectedCityId = value;
      });
    }
  }

  Future<void> _handleSaveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final _currentUser = authProvider.currentUser;

      if (_currentUser == null) return;

      final updatedUser = _currentUser.copyWith(
        userRole: _selectedUserRole,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        whatsappNumber:
        _whatsappSameAsPhone ? _phoneController.text : _whatsappController.text,
        address: _addressController.text,
        cityId: _selectedCityId!,
        updatedAt: Timestamp.now(),
      );

      try {
        await authProvider.updateUserProfile(
          updatedUser: updatedUser,
          licenseNumber: _selectedUserRole == UserRole.agent
              ? _licenseNumberController.text
              : null,
          agencyName: _selectedUserRole == UserRole.agent
              ? _agencyNameController.text
              : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final _currentUser = authProvider.currentUser;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    if (authProvider.isLoading || ! _isDataInitialized || _currentUser == null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: textTheme.titleLarge!.copyWith(color: colorScheme.onPrimary),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: colorScheme.surface,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(hintText: 'First Name'),
                validator: (value) => value!.isEmpty ? 'Please enter your first name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(hintText: 'Last Name'),
                validator: (value) => value!.isEmpty ? 'Please enter your last name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email should be read-only
                style: textTheme.bodyMedium!.copyWith(color: colorScheme.onBackground.withOpacity(0.5)),
              ),
              const SizedBox(height: 16),
              // User Role Dropdown
              DropdownButtonFormField<UserRole>(
                value: _selectedUserRole,
                decoration: const InputDecoration(hintText: 'You are?'),
                style: textTheme.bodyMedium!.copyWith(color: colorScheme.onBackground),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem<UserRole>(
                    value: role,
                    child: Text(role.name.toCapitalizedString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUserRole = value!;
                  });
                },
                validator: (value) => value == null ? 'Please select your role' : null,
              ),
              const SizedBox(height: 16),
              // Conditional Agent fields
              if (_selectedUserRole == UserRole.agent) ...[
                TextFormField(
                  controller: _licenseNumberController,
                  decoration: const InputDecoration(hintText: 'License Number'),
                  validator: (value) => value!.isEmpty ? 'Please enter your license number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _agencyNameController,
                  decoration: const InputDecoration(hintText: 'Agency Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter your agency name' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(hintText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'WhatsApp same as Phone',
                      style: textTheme.bodyLarge!.copyWith(color: colorScheme.onBackground),
                    ),
                  ),
                  Switch(
                    value: _whatsappSameAsPhone,
                    onChanged: (value) {
                      setState(() {
                        _whatsappSameAsPhone = value;
                      });
                    },
                    activeColor: colorScheme.primary,
                  ),
                ],
              ),
              if (!_whatsappSameAsPhone) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _whatsappController,
                  decoration: const InputDecoration(hintText: 'WhatsApp Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Please enter your WhatsApp number' : null,
                ),
              ],
              const SizedBox(height: 16),
              Consumer<CityProvider>(
                builder: (context, cityProvider, child) {
                  if (cityProvider.isLoading) {
                    return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                  }

                  final cities = cityProvider.cities;
                  return DropdownButtonFormField<String>(
                    value: _selectedCityId,
                    style: textTheme.bodyMedium!.copyWith(color: colorScheme.onBackground),
                    decoration: const InputDecoration(hintText: 'City'),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'list_new_city',
                        child: Text(
                          'List Your City',
                          style: textTheme.bodyMedium!.copyWith(fontStyle: FontStyle.italic, color: colorScheme.primary),
                        ),
                      ),
                      ...cities.map((city) {
                        return DropdownMenuItem<String>(
                          value: city.cityId,
                          child: Text(city.cityName),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) async {
                      await _handleCitySelection(context, value);
                    },
                    validator: (value) => value == null ? 'Please select a city' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(hintText: 'Address'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Please enter your address' : null,
              ),
              const SizedBox(height: 32),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return authProvider.isLoading
                      ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                      : ElevatedButton(
                    onPressed: _handleSaveChanges,
                    child: Text('Save Changes', style: textTheme.bodyLarge),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
