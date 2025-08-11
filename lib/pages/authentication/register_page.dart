// lib/pages/authentication/register_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/enums.dart';
import '../../models/user.dart';
import '../../models/city.dart';
import '../../providers/auth_provider.dart';
import '../../providers/city_provider.dart';

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

  bool _whatsappSameAsPhone = true;
  String? _selectedCity;

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
    super.dispose();
  }

  Future<void> _handleCitySelection(BuildContext context, String? value) async {
    if (value == 'list_new_city') {
      final newCityName = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          final newCityController = TextEditingController();
          return AlertDialog(
            backgroundColor: Theme.of(dialogContext).colorScheme.surface,
            title: Text(
              'List Your City',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
            ),
            content: TextField(
              controller: newCityController,
              decoration: InputDecoration(
                hintText: "Enter new city name",
                hintStyle: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text('Cancel',
                    style: TextStyle(color: Theme.of(dialogContext).colorScheme.primary)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(newCityController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                ),
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
            _selectedCity = newCity.cityId;
          });
        }
      }
    } else {
      setState(() {
        _selectedCity = value;
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final newUser = User(
        userId: '',
        userRole: UserRole.buyer,
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
      );

      try {
        await authProvider.registerUser(newUser);
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
                decoration: const InputDecoration(hintText: 'First Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter your first name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(hintText: 'Last Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter your last name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value!.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(hintText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length < 6
                    ? 'Password must be at least 6 characters long'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
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
                  decoration: const InputDecoration(hintText: 'WhatsApp Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter your WhatsApp number' : null,
                ),
              ],
              const SizedBox(height: 16),
              Consumer<CityProvider>(
                builder: (context, cityProvider, child) {
                  if (cityProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final cities = cityProvider.cities;
                  return DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: const InputDecoration(hintText: 'City'),
                    hint: const Text('Select a city'),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'list_new_city',
                        child: Text(
                          'List Your City',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.primary,
                          ),
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
                    validator: (value) =>
                    value == null ? 'Please select a city' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
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
