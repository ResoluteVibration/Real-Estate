// lib/pages/home/profile/edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/enums.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/city_provider.dart';
import '../../../widgets/city_dropdown.dart';
import '../../../theme/custom_colors.dart';

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

  //For Avatar
  String? _selectedAvatar;

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
    _selectedAvatar = _currentUser?.avatarUrl?.isNotEmpty == true
        ? _currentUser?.avatarUrl
        : null;

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
        avatarUrl: _selectedAvatar ?? '',
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
          // Show the success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully!',
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
      } catch (e) {
        if (mounted) {
          // Show the failure snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update profile: $e',
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
      }
    }
  }

  void _showAvatarSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 11, // total avatars you have
          itemBuilder: (context, index) {
            final avatarPath = "assets/avatars/avatar${index + 1}.png";
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatar = avatarPath;
                });
                Navigator.pop(context);
              },
              child: CircleAvatar(
                backgroundImage: AssetImage(avatarPath),
                radius: 30,
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final _currentUser = authProvider.currentUser;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final inputTextStyle = TextStyle(color: CustomColors.mutedBlue);
    final inputHintStyle = TextStyle(color: CustomColors.mutedBlue.withOpacity(0.7));

    if (authProvider.isLoading || !_isDataInitialized || _currentUser == null) {
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
                child: Stack(
                  children: [
                    Hero(
                      tag: "profile-photo",
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.surface,
                        backgroundImage: _selectedAvatar != null && _selectedAvatar!.isNotEmpty
                            ? AssetImage(_selectedAvatar!) // ✅ use saved/selected avatar
                            : null,
                        child: _selectedAvatar == null || _selectedAvatar!.isEmpty
                            ? Icon(Icons.person, size: 60, color: colorScheme.onSurface) // ✅ fallback
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () {
                          _showAvatarSelectionSheet(context);
                        },
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: colorScheme.primary,
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              TextFormField(
                controller: _firstNameController,
                style: inputTextStyle,
                decoration: InputDecoration(
                  hintText: 'First Name',
                  hintStyle: inputHintStyle,
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your first name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                style: inputTextStyle,
                decoration: InputDecoration(
                  hintText: 'Last Name',
                  hintStyle: inputHintStyle,
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your last name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: inputTextStyle.copyWith(color: inputTextStyle.color!.withOpacity(0.5)),
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: inputHintStyle,
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email is read-only
              ),
              const SizedBox(height: 16),
              // User Role Dropdown
              DropdownButtonFormField<UserRole>(
                menuMaxHeight: 100,
                value: _selectedUserRole,
                decoration: InputDecoration(
                  hintText: 'You are?',
                  hintStyle: inputHintStyle,
                ),
                style: inputTextStyle,
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
                  style: inputTextStyle,
                  decoration: InputDecoration(
                    hintText: 'License Number',
                    hintStyle: inputHintStyle,
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter your license number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _agencyNameController,
                  style: inputTextStyle,
                  decoration: InputDecoration(
                    hintText: 'Agency Name',
                    hintStyle: inputHintStyle,
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter your agency name' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _phoneController,
                style: inputTextStyle,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: inputHintStyle,
                ),
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
                  style: inputTextStyle,
                  decoration: InputDecoration(
                    hintText: 'WhatsApp Number',
                    hintStyle: inputHintStyle,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Please enter your WhatsApp number' : null,
                ),
              ],
              const SizedBox(height: 16),
              CityDropdown(
                selectedCity: _selectedCityId,
                onCitySelected: (value) {
                  setState(() {
                    _selectedCityId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                style: inputTextStyle,
                decoration: InputDecoration(
                  hintText: 'Address',
                  hintStyle: inputHintStyle,
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Please enter your address' : null,
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return authProvider.isLoading
                  ? ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const CircularProgressIndicator(),
              )
                  : ElevatedButton(
                onPressed: _handleSaveChanges,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // full width, good height
                ),
                child: Text('Save Changes', style: textTheme.bodyLarge),
              );
            },
          ),
        ),
      ),
    );
  }
}