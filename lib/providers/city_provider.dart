// lib/providers/city_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city.dart';

class CityProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<City> _cities = [];
  bool _isLoading = false;

  List<City> get cities => _cities;
  bool get isLoading => _isLoading;

  Future<void> fetchCities() async {
    _isLoading = true;
    notifyListeners();
    try {
      final querySnapshot = await _firestore.collection('cities').get();
      _cities = querySnapshot.docs.map((doc) => City.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching cities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<City?> addCity(String cityName) async {
    try {
      // Check if a city with the same name already exists.
      final querySnapshot = await _firestore
          .collection('cities')
          .where('city_name', isEqualTo: cityName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // City already exists, return the existing City object.
        final existingCity = City.fromFirestore(querySnapshot.docs.first);
        return existingCity;
      } else {
        // City does not exist, add a new one.
        final docRef = await _firestore.collection('cities').add({
          'city_name': cityName,
        });
        final newCity = City(cityId: docRef.id, cityName: cityName);
        _cities.add(newCity);
        notifyListeners();
        return newCity;
      }
    } catch (e) {
      debugPrint('Error adding new city: $e');
      return null;
    }
  }
}