import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_media.dart';

void main() {
  group('OrderMedia - JSON parsing & URL extraction', () {
    // Real backend response shape
    const sampleJson = {
      'id': 1177,
      'file_name': 'scaled_1000270821.jpg',
      'mime_type': 'image/jpeg',
      'size': 156933,
      'url': 'https://test.omni-link.net/storage/1177/scaled_1000270821.jpg',
      'created_at': '2026-09-14T09:23:16+00:00',
    };

    test('fromJson correctly parses all fields', () {
      final media = OrderMedia.fromJson(sampleJson);

      expect(media.id, 1177);
      expect(media.fileName, 'scaled_1000270821.jpg');
      expect(media.mimeType, 'image/jpeg');
      expect(media.size, 156933);
      expect(media.url,
          'https://test.omni-link.net/storage/1177/scaled_1000270821.jpg');
      expect(media.createdAt, isNotNull);
    });

    test('url field is exactly the full HTTPS URL — never the whole object', () {
      final media = OrderMedia.fromJson(sampleJson);

      // This is what must be passed to CachedNetworkImage / CachedNetworkImageProvider
      expect(
        media.url,
        'https://test.omni-link.net/storage/1177/scaled_1000270821.jpg',
      );

      // Confirm toString() of the object is NOT a valid URL
      // (guards against accidentally passing `media` instead of `media.url`)
      expect(media.toString(), isNot(startsWith('https://')));
    });

    test('fromJson handles missing optional createdAt gracefully', () {
      const jsonWithoutDate = {
        'id': 1,
        'file_name': 'photo.jpg',
        'mime_type': 'image/jpeg',
        'size': 1024,
        'url': 'https://example.com/photo.jpg',
      };

      final media = OrderMedia.fromJson(jsonWithoutDate);
      expect(media.createdAt, isNull);
      expect(media.url, 'https://example.com/photo.jpg');
    });

    test('parsing an empty media list returns an empty list', () {
      final List<dynamic> emptyJson = [];

      final photos = emptyJson
          .whereType<Map<String, dynamic>>()
          .map((item) => OrderMedia.fromJson(item))
          .toList();

      expect(photos, isEmpty);
    });

    test('parsing a list of two media objects extracts correct URLs', () {
      final List<dynamic> twoPhotos = [
        {
          'id': 1177,
          'file_name': 'photo1.jpg',
          'mime_type': 'image/jpeg',
          'size': 100000,
          'url': 'https://test.omni-link.net/storage/1177/photo1.jpg',
          'created_at': '2026-09-14T09:23:16+00:00',
        },
        {
          'id': 1178,
          'file_name': 'photo2.jpg',
          'mime_type': 'image/jpeg',
          'size': 200000,
          'url': 'https://test.omni-link.net/storage/1178/photo2.jpg',
          'created_at': '2026-09-14T09:25:00+00:00',
        },
      ];

      final photos = twoPhotos
          .whereType<Map<String, dynamic>>()
          .map((item) => OrderMedia.fromJson(item))
          .toList();

      expect(photos.length, 2);
      expect(photos[0].url, 'https://test.omni-link.net/storage/1177/photo1.jpg');
      expect(photos[1].url, 'https://test.omni-link.net/storage/1178/photo2.jpg');

      // URLs extracted for image widgets are valid HTTPS URLs
      final urls = photos.map((p) => p.url).toList();
      for (final url in urls) {
        expect(Uri.tryParse(url)?.scheme, 'https',
            reason: 'Each URL must be a valid https:// URI for CachedNetworkImage');
      }
    });

    test('string-like items mixed into the list are silently skipped', () {
      // Defensive: if backend returns a mix, whereType<Map> filters out non-objects
      final List<dynamic> mixed = [
        'https://some-plain-url.com/photo.jpg', // plain string — must be ignored
        {
          'id': 1177,
          'file_name': 'photo1.jpg',
          'mime_type': 'image/jpeg',
          'size': 100000,
          'url': 'https://test.omni-link.net/storage/1177/photo1.jpg',
        },
      ];

      final photos = mixed
          .whereType<Map<String, dynamic>>()
          .map((item) => OrderMedia.fromJson(item))
          .toList();

      expect(photos.length, 1);
      expect(photos[0].id, 1177);
    });
  });
}
