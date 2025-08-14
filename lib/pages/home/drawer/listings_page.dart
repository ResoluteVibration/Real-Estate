// lib/pages/home/drawer/listings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:real_estate/providers/property_provider.dart';
import 'package:real_estate/widgets/listing_card.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      propertyProvider.fetchUserListings(authProvider.currentUser!.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final userListings = propertyProvider.userListings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
      ),
      body: propertyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : userListings.isEmpty
          ? const Center(child: Text('You have no listings yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: userListings.length,
        itemBuilder: (context, index) {
          final listing = userListings[index];
          return ListingCard(listing: listing);
        },
      ),
    );
  }
}
