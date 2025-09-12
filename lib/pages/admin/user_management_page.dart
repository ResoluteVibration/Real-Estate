import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:real_estate/models/user.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:flutter/services.dart'; // Import for Clipboard

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  // Use a map to track the loading state for each user
  final Map<String, bool> _loadingStates = {};

  Future<void> _toggleAdminStatus(BuildContext context, String userId, bool makeAdmin) async {
    setState(() {
      _loadingStates[userId] = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (makeAdmin) {
        await authProvider.makeUserAdmin(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User successfully made an admin!')),
        );
      } else {
        await authProvider.revokeUserAdmin(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User admin privileges revoked.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update admin status: $e')),
      );
    } finally {
      setState(() {
        _loadingStates.remove(userId);
      });
    }
  }

  Future<void> _deleteUser(BuildContext context, String userId, String email) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete user $email? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _loadingStates[userId] = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $email successfully deleted!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e')),
        );
      } finally {
        setState(() {
          _loadingStates.remove(userId);
        });
      }
    }
  }

  /// Displays a dialog with the user's contact details.
  Future<void> _showUserDetailsDialog(BuildContext context, User user) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact ${user.firstName} ${user.lastName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(user.email),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: user.email));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Email copied to clipboard!', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Phone Number:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(user.phoneNumber),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: user.phoneNumber));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Phone number copied to clipboard!', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('WhatsApp Number:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(user.whatsappNumber),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: user.whatsappNumber));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('WhatsApp number copied to clipboard!', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if the current user is an admin
        final bool isCurrentUserAdmin = authProvider.isAdmin;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No users found.'));
            }

            final users = snapshot.data!.docs
                .map((doc) => User.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
                .toList();

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final bool isThisUserLoading = _loadingStates.containsKey(user.userId);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    // Call the new method when the ListTile is tapped
                    onTap: () => _showUserDetailsDialog(context, user),
                    leading: const Icon(Icons.person),
                    title: Text('${user.firstName} ${user.lastName}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Removed the email from the card
                        Text('Role: ${user.userRole.name}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Display admin status icon and "make/revoke admin" button
                        if (isCurrentUserAdmin)
                          isThisUserLoading
                              ? const CircularProgressIndicator()
                              : IconButton(
                            icon: Icon(
                              user.isAdmin ? Icons.shield : Icons.shield_outlined,
                              color: Colors.blue,
                            ),
                            onPressed: () => _toggleAdminStatus(context, user.userId, !user.isAdmin),
                            tooltip: user.isAdmin ? 'Revoke Admin' : 'Make Admin',
                          ),
                        // Delete user button
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(context, user.userId, user.email),
                          tooltip: 'Delete User',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
