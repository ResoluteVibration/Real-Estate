import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/models/property.dart';
import 'package:real_estate/widgets/property_details_card.dart';

class PropertyManagementPage extends StatefulWidget {
  const PropertyManagementPage({super.key});

  @override
  State<PropertyManagementPage> createState() => _PropertyManagementPageState();
}

class _PropertyManagementPageState extends State<PropertyManagementPage> {
  // Use a map to track the loading state for each property
  final Map<String, bool> _loadingStates = {};

  Future<void> _deleteProperty(String propertyId, String title) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the property "$title"? This action cannot be undone.'),
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
        _loadingStates[propertyId] = true;
      });
      try {
        await FirebaseFirestore.instance.collection('properties').doc(propertyId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Property "$title" successfully deleted!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete property: $e')),
        );
      } finally {
        setState(() {
          _loadingStates.remove(propertyId);
        });
      }
    }
  }

  // New function to handle property editing
  void _editProperty(Property property) {
    // Implement navigation to the property edit page here
    // For now, let's just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit button pressed for: ${property.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('properties').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No properties found.'));
        }

        final properties = snapshot.data!.docs
            .map((doc) => Property.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();

        return ListView.builder(
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            final bool isThisPropertyLoading = _loadingStates.containsKey(property.propertyId);

            return PropertyDetailsCard(
              property: property,
              isLoading: isThisPropertyLoading,
              onDelete: () => _deleteProperty(property.propertyId, property.title),
            );
          },
        );
      },
    );
  }
}
