// lib/pages/home/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:real_estate/pages/home/drawer/post_property_page.dart';
import 'package:real_estate/pages/home/profile/edit_profile_page.dart'; // Import the new page
import 'package:real_estate/widgets/handlePostPropertyAction.dart';
import 'package:real_estate/pages/home/drawer/favourite_page.dart';
import '../drawer/listings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // A helper function to create consistent list tile items
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Helper to show a simple dialog
  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final isGuest = user?.userId == 'guest_user_id';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: theme.colorScheme.onBackground,
        foregroundColor: theme.colorScheme.onSecondary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: isGuest
          ? _buildGuestProfile(context, theme)
          : _buildLoggedInProfile(context, authProvider, user, theme),
    );
  }

  Widget _buildGuestProfile(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // New profile photo placeholder for guests
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: theme.colorScheme.surface,
            child: Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Guest',
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 0),
          _buildProfileOption(
            icon: Icons.login,
            title: 'Login / Sign Up',
            onTap: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
            },
          ),
          const Divider(),
          _buildProfileOption(
            icon: Icons.home,
            title: 'Browse Properties',
            onTap: () => Navigator.of(context).pop(),
          ),
          _buildProfileOption(
            icon: Icons.star_border,
            title: 'Saved Properties',
            onTap: () {
              // Redirect guest users to login/register to save properties
              Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
            },
          ),
          const Divider(),
          _buildProfileOption(
            icon: Icons.info_outline,
            title: 'About Us',
            onTap: () {
              _showInfoDialog(context, 'About Us', 'Real Estate is a platform dedicated to helping you find your perfect home or commercial property.');
            },
          ),
          _buildProfileOption(
            icon: Icons.contact_mail_outlined,
            title: 'Contact Us',
            onTap: () {
              _showInfoDialog(context, 'Contact Us', 'Email us at: resolutevibration.xstate@gmail.com');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInProfile(BuildContext context, AuthProvider authProvider, user, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // User Info Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                // New profile photo icon, which can be edited later
                GestureDetector(
                  onTap: () {
                    _showInfoDialog(context, 'Upload Photo', 'Upload profile photo functionality coming soon!');
                  },
                  child: const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user?.firstName} ${user?.lastName}',
                        style: theme.textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Navigate to the new EditProfilePage
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfilePage()));
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          _buildProfileOption(
            icon: Icons.star,
            title: 'Shortlisted/Favourite Properties',
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const FavouritePage())
              );
            },
          ),
          _buildProfileOption(
            icon: Icons.apartment,
            title: 'Manage/Edit Your Listings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListingsPage()),
              );
            },
          ),
          _buildProfileOption(
            icon: Icons.add_home_work,
            title: 'Post a Property',
            onTap: () {
              handlePostPropertyAction(context);
            },
          ),
          const Divider(),
          _buildProfileOption(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              authProvider.logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
