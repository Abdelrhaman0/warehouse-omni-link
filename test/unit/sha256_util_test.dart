import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/core/utils/sha256_util.dart';

void main() {
  group('Sha256Util and Duplicate Image Detection', () {
    test('same bytes with different filenames are detected as duplicates', () {
      final imageBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
      final hash1 = Sha256Util.calculateHash(imageBytes);

      // Create an already selected image
      final item1 = HashedImageItem(
        path: '/path/photo.jpg',
        name: 'photo.jpg',
        bytes: imageBytes,
        hash: hash1,
      );

      // Same bytes, but different filename and path
      final newPick = (
        path: '/different/path/photo_copy(1).jpg',
        name: 'photo_copy(1).jpg',
        bytes: imageBytes,
      );

      final result = Sha256Util.processAndFilter(
        newPicks: [newPick],
        alreadySelected: [item1],
        persistedHashes: {},
      );

      expect(result.hasDuplicates, isTrue);
      expect(result.duplicateCount, 1);
      expect(result.accepted, isEmpty);
      expect(result.rejectedHashes.first, hash1);
    });

    test('different image bytes are accepted as unique', () {
      final bytesA = Uint8List.fromList([1, 2, 3]);
      final bytesB = Uint8List.fromList([4, 5, 6]);

      final itemA = HashedImageItem(
        path: '/path/image_a.jpg',
        name: 'image_a.jpg',
        bytes: bytesA,
        hash: Sha256Util.calculateHash(bytesA),
      );

      final newPickB = (
        path: '/path/image_b.jpg',
        name: 'image_b.jpg',
        bytes: bytesB,
      );

      final result = Sha256Util.processAndFilter(
        newPicks: [newPickB],
        alreadySelected: [itemA],
        persistedHashes: {},
      );

      expect(result.hasDuplicates, isFalse);
      expect(result.duplicateCount, 0);
      expect(result.accepted.length, 1);
      expect(result.accepted.first.name, 'image_b.jpg');
    });

    test('rejects images matching locally persisted hashes from prior uploads', () {
      final bytes = Uint8List.fromList([99, 88, 77]);
      final hash = Sha256Util.calculateHash(bytes);

      // Persisted hash set from previous app session
      final persistedHashes = {hash};

      final newPick = (
        path: '/gallery/new_name.jpg',
        name: 'new_name.jpg',
        bytes: bytes,
      );

      final result = Sha256Util.processAndFilter(
        newPicks: [newPick],
        alreadySelected: [],
        persistedHashes: persistedHashes,
      );

      expect(result.hasDuplicates, isTrue);
      expect(result.accepted, isEmpty);
      expect(result.rejectedHashes, contains(hash));
    });

    test('handles internal duplicates within the newly selected batch', () {
      final bytes = Uint8List.fromList([5, 10, 15]);

      final batch = [
        (path: '/cam/1.jpg', name: '1.jpg', bytes: bytes),
        (path: '/cam/2.jpg', name: '2.jpg', bytes: bytes), // Duplicate of 1
        (path: '/cam/3.jpg', name: '3.jpg', bytes: Uint8List.fromList([100, 200])),
      ];

      final result = Sha256Util.processAndFilter(
        newPicks: batch,
        alreadySelected: [],
        persistedHashes: {},
      );

      expect(result.hasDuplicates, isTrue);
      expect(result.duplicateCount, 1);
      expect(result.accepted.length, 2);
      expect(result.accepted[0].name, '1.jpg');
      expect(result.accepted[1].name, '3.jpg');
    });
  });
}
