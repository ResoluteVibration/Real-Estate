import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the 'agents' collection.
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

  // Creates an Agent object from a Firestore document.
  factory Agent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Agent(
      agentId: snapshot.id,
      userId: data?['user_id'] as String,
      licenseNumber: data?['license_number'] as String,
      agencyName: data?['agency_name'] as String,
    );
  }

  // Converts an Agent object to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      "user_id": userId,
      "license_number": licenseNumber,
      "agency_name": agencyName,
    };
  }
}
