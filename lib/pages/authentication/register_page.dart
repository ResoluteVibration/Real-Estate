import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/enums.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/city_provider.dart';
import '../../theme/custom_colors.dart';
import '../../widgets/city_dropdown.dart'; // ✅ New import

extension StringExtension on String {
  String toCapitalizedString() {
    if (isEmpty) {
      return '';
    }
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _agencyNameController = TextEditingController();

  bool _whatsappSameAsPhone = true;
  String? _selectedCity;
  UserRole _selectedUserRole = UserRole.buyer;

  // A list of default avatars for new users
  final List<String> _defaultAvatars = [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    'assets/avatars/avatar4.png',
    'assets/avatars/avatar5.png',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CityProvider>(context, listen: false).fetchCities();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _agencyNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final newUser = User(
        userId: '',
        userRole: _selectedUserRole,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text,
        whatsappNumber:
        _whatsappSameAsPhone ? _phoneController.text : _whatsappController.text,
        address: _addressController.text,
        cityId: _selectedCity!,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        // Assign a default avatar here
        avatarUrl: null,
      );

      try {
        await authProvider.registerUser(
          user: newUser,
          licenseNumber: _selectedUserRole == UserRole.agent
              ? _licenseNumberController.text
              : null,
          agencyName: _selectedUserRole == UserRole.agent
              ? _agencyNameController.text
              : null,
        );
        Navigator.of(context).pushReplacementNamed('/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Register', style: TextStyle(color: colorScheme.onPrimary)),
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
              TextFormField(
                controller: _firstNameController,
                style: TextStyle(color: CustomColors.mutedBlue),
                decoration: const InputDecoration(hintText: 'First Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter your first name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                style: TextStyle(color: CustomColors.mutedBlue),
                decoration: const InputDecoration(hintText: 'Last Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter your last name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: TextStyle(color: CustomColors.mutedBlue),
                decoration: const InputDecoration(hintText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value!.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                style: TextStyle(color: CustomColors.mutedBlue),
                decoration: const InputDecoration(hintText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length < 6
                    ? 'Password must be at least 6 characters long'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: _selectedUserRole,
                decoration: const InputDecoration(hintText: 'You are?'),
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
                validator: (value) =>
                value == null ? 'Please select your role' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedUserRole == UserRole.agent) ...[
                TextFormField(
                  controller: _licenseNumberController,
                  style: TextStyle(color: CustomColors.mutedBlue),
                  decoration: const InputDecoration(hintText: 'License Number'),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter your license number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _agencyNameController,
                  style: TextStyle(color: CustomColors.mutedBlue),
                  decoration: const InputDecoration(hintText: 'Agency Name'),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter your agency name' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _phoneController,
                style: TextStyle(color: CustomColors.mutedBlue),
                decoration: const InputDecoration(hintText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                value!.isEmpty ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'WhatsApp same as Phone',
                      style: Theme.of(context).textTheme.bodyLarge,
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
                  style: TextStyle(color: CustomColors.mutedBlue),
                  decoration: const InputDecoration(hintText: 'WhatsApp Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter your WhatsApp number' : null,
                ),
              ],
              const SizedBox(height: 16),

              // ✅ City dropdown widget
              CityDropdown(
                selectedCity: _selectedCity,
                onCitySelected: (value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                style: TextStyle(color: CustomColors.mutedBlue),
                decoration: const InputDecoration(hintText: 'Address'),
                maxLines: 3,
                validator: (value) =>
                value!.isEmpty ? 'Please enter your address' : null,
              ),
              const SizedBox(height: 32),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return authProvider.isRegistering
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _register,
                    child: const Text('Register'),
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
