// lib/pages/home/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:real_estate/pages/home/drawer/favourite_page.dart';
import 'package:real_estate/pages/home/profile/edit_profile_page.dart';
import 'package:real_estate/widgets/handlePostPropertyAction.dart';
import 'package:real_estate/pages/authentication/change_password_page.dart';
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
          // Guest Profile Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: theme.colorScheme.surface,
            child: Center(
              child: Column(
                children: [
                  Hero(
                    tag: "guest-profile-photo",
                    child: const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 50),
                    ),
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
              Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
            },
          ),
          const Divider(),
          _buildProfileOption(
            icon: Icons.info_outline,
            title: 'About Us',
            onTap: () {
              _showStaticDialog(context, 'About Us',
                  'Real Estate is a platform dedicated to helping you find your perfect home or commercial property.');
            },
          ),
          _buildProfileOption(
            icon: Icons.contact_mail_outlined,
            title: 'Contact Us',
            onTap: () {
              _showStaticDialog(context, 'Contact Us',
                  'Email us at: resolutevibration.xstate@gmail.com');
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
                // Expandable Profile Photo
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (context, _, __) {
                          return GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              color: Colors.black.withOpacity(0.8),
                              alignment: Alignment.center,
                              child: Hero(
                                tag: "profile-photo",
                                child: CircleAvatar(
                                  radius: 120,
                                  backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                      ? AssetImage(user.avatarUrl!)
                                      : null,
                                  child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 100)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: Hero(
                    tag: "profile-photo",
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? AssetImage(user.avatarUrl!)
                          : null,
                      child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const EditProfilePage()),
                    );
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
                  MaterialPageRoute(builder: (context) => const FavouritePage()));
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
            icon: Icons.password_outlined,
            title: 'Change Password',
            onTap: () {
              Navigator.push(
                context, MaterialPageRoute(builder: (context) => const ChangePasswordPage())
              );
            },
          ),
          _buildProfileOption(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              authProvider.logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/welcome', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  // Simple reusable info dialog for static content
  void _showStaticDialog(BuildContext context, String title, String content) {
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
}
