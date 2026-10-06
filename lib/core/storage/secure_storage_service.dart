import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for persisting sensitive authentication data securely.
/// Note: Never logs, prints, or exposes the raw auth token.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserData = 'user_data';

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Save authentication token safely
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _keyAuthToken);
  }

  /// Save authenticated admin user json
  Future<void> saveUserData(String userJson) async {
    await _storage.write(key: _keyUserData, value: userJson);
  }

  /// Get authenticated admin user json
  Future<String?> getUserData() async {
    return await _storage.read(key: _keyUserData);
  }

  /// Clear all stored auth data on logout
  Future<void> clearAuthData() async {
    await _storage.delete(key: _keyAuthToken);
    await _storage.delete(key: _keyUserData);
  }

  /// Check if user has an active token stored
  Future<bool> hasToken() async {
    final token = await _storage.read(key: _keyAuthToken);
    return token != null && token.isNotEmpty;
  }
}
