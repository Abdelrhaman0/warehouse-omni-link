import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  final String id;
  final String? uuid;
  final String name;
  final String email;
  final String? phone;
  final String? status;
  final String? gender;
  final String? role;
  final String? permissions;
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
    this.permissions,
    this.avatar,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      status: json['status']?.toString(),
      gender: json['gender']?.toString(),
      role: json['role']?.toString(),
      permissions: json['permissions']?.toString(),
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
      'permissions': permissions,
      'avatar': avatar,
      'created_at': createdAt,
    };
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
        permissions,
        avatar,
        createdAt,
      ];
}
