// lib/pages/home/drawer/view_responses_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_estate/providers/auth_provider.dart';
import 'package:real_estate/providers/property_provider.dart';
import 'package:real_estate/widgets/property_response_card.dart';

class ViewResponsesPage extends StatefulWidget {
  const ViewResponsesPage({Key? key}) : super(key: key);

  @override
  State<ViewResponsesPage> createState() => _ViewResponsesPageState();
}

class _ViewResponsesPageState extends State<ViewResponsesPage> {
  @override
  void initState() {
    super.initState();
    _fetchUserListings();
  }

  Future<void> _fetchUserListings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    if (authProvider.userId != null) {
      await propertyProvider.fetchUserListings(authProvider.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listing Responses',
        style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUserListings,
          ),
        ],
      ),
      body: propertyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : propertyProvider.userListings.isEmpty
          ? const Center(child: Text('You have no properties listed.'))
          : ListView.builder(
        itemCount: propertyProvider.userListings.length,
        itemBuilder: (context, index) {
          final listing = propertyProvider.userListings[index];
          return PropertyResponseCard(propertyWithImages: listing);
        },
      ),
    );
  }
}