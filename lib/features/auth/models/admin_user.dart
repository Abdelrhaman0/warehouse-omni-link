import 'package:equatable/equatable.dart';

import 'authorization_service.dart';
import 'user_role.dart';

export 'authorization_service.dart';
export 'user_role.dart';

class AdminUser extends Equatable {
  final String id;
  final String? uuid;
  final String name;
  final String email;
  final String? phone;
  final String? status;
  final String? gender;
  final String? role;
  final String? roleName;
  final List<String> permissions;
  final String? avatar;
  final String? createdAt;

  const AdminUser({
    required this.id,
    this.uuid,
    required this.name,
    required this.email,
    this.phone,
    this.status,
    this.gender,
    this.role,
    this.roleName,
    this.permissions = const [],
    this.avatar,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    List<String> parsedPermissions = const [];
    final rawPermissions = json['permissions'];
    if (rawPermissions is List) {
      parsedPermissions = rawPermissions
          .where((p) => p != null)
          .map((p) => p.toString().trim())
          .where((p) => p.isNotEmpty)
          .toList(growable: false);
    } else if (rawPermissions is String && rawPermissions.trim().isNotEmpty) {
      parsedPermissions = [rawPermissions.trim()];
    }

    return AdminUser(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      status: json['status']?.toString(),
      gender: json['gender']?.toString(),
      role: json['role']?.toString().trim(),
      roleName: (json['role_name'] ?? json['roleName'])?.toString().trim(),
      permissions: parsedPermissions,
      avatar: json['avatar']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
      'gender': gender,
      'role': role,
      'role_name': roleName,
      'permissions': permissions,
      'avatar': avatar,
      'created_at': createdAt,
    };
  }

  /// Typed role evaluation
  UserRole get userRole => UserRole.fromString(role);

  /// Helper getter for super admin check
  bool get isSuperAdmin => AuthorizationService.isSuperAdmin(this);

  /// Helper getter for store keeper check
  bool get isStoreKeeper => AuthorizationService.isStoreKeeper(this);

  /// Helper getter for dashboard access check
  bool get canAccessDashboard => AuthorizationService.canAccessDashboard(this);

  /// Reusable permission check
  bool hasPermission(String permission) =>
      AuthorizationService.hasPermission(this, permission);

  /// Human-friendly role display label, preferring backend `roleName`
  String get roleDisplay {
    if (roleName != null && roleName!.isNotEmpty) {
      return roleName!;
    }
    if (isSuperAdmin) return 'مدير عام';
    if (isStoreKeeper) return 'أمين المستودع';
    return role ?? '';
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    name,
    email,
    phone,
    status,
    gender,
    role,
    roleName,
    permissions,
    avatar,
    createdAt,
  ];
}
