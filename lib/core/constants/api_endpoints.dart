/// Centralized API endpoints configuration.
/// Allows environment overrides for production deployment without code changes.
class ApiEndpoints {
  ApiEndpoints._();

  /// Default base URL pointing to test environment.
  /// Can be overridden at runtime or via compile-time environment definition.
  static const String defaultBaseUrl = 'https://omni-link.net/api';

  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  /// Default language segment.
  static const String defaultLanguage = 'ar';

  /// Default number of items per page for paginated requests.
  static const int defaultPerPage = 15;

  /// Returns the base URL with language prefix: `{baseUrl}/{lang}/v1`
  static String localizedBase(String lang) => '$baseUrl/$lang/v1';

  // Auth endpoints
  static String login(String lang) => '${localizedBase(lang)}/admin/auth/login';
  static String logout(String lang) => '${localizedBase(lang)}/admin/auth/logout';
  static String me(String lang) => '${localizedBase(lang)}/admin/auth/me';

  // Warehouse orders endpoints
  static String orders(String lang) => '${localizedBase(lang)}/admin/warehouse/orders';
  static String orderDetails(String lang, dynamic id) =>
      '${localizedBase(lang)}/admin/warehouse/orders/$id';
  static String shipmentPhotos(String lang, dynamic id) =>
      '${localizedBase(lang)}/admin/warehouse/orders/$id/shipment-photos';
  static String waybillPhotos(String lang, dynamic id) =>
      '${localizedBase(lang)}/admin/warehouse/orders/$id/waybill-photos';
}
