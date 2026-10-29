/// Strongly typed administrator roles recognized by Omni Link Warehouse.
enum UserRole {
  storeKeeper('store_keeper'),
  superAdmin('super_admin'),
  unknown('unknown');

  final String value;
  const UserRole(this.value);

  /// Safely parse a role string from the backend into a [UserRole].
  /// Fails closed to [UserRole.unknown] for null, empty, malformed,
  /// or unrecognized values.
  static UserRole fromString(String? role) {
    if (role == null) return UserRole.unknown;
    final normalized = role.trim().toLowerCase();
    if (normalized == UserRole.storeKeeper.value) {
      return UserRole.storeKeeper;
    } else if (normalized == UserRole.superAdmin.value) {
      return UserRole.superAdmin;
    }
    return UserRole.unknown;
  }

  bool get isStoreKeeper => this == UserRole.storeKeeper;
  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isUnknown => this == UserRole.unknown;
}
