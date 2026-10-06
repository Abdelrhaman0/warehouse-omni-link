import 'package:shared_preferences/shared_preferences.dart';

/// Storage service to persist uploaded image SHA-256 hashes locally per order.
/// Ensures duplicate prevention survives application restarts.
class MediaHashStorage {
  final SharedPreferences _prefs;

  static const String _keyPrefix = 'uploaded_hashes_order_';

  MediaHashStorage(this._prefs);

  /// Load existing uploaded hashes for a specific order.
  Set<String> getUploadedHashes(dynamic orderId) {
    final key = '$_keyPrefix$orderId';
    final list = _prefs.getStringList(key) ?? [];
    return list.toSet();
  }

  /// Add new successfully uploaded hashes for a specific order.
  Future<void> addUploadedHashes(dynamic orderId, Iterable<String> newHashes) async {
    final key = '$_keyPrefix$orderId';
    final existing = getUploadedHashes(orderId);
    existing.addAll(newHashes);
    await _prefs.setStringList(key, existing.toList());
  }

  /// Clear hashes for an order if ever needed.
  Future<void> clearOrderHashes(dynamic orderId) async {
    final key = '$_keyPrefix$orderId';
    await _prefs.remove(key);
  }
}
