// lib/pages/property/contact_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_estate/models/contacted.dart';
import 'package:real_estate/widgets/contact_card.dart';

class ContactPage extends StatelessWidget {
  final String propertyId;
  final String propertyTitle;

  const ContactPage({Key? key, required this.propertyId, required this.propertyTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(propertyTitle),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contacted')
            .where('propertyId', isEqualTo: propertyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Note: The error image you provided indicates a missing index.
            // You must create the index for the query:
            // where('propertyId', isEqualTo: ...)
            // You can use the link provided in the error image:
            // https://console.firebase.google.com/v1/r/project/real-estate-c4df0/firestore/indexes?create_composite=CjNwcmlvcGVydGllcy5jb250YWN0ZWQSBHByb3BlcnR5X2lkGAEgLCAKBHVzZXJJZBgBIAuYAQ
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No responses yet.'));
          }

          final contactedDocs = snapshot.data!.docs;
          final contactedList = contactedDocs
              .map((doc) => Contacted.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: contactedList.length,
            itemBuilder: (context, index) {
              final contacted = contactedList[index];
              return ContactCard(contacted: contacted);
            },
          );
        },
      ),
    );
  }
}