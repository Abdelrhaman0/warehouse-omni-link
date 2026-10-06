class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ServerException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException({required this.message});

  @override
  String toString() => 'UnauthorizedException: $message';
}

class SessionExpiredException extends UnauthorizedException {
  SessionExpiredException({required super.message});

  @override
  String toString() => 'SessionExpiredException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}
