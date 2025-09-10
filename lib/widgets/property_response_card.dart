// lib/widgets/property_response_card.dart

import 'package:flutter/material.dart';
import 'package:real_estate/models/property_with_images.dart';
import 'package:real_estate/pages/property/contact_page.dart';

class PropertyResponseCard extends StatelessWidget {
  final PropertyWithImages propertyWithImages;

  const PropertyResponseCard({Key? key, required this.propertyWithImages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final property = propertyWithImages.property;
    final firstImage = propertyWithImages.images.isNotEmpty ? propertyWithImages.images.first : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ContactPage(
              propertyId: property.propertyId,
              propertyTitle: property.title,
            ),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (firstImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    firstImage,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                property.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                property.locationAddress,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${property.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ContactPage(
                        propertyId: property.propertyId,
                        propertyTitle: property.title,
                      ),
                    ));
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Responses'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}