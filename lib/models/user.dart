import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Model for the 'users' collection.
class User {
  final String userId;
  final UserRole userRole;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNumber;
  final String whatsappNumber;
  final String address;
  final String cityId;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? avatarUrl;
  final bool isAdmin;

  User({
    required this.userId,
    required this.userRole,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.address,
    required this.cityId,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.isAdmin = false,
  });

  User copyWith({
    String? userId,
    UserRole? userRole,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? phoneNumber,
    String? whatsappNumber,
    String? address,
    String? cityId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? avatarUrl,
    bool? isAdmin,
  }) {
    return User(
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      address: address ?? this.address,
      cityId: cityId ?? this.cityId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  // Creates a User object from a Firestore document.
  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return User(
      userId: snapshot.id,
      userRole: UserRole.values.byName(data?['user_role'] as String),
      firstName: data?['first_name'] as String,
      lastName: data?['last_name'] as String,
      email: data?['email'] as String,
      password: data?['password'] as String,
      phoneNumber: data?['phone_number'] as String,
      whatsappNumber: data?['whatsapp_number'] as String,
      address: data?['address'] as String,
      cityId: data?['city_id'] as String,
      createdAt: data?['created_at'] as Timestamp,
      updatedAt: data?['updated_at'] as Timestamp,
      avatarUrl: data?['avatar_url'] as String?,
      isAdmin: data?['isAdmin'] as bool? ?? false,
    );
  }

  // Converts a User object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      'user_role': userRole.name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'whatsapp_number': whatsappNumber,
      'address': address,
      'city_id': cityId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'avatar_url': avatarUrl,
      'isAdmin': isAdmin,
    };
  }
}
