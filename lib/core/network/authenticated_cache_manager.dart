import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// An HTTP client that reads the auth token from a getter and injects it.
class _AuthHttpClient extends http.BaseClient {
  _AuthHttpClient(this._getToken);

  /// Async getter that returns the current Bearer token.
  final Future<String?> Function() _getToken;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

/// A custom [CacheManager] that injects an [Authorization] header into
/// every image fetch request automatically.
///
/// **Why this is needed:**
/// [CachedNetworkImage] uses [flutter_cache_manager] under the hood,
/// which uses its own internal [http.Client] — completely separate from
/// the app DioClient. It sends NO authentication headers by default.
/// When the backend storage moved from public to protected access,
/// all images silently started failing (shown as broken-image icons).
///
/// **Usage — pass once to every [CachedNetworkImage] / [CachedNetworkImageProvider]:**
/// ```dart
/// CachedNetworkImage(
///   imageUrl: url,
///   cacheManager: AuthenticatedCacheManager.instance,
/// )
/// CachedNetworkImageProvider(url,
///   cacheManager: AuthenticatedCacheManager.instance,
/// )
/// ```
///
/// Call [AuthenticatedCacheManager.configure] once at startup (after login)
/// with the [SecureStorageService] reference.
class AuthenticatedCacheManager {
  AuthenticatedCacheManager._();

  static Future<String?> Function()? _tokenGetter;
  static CacheManager? _instance;

  /// Configure the token getter. Call this once in main() or after login.
  ///
  /// Example:
  /// ```dart
  /// AuthenticatedCacheManager.configure(() => secureStorage.getAuthToken());
  /// ```
  static void configure(Future<String?> Function() tokenGetter) {
    _tokenGetter = tokenGetter;
    // Reset instance so next access rebuilds with the new getter
    _instance = null;
  }

  /// The singleton [CacheManager] configured with auth headers.
  /// Falls back to [DefaultCacheManager] if [configure] was never called.
  static CacheManager get instance {
    if (_instance != null) return _instance!;

    if (_tokenGetter == null) {
      // Fallback — no token configured, use default (no auth headers)
      return DefaultCacheManager();
    }

    _instance = CacheManager(
      Config(
        'authenticated_images',
        fileService: HttpFileService(
          httpClient: _AuthHttpClient(_tokenGetter!),
        ),
      ),
    );
    return _instance!;
  }

  /// Call this on logout to clear the cached images and reset the manager.
  static Future<void> clearAndReset() async {
    await _instance?.emptyCache();
    _instance = null;
    _tokenGetter = null;
  }
}
