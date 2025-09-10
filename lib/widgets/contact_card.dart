// lib/widgets/contact_card.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:real_estate/models/user.dart';
import 'package:real_estate/models/contacted.dart';

class ContactCard extends StatelessWidget {
  final Contacted contacted;

  const ContactCard({Key? key, required this.contacted}) : super(key: key);

  Future<User?> _fetchContactedUser(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return User.fromFirestore(userDoc);
      }
    } catch (e) {
      debugPrint('Error fetching contacted user: $e');
    }
    return null;
  }

  void _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _fetchContactedUser(contacted.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Failed to load contact information.'));
        }

        final user = snapshot.data!;
        final fullName = '${user.firstName} ${user.lastName}';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        user.email,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (user.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(user.phoneNumber, style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl('tel:${user.phoneNumber}'),
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                      ),
                    ],
                  ),
                ],
                if (user.whatsappNumber.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.message, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(user.whatsappNumber, style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl('https://wa.me/${user.whatsappNumber}'),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Contacted on: ${contacted.contactedAt.toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}