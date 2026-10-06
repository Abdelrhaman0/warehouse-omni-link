import 'admin_user.dart';

class LoginResponse {
  final bool status;
  final String message;
  final AdminUser? admin;
  final String? token;
  final dynamic errors;

  const LoginResponse({
    required this.status,
    required this.message,
    this.admin,
    this.token,
    this.errors,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final adminJson = data?['admin'] as Map<String, dynamic>?;

    return LoginResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      admin: adminJson != null ? AdminUser.fromJson(adminJson) : null,
      token: data?['token']?.toString(),
      errors: json['errors'],
    );
  }
}
