// lib/widgets/handlePostPropertyAction.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_estate/pages/home/drawer/post_property_page.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:real_estate/models/enums.dart';

/// Shows a dialog to update the user's role and navigates to the PostPropertyPage.
Future<void> handlePostPropertyAction(BuildContext context) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final user = authProvider.currentUser;

  // If the user is already an agent or owner, navigate directly.
  if (user?.userRole == UserRole.agent || user?.userRole == UserRole.owner) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostPropertyPage()),
    );
    return;
  }

  // Show a dialog to prompt the user to select a role.
  showDialog(
    context: context,
    builder: (context) {
      UserRole? selectedRole;
      final licenseController = TextEditingController();
      final agencyNameController = TextEditingController();

      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Want to post properties?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('You are?'),
                  const SizedBox(height: 16),
                  DropdownButton<UserRole>(
                    isExpanded: true,
                    value: selectedRole,
                    hint: const Text('Select Role'),
                    items: [UserRole.agent, UserRole.owner]
                        .map((UserRole value) => DropdownMenuItem<UserRole>(
                      value: value,
                      child: Text(value.toCapitalizedString()),
                    ))
                        .toList(),
                    onChanged: (UserRole? newValue) {
                      setModalState(() {
                        selectedRole = newValue;
                      });
                    },
                  ),
                  if (selectedRole == UserRole.agent) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: licenseController,
                      decoration: const InputDecoration(
                        labelText: 'License Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: agencyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Agency Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedRole != null) {
                    await authProvider.updateUserRole(
                      selectedRole!.name,
                      licenseNumber: licenseController.text,
                      agencyName: agencyNameController.text,
                    );
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PostPropertyPage()),
                    );
                  }
                },
                child: const Text('Proceed'),
              ),
            ],
          );
        },
      );
    },
  );
}
