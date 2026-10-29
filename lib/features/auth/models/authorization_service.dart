import 'admin_user.dart';

/// Centralized authorization policy for Omni Link Warehouse RBAC.
class AuthorizationService {
  AuthorizationService._();

  /// Checks whether [user] has the valid, machine-readable role `super_admin`.
  static bool isSuperAdmin(AdminUser? user) {
    if (user == null || user.role == null) return false;
    return user.role!.trim().toLowerCase() == UserRole.superAdmin.value;
  }

  /// Checks whether [user] has the valid, machine-readable role `store_keeper`.
  static bool isStoreKeeper(AdminUser? user) {
    if (user == null || user.role == null) return false;
    return user.role!.trim().toLowerCase() == UserRole.storeKeeper.value;
  }

  /// Authorization check for Dashboard access.
  ///
  /// Policy:
  /// - super_admin: allowed.
  /// - store_keeper: denied.
  /// - missing / null / empty / malformed / unknown role: denied.
  ///
  /// CRITICAL: The dashboard rule is role-controlled and MUST NOT be overridden
  /// by any entry in the backend `permissions` array (e.g. `dashboard.view`).
  static bool canAccessDashboard(AdminUser? user) {
    return isSuperAdmin(user);
  }

  /// Checks whether [user] possesses a specific permission string from the backend.
  static bool hasPermission(AdminUser? user, String permission) {
    if (user == null) return false;
    return user.permissions.contains(permission.trim());
  }
}
