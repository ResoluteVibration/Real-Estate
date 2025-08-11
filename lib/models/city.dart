import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the 'cities' collection.
class City {
  final String cityId;
  final String cityName;

  City({
    required this.cityId,
    required this.cityName,
  });

  // Creates a City object from a Firestore document.
  factory City.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return City(
      cityId: snapshot.id,
      cityName: data?['city_name'] as String,
    );
  }

  // Converts a City object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      "city_name": cityName,
    };
  }
}