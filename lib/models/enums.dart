// lib/models/enums.dart

// Represents the role of a user in the system.
enum UserRole {
  owner,
  agent,
  buyer,
}

// Represents the different types of properties.
enum PropertyType {
  apartment,
  house,
  commercial,
  land,
}

// Represents the construction status of a property.
enum ConstructionStatus {
  underConstruction,
  readyToMove,
}

// Represents the furnishing status of a property.
enum Furnishing {
  furnished,
  semiFurnished,
  unfurnished,
}

// Represents the listing status of a property.
enum ListingStatus {
  active,
  pending,
  sold,
  rented,
}

// Extension to format enum names for a user-friendly display string
extension EnumStringExtension on Enum {
  String toCapitalizedString() {
    final name = this.name;
    // Handle camelCase by splitting at uppercase letters
    final words = name.split(RegExp(r'(?=[A-Z])'));
    if (words.length > 1) {
      return words.map((word) {
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      }).join(' ');
    }
    // If not camelCase, just capitalize the first letter
    return '${name[0].toUpperCase()}${name.substring(1).toLowerCase()}';
  }
}
