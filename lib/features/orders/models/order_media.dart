import 'package:equatable/equatable.dart';

/// Represents a media object returned by the backend for order photos.
/// The backend returns objects like:
/// ```json
/// {
///   "id": 1177,
///   "file_name": "scaled_1000270821.jpg",
///   "mime_type": "image/jpeg",
///   "size": 156933,
///   "url": "https://test.omni-link.net/storage/1177/scaled_1000270821.jpg",
///   "created_at": "2026-09-14T09:23:16+00:00"
/// }
/// ```
/// Always use [url] when passing to image widgets — never toString() this object.
class OrderMedia extends Equatable {
  final int id;
  final String fileName;
  final String mimeType;
  final int size;
  final String url;
  final DateTime? createdAt;

  const OrderMedia({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.url,
    this.createdAt,
  });

  factory OrderMedia.fromJson(Map<String, dynamic> json) {
    return OrderMedia(
      id: _parseInt(json['id']),
      fileName: json['file_name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      size: _parseInt(json['size']),
      url: json['url']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => [id, fileName, mimeType, size, url, createdAt];
}
