// lib/pages/authentication/change_password_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_estate/providers/auth_provider.dart';

import '../../theme/custom_colors.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Regex validation function
  String? _validatePassword(String? value, {bool isConfirm = false}) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    // For confirm field
    if (isConfirm && value != _newPasswordController.text) {
      return 'Passwords do not match';
    }

    // Strong password regex
    final regex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{6,}$');
    if (!regex.hasMatch(value)) {
      return 'Must be 6+ chars, include upper, lower, number & special char';
    }
    return null;
  }

  Future<void> _handleChangePassword(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_formKey.currentState?.validate() ?? false) {
      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;

      // Verify current password
      final isCorrect = await authProvider.verifyPassword(currentPassword);
      if (!isCorrect) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your current password is incorrect')),
        );
        return;
      }

      // Prevent same password
      if (currentPassword == newPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New password cannot be same as the current password')),
        );
        return;
      }

      try {
        await authProvider.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update password: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: theme.colorScheme.onBackground,
        foregroundColor: theme.colorScheme.onSecondary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                style: TextStyle(color: CustomColors.mutedBlue),
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: "Current Password",
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscureCurrent = !_obscureCurrent);
                    },
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your current password' : null,
              ),
              const SizedBox(height: 16),

              // New Password
              TextFormField(
                controller: _newPasswordController,
                style: TextStyle(color: CustomColors.mutedBlue),
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: "New Password",
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscureNew = !_obscureNew);
                    },
                  ),
                ),
                validator: (value) => _validatePassword(value),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                style: TextStyle(color: CustomColors.mutedBlue),
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: "Confirm New Password",
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                ),
                validator: (value) => _validatePassword(value, isConfirm: true),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () => _handleChangePassword(context),
                child: const Text("Update Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

