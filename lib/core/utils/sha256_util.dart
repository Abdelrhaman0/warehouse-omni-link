import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class HashedImageItem {
  final String path;
  final String name;
  final Uint8List bytes;
  final String hash;

  const HashedImageItem({
    required this.path,
    required this.name,
    required this.bytes,
    required this.hash,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HashedImageItem &&
          runtimeType == other.runtimeType &&
          hash == other.hash;

  @override
  int get hashCode => hash.hashCode;
}

class DuplicateFilterResult {
  final List<HashedImageItem> accepted;
  final List<String> rejectedHashes;
  final int duplicateCount;

  DuplicateFilterResult({
    required this.accepted,
    required this.rejectedHashes,
  }) : duplicateCount = rejectedHashes.length;

  bool get hasDuplicates => duplicateCount > 0;
}

class Sha256Util {
  Sha256Util._();

  /// Calculate SHA-256 hash string from raw image bytes.
  static String calculateHash(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Process raw images into HashedImageItems and filter out duplicates against:
  /// 1. Locally persisted previously uploaded hashes for this order.
  /// 2. Already selected images in the current queue.
  /// 3. Duplicate images inside the newly picked batch itself.
  static DuplicateFilterResult processAndFilter({
    required List<({String path, String name, Uint8List bytes})> newPicks,
    required List<HashedImageItem> alreadySelected,
    required Set<String> persistedHashes,
  }) {
    final accepted = <HashedImageItem>[];
    final rejected = <String>[];

    // Build the set of existing known hashes
    final knownHashes = <String>{
      ...persistedHashes,
      ...alreadySelected.map((e) => e.hash),
    };

    for (final pick in newPicks) {
      final hash = calculateHash(pick.bytes);
      if (knownHashes.contains(hash)) {
        rejected.add(hash);
      } else {
        knownHashes.add(hash);
        accepted.add(
          HashedImageItem(
            path: pick.path,
            name: pick.name,
            bytes: pick.bytes,
            hash: hash,
          ),
        );
      }
    }

    return DuplicateFilterResult(
      accepted: accepted,
      rejectedHashes: rejected,
    );
  }
}
