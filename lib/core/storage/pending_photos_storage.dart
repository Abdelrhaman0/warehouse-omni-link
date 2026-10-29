import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/sha256_util.dart';

/// Storage service to persist pending (un-uploaded) shipment and waybill photos locally.
/// Photos are copied to application-controlled storage so they are not purged by the OS,
/// and metadata (paths, names, hashes) is tracked per order and photo type in SharedPreferences.
class PendingPhotosStorage {
  final SharedPreferences _prefs;
  final Future<Directory> Function()? baseDirectoryResolver;

  static const String _keyPrefix = 'pending_photos_order_';

  PendingPhotosStorage(
    this._prefs, {
    this.baseDirectoryResolver,
  });

  String _getKey(int orderId, String category) => '$_keyPrefix${orderId}_$category';

  Future<Directory> _getBaseDirectory() async {
    if (baseDirectoryResolver != null) {
      return await baseDirectoryResolver!();
    }
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      // Fallback in test environments where platform channels are not mocked
      return Directory.systemTemp;
    }
  }

  Future<Directory> _getCategoryDirectory(int orderId, String category) async {
    final baseDir = await _getBaseDirectory();
    final dir = Directory('${baseDir.path}/pending_photos/$orderId/$category');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Save raw photo bytes into durable application-controlled storage and record in metadata.
  Future<HashedImageItem> saveImageFile({
    required int orderId,
    required String category,
    required String name,
    required Uint8List bytes,
    required String hash,
    String? originalPath,
  }) async {
    final categoryDir = await _getCategoryDirectory(orderId, category);
    final safeName = name.split(RegExp(r'[/\\]')).last;
    final fileName = '${hash}_$safeName';
    final targetFile = File('${categoryDir.path}/$fileName');

    // Write file to application-controlled storage
    await targetFile.writeAsBytes(bytes, flush: true);

    // Update metadata in SharedPreferences
    final key = _getKey(orderId, category);
    final existingList = _loadRawMetadata(key);

    // Remove any existing entry with the same hash to prevent duplicates
    existingList.removeWhere((item) => item['hash'] == hash);

    existingList.add({
      'path': targetFile.path,
      'name': safeName,
      'hash': hash,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    await _prefs.setString(key, jsonEncode(existingList));

    return HashedImageItem(
      path: targetFile.path,
      name: safeName,
      bytes: bytes,
      hash: hash,
    );
  }

  /// Load pending photos for an order and category from disk and metadata.
  /// Handles missing files or invalid paths gracefully by pruning dead entries.
  Future<List<HashedImageItem>> loadPendingPhotos({
    required int orderId,
    required String category,
  }) async {
    final key = _getKey(orderId, category);
    final rawList = _loadRawMetadata(key);
    if (rawList.isEmpty) return [];

    final result = <HashedImageItem>[];
    final validMetadata = <Map<String, dynamic>>[];

    for (final item in rawList) {
      final path = item['path'] as String?;
      final name = item['name'] as String? ?? 'photo.jpg';
      final hash = item['hash'] as String?;

      if (path == null || hash == null) continue;

      final file = File(path);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          result.add(HashedImageItem(
            path: path,
            name: name,
            bytes: bytes,
            hash: hash,
          ));
          validMetadata.add(item);
        } catch (_) {
          // Unreadable file: omit
        }
      }
    }

    // Synchronize metadata if any invalid/deleted files were pruned
    if (validMetadata.length != rawList.length) {
      if (validMetadata.isEmpty) {
        await _prefs.remove(key);
      } else {
        await _prefs.setString(key, jsonEncode(validMetadata));
      }
    }

    return result;
  }

  /// Remove a single photo by hash, deleting both the file and its metadata entry.
  Future<void> removePhoto({
    required int orderId,
    required String category,
    required String hash,
  }) async {
    final key = _getKey(orderId, category);
    final rawList = _loadRawMetadata(key);
    final itemToRemove = rawList.firstWhere(
      (item) => item['hash'] == hash,
      orElse: () => <String, dynamic>{},
    );

    if (itemToRemove.isNotEmpty) {
      final path = itemToRemove['path'] as String?;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }

      rawList.removeWhere((item) => item['hash'] == hash);
      if (rawList.isEmpty) {
        await _prefs.remove(key);
      } else {
        await _prefs.setString(key, jsonEncode(rawList));
      }
    }
  }

  /// Clear all pending photos for a specific category and order.
  /// Used after server confirms successful upload.
  Future<void> clearCategoryPhotos({
    required int orderId,
    required String category,
  }) async {
    final key = _getKey(orderId, category);
    final rawList = _loadRawMetadata(key);

    for (final item in rawList) {
      final path = item['path'] as String?;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
    }

    await _prefs.remove(key);

    // Try deleting the category folder if empty
    try {
      final categoryDir = await _getCategoryDirectory(orderId, category);
      if (await categoryDir.exists() && (await categoryDir.list().isEmpty)) {
        await categoryDir.delete();
      }
    } catch (_) {}
  }

  /// Clear all pending photos (shipment + waybill) for a specific order.
  Future<void> clearOrderPhotos(int orderId) async {
    await clearCategoryPhotos(orderId: orderId, category: 'shipment');
    await clearCategoryPhotos(orderId: orderId, category: 'waybill');

    try {
      final baseDir = await _getBaseDirectory();
      final orderDir = Directory('${baseDir.path}/pending_photos/$orderId');
      if (await orderDir.exists() && (await orderDir.list().isEmpty)) {
        await orderDir.delete();
      }
    } catch (_) {}
  }

  /// Quick check if an order has pending photos without reading full byte contents.
  bool hasPendingPhotos(int orderId, {String? category}) {
    if (category != null) {
      final key = _getKey(orderId, category);
      final raw = _loadRawMetadata(key);
      return raw.isNotEmpty;
    }
    return _loadRawMetadata(_getKey(orderId, 'shipment')).isNotEmpty ||
        _loadRawMetadata(_getKey(orderId, 'waybill')).isNotEmpty;
  }

  List<Map<String, dynamic>> _loadRawMetadata(String key) {
    final jsonStr = _prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return [];
  }
}
