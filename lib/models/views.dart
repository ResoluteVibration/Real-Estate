import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the 'views' collection (one per property).
class PropertyViews {
  final String propertyId;
  final int viewsCount;
  final int savedCount;
  final int enquiryCount;
  final Map<String, int> dailyViews;       // e.g. {"2025-08-16": 12}
  final Map<String, int> dailySaves;       // e.g. {"2025-08-16": 4}
  final Map<String, int> dailyEnquiries;   // e.g. {"2025-08-16": 2}

  PropertyViews({
    required this.propertyId,
    required this.viewsCount,
    required this.savedCount,
    required this.enquiryCount,
    required this.dailyViews,
    required this.dailySaves,
    required this.dailyEnquiries,
  });

  /// Creates a PropertyViews object from a Firestore document.
  factory PropertyViews.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return PropertyViews(
      propertyId: data?['property_id'] as String,
      viewsCount: data?['views_count'] as int? ?? 0,
      savedCount: data?['saved_count'] as int? ?? 0,
      enquiryCount: data?['enquiry_count'] as int? ?? 0,
      dailyViews: Map<String, int>.from(data?['daily_views'] ?? {}),
      dailySaves: Map<String, int>.from(data?['daily_saves'] ?? {}),
      dailyEnquiries: Map<String, int>.from(data?['daily_enquiries'] ?? {}),
    );
  }

  /// Converts a PropertyViews object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      "property_id": propertyId,
      "views_count": viewsCount,
      "saved_count": savedCount,
      "enquiry_count": enquiryCount,
      "daily_views": dailyViews,
      "daily_saves": dailySaves,
      "daily_enquiries": dailyEnquiries,
    };
  }
}
