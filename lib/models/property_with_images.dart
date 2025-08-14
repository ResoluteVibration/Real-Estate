// lib/models/property_with_images.dart
import 'package:real_estate/models/property.dart';

/// A simple model to combine Property data with its corresponding images for UI display.
/// This avoids performing multiple Firestore queries for each item in a list.
class PropertyWithImages {
  final Property property;
  final List<String> images;

  PropertyWithImages({
    required this.property,
    required this.images,
  });
}
