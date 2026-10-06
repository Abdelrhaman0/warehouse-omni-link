import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that formats and logs every outgoing HTTP request,
/// incoming response, and error to the console for clear analysis.
///
/// Features:
/// - Pretty-prints JSON bodies for both requests and responses.
/// - Handles [FormData] uploads gracefully (fields and attached files).
/// - Measures and displays request execution duration (in milliseconds).
/// - Prints visual box borders and status indicators (🟢 🟡 🔴) to easily
///   distinguish concurrent or sequential network calls.
/// - Chunks long lines to prevent Flutter console / logcat truncation.
/// - Active only in debug mode (`kDebugMode`), zero overhead in release.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({
    this.logRequest = true,
    this.logRequestHeaders = true,
    this.logRequestBody = true,
    this.logResponseHeaders = false,
    this.logResponseBody = true,
    this.logError = true,
    this.compact = false,
  });

  final bool logRequest;
  final bool logRequestHeaders;
  final bool logRequestBody;
  final bool logResponseHeaders;
  final bool logResponseBody;
  final bool logError;
  final bool compact;

  static const String _startTimeKey = '_logging_start_time';
  static const int _maxLineLength = 800;
  static const String _lineDivider =
      '──────────────────────────────────────────────────────────────────────────────';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode && logRequest) {
      options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;
      _printRequest(options);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _printResponse(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode && logError) {
      _printError(err);
    }
    handler.next(err);
  }

  // ─── Request Logging ────────────────────────────────────────────────────────

  void _printRequest(RequestOptions options) {
    final buffer = StringBuffer();
    buffer.writeln('┌$_lineDivider');
    buffer.writeln('│ 🚀 [HTTP REQUEST] ${options.method.toUpperCase()} ${options.uri}');
    buffer.writeln('├$_lineDivider');

    // Headers
    if (logRequestHeaders && options.headers.isNotEmpty) {
      buffer.writeln('│ 📋 Headers:');
      options.headers.forEach((key, value) {
        buffer.writeln('│    $key: $value');
      });
    }

    // Query parameters
    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('│ 🔍 Query Parameters:');
      options.queryParameters.forEach((key, value) {
        buffer.writeln('│    $key: $value');
      });
    }

    // Request Body
    if (logRequestBody && options.data != null) {
      buffer.writeln('│ 📦 Body:');
      final formattedBody = _formatData(options.data);
      for (final line in formattedBody.split('\n')) {
        buffer.writeln('│    $line');
      }
    }

    buffer.write('└$_lineDivider');
    _safePrint(buffer.toString());
  }

  // ─── Response Logging ───────────────────────────────────────────────────────

  void _printResponse(Response response) {
    final duration = _calculateDuration(response.requestOptions);
    final statusCode = response.statusCode ?? 0;
    final statusMsg = response.statusMessage ?? '';
    final emoji = _statusEmoji(statusCode);

    final buffer = StringBuffer();
    buffer.writeln('┌$_lineDivider');
    buffer.writeln('│ $emoji [HTTP RESPONSE] $statusCode $statusMsg  ⏱️ $duration');
    buffer.writeln('│ 🔗 ${response.requestOptions.method.toUpperCase()} ${response.requestOptions.uri}');
    buffer.writeln('├$_lineDivider');

    // Response Headers (optional)
    if (logResponseHeaders && response.headers.map.isNotEmpty) {
      buffer.writeln('│ 📋 Response Headers:');
      response.headers.map.forEach((key, values) {
        buffer.writeln('│    $key: ${values.join(', ')}');
      });
    }

    // Response Body
    if (logResponseBody) {
      buffer.writeln('│ 📦 Response Body:');
      if (response.data == null) {
        buffer.writeln('│    (empty body)');
      } else {
        final formattedBody = _formatData(response.data);
        for (final line in formattedBody.split('\n')) {
          buffer.writeln('│    $line');
        }
      }
    }

    buffer.write('└$_lineDivider');
    _safePrint(buffer.toString());
  }

  // ─── Error Logging ──────────────────────────────────────────────────────────

  void _printError(DioException err) {
    final duration = _calculateDuration(err.requestOptions);
    final statusCode = err.response?.statusCode;
    final statusLabel = statusCode != null ? '$statusCode ' : '';

    final buffer = StringBuffer();
    buffer.writeln('┌$_lineDivider');
    buffer.writeln('│ ❌ [HTTP ERROR] $statusLabel[${err.type.name}]  ⏱️ $duration');
    buffer.writeln('│ 🔗 ${err.requestOptions.method.toUpperCase()} ${err.requestOptions.uri}');
    buffer.writeln('├$_lineDivider');

    if (err.message != null && err.message!.isNotEmpty) {
      buffer.writeln('│ ⚠️ Error Message: ${err.message}');
    }

    if (err.response?.data != null) {
      buffer.writeln('│ 📦 Server Error Body:');
      final formattedBody = _formatData(err.response!.data);
      for (final line in formattedBody.split('\n')) {
        buffer.writeln('│    $line');
      }
    }

    buffer.write('└$_lineDivider');
    _safePrint(buffer.toString());
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _calculateDuration(RequestOptions options) {
    final startTime = options.extra[_startTimeKey] as int?;
    if (startTime == null) return 'N/A';
    final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
    return '${elapsed}ms';
  }

  String _statusEmoji(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return '🟢';
    if (statusCode >= 300 && statusCode < 400) return '🟡';
    if (statusCode >= 400 && statusCode < 500) return '🟠';
    return '🔴';
  }

  String _formatData(dynamic data) {
    if (data == null) return 'null';

    if (data is FormData) {
      final fields = data.fields.map((f) => '${f.key}: ${f.value}').toList();
      final files = data.files
          .map((f) => '${f.key}: ${f.value.filename ?? "file"} (${f.value.length} bytes)')
          .toList();
      return 'FormData(\n  Fields: $fields,\n  Files: $files\n)';
    }

    if (data is Map || data is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(data);
      } catch (_) {
        return data.toString();
      }
    }

    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return const JsonEncoder.withIndent(' ').convert(decoded);
      } catch (_) {
        return data;
      }
    }

    return data.toString();
  }

  /// Prints text safely without truncation by breaking lines longer
  /// than [_maxLineLength] into readable chunks.
  void _safePrint(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.length <= _maxLineLength) {
        // ignore: avoid_print
        print(line);
      } else {
        for (int i = 0; i < line.length; i += _maxLineLength) {
          final end = (i + _maxLineLength < line.length)
              ? i + _maxLineLength
              : line.length;
          // ignore: avoid_print
          print(line.substring(i, end));
        }
      }
    }
  }
}
