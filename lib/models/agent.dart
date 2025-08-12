// lib/models/agent.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Agent {
  final String agentId;
  final String userId;
  final String licenseNumber;
  final String agencyName;

  Agent({
    required this.agentId,
    required this.userId,
    required this.licenseNumber,
    required this.agencyName,
  });

  // Factory constructor to create an Agent from a Firestore document
  factory Agent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Agent data is null");
    }
    return Agent(
      agentId: snapshot.id,
      userId: data['user_id'] as String,
      licenseNumber: data['license_number'] as String,
      agencyName: data['agency_name'] as String,
    );
  }

  // Method to convert an Agent object to a Firestore document map
  Map<String, dynamic> toFirestore() {
    return {
      "user_id": userId,
      "license_number": licenseNumber,
      "agency_name": agencyName,
    };
  }

  // A copyWith method to create a new Agent instance with updated values
  Agent copyWith({
    String? agentId,
    String? userId,
    String? licenseNumber,
    String? agencyName,
  }) {
    return Agent(
      agentId: agentId ?? this.agentId,
      userId: userId ?? this.userId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      agencyName: agencyName ?? this.agencyName,
    );
  }
}
