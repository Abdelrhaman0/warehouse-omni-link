import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/storage/secure_storage_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String url;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final SecureStorageService _storageService = SecureStorageService();

  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _documentBytes;
  bool _isImage = false;

  @override
  void initState() {
    super.initState();
    _fetchDocument();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<void> _fetchDocument() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _documentBytes = null;
      _isImage = false;
    });

    String? token;
    try {
      token = await _storageService.getAuthToken();
      final uri = Uri.parse(widget.url.trim());

      final headers = <String, String>{
        'Accept': 'application/pdf, image/*, application/json, */*',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile)',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final client = http.Client();
      http.Response response;
      final redirectHistory = <Map<String, dynamic>>[];
      var currentUri = uri;
      const maxRedirects = 5;

      debugPrint('[PDF_DIAGNOSTIC] Requested URL: $uri');

      try {
        while (true) {
          final request = http.Request('GET', currentUri);
          request.headers.addAll(headers);
          request.followRedirects = false;
          request.maxRedirects = maxRedirects;

          final streamedResponse = await client.send(request);
          final res = await http.Response.fromStream(streamedResponse);

          final isRedirectStatus = res.statusCode == 301 ||
              res.statusCode == 302 ||
              res.statusCode == 303 ||
              res.statusCode == 307 ||
              res.statusCode == 308;

          final locationHeader = res.headers['location'];

          if (isRedirectStatus &&
              locationHeader != null &&
              redirectHistory.length < maxRedirects) {
            final nextUri = currentUri.resolve(locationHeader);
            redirectHistory.add({
              'status': res.statusCode,
              'from': currentUri.toString(),
              'to': nextUri.toString(),
            });
            debugPrint('[PDF_DIAGNOSTIC] Redirect #${redirectHistory.length}:');
            debugPrint('  Status: ${res.statusCode}');
            debugPrint('  From: $currentUri');
            debugPrint('  To: $nextUri');

            currentUri = nextUri;
            continue;
          }

          response = res;
          break;
        }
      } finally {
        client.close();
      }

      final bytes = response.bodyBytes;
      final contentType = response.headers['content-type'] ?? 'unknown';
      final contentLength = response.contentLength ??
          (response.headers['content-length'] != null
              ? int.tryParse(response.headers['content-length']!)
              : null);

      final hexBytes = bytes
          .take(16)
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');

      // Magic bytes check for PDF (%PDF)
      final isPdf = bytes.length >= 4 &&
          bytes[0] == 0x25 && // %
          bytes[1] == 0x50 && // P
          bytes[2] == 0x44 && // D
          bytes[3] == 0x46;   // F

      // Check if the server sent an image instead (JPEG, PNG, etc.)
      final isJpeg = bytes.length >= 3 &&
          bytes[0] == 0xFF &&
          bytes[1] == 0xD8 &&
          bytes[2] == 0xFF;
      final isPng = bytes.length >= 4 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47;

      final ctLower = contentType.toLowerCase();
      final sampleLength = bytes.length < 64 ? bytes.length : 64;
      final sampleString = sampleLength > 0
          ? utf8
              .decode(bytes.sublist(0, sampleLength), allowMalformed: true)
              .trimLeft()
              .toLowerCase()
          : '';
      final isHtml = ctLower.contains('text/html') ||
          sampleString.startsWith('<!doctype') ||
          sampleString.startsWith('<html');

      debugPrint('[PDF_DIAGNOSTIC] Status: ${response.statusCode}');
      debugPrint('[PDF_DIAGNOSTIC] Final URL: $currentUri');
      debugPrint('[PDF_DIAGNOSTIC] Redirected: ${redirectHistory.isNotEmpty}');
      if (redirectHistory.isEmpty) {
        debugPrint('[PDF_DIAGNOSTIC] Redirect history: None');
      }
      debugPrint('[PDF_DIAGNOSTIC] Content-Type: $contentType');
      debugPrint('[PDF_DIAGNOSTIC] Content-Length: ${contentLength ?? 'unknown'}');
      debugPrint('[PDF_DIAGNOSTIC] Body bytes: ${bytes.length}');
      debugPrint('[PDF_DIAGNOSTIC] First bytes HEX: $hexBytes');
      debugPrint('[PDF_DIAGNOSTIC] PDF: $isPdf');
      debugPrint('[PDF_DIAGNOSTIC] JPEG: $isJpeg');
      debugPrint('[PDF_DIAGNOSTIC] PNG: $isPng');
      debugPrint('[PDF_DIAGNOSTIC] HTML: $isHtml');

      try {
        final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: true));
        if (decoded is Map && decoded.containsKey('message')) {
          final msg = decoded['message']?.toString() ?? '';
          final truncatedMsg =
              msg.length > 200 ? '${msg.substring(0, 200)}...' : msg;
          debugPrint('[PDF_DIAGNOSTIC] JSON message: $truncatedMsg');
        }
      } catch (_) {
        // Not JSON, ignore
      }

      if (response.statusCode == 200) {
        if (bytes.isEmpty) {
          throw Exception('الملف المستلم فارغ من الخادم');
        }

        final isImage = isJpeg || isPng || ctLower.startsWith('image/');

        if (isPdf) {
          if (mounted) {
            setState(() {
              _documentBytes = bytes;
              _isImage = false;
              _isLoading = false;
            });
          }
        } else if (isImage) {
          if (mounted) {
            setState(() {
              _documentBytes = bytes;
              _isImage = true;
              _isLoading = false;
            });
          }
        } else {
          // If not PDF and not image, it may be an API JSON error or HTML error
          String errorText = 'الملف غير صالح أو ليس بتنسيق PDF';
          try {
            final jsonMap = jsonDecode(response.body);
            if (jsonMap is Map && jsonMap['message'] != null) {
              errorText = jsonMap['message'].toString();
            }
          } catch (_) {
            if (response.body.length < 200 && !response.body.contains('<html')) {
              errorText = response.body;
            }
          }
          throw Exception(errorText);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('غير مصرح بالوصول إلى هذا الملف (${response.statusCode}). يرجى التحقق من الصلاحيات.');
      } else if (response.statusCode == 404) {
        throw Exception('ملف ملصق الشحن غير موجود على الخادم (404)');
      } else {
        throw Exception('فشل تحميل الملف من الخادم (رمز الاستجابة: ${response.statusCode})');
      }
    } catch (e) {
      String safeMsg = e.toString();
      if (token != null && token.isNotEmpty) {
        safeMsg = safeMsg.replaceAll(token, '[REDACTED]');
      }
      debugPrint('[PDF_DIAGNOSTIC] Network exception: ${e.runtimeType}: $safeMsg');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.couldNotLaunchUrl),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'فتح في المتصفح الخارجي',
            icon: const Icon(Icons.open_in_browser, size: 20),
            onPressed: _openExternal,
          ),
          IconButton(
            tooltip: AppStrings.copiedToClipboard,
            icon: const Icon(Icons.copy_outlined, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.copiedToClipboard),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            tooltip: AppStrings.retry,
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _fetchDocument,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Error state ────────────────────────────────────────────────
          // Positioned.fill makes this a positioned Stack child, so Flutter
          // gives it tight constraints (w=384, h=751) directly — no
          // RenderConstrainedBox with additionalConstraints: BoxConstraints(biggest).
          // SingleChildScrollView receives those tight bounds, reports its own
          // size correctly, and gives its child unbounded height for scrolling.
          // Wrap instead of Row lets buttons reflow on narrow screens without
          // needing IntrinsicWidth or a fixed axis constraint.
          if (_errorMessage != null)
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 54, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _fetchDocument,
                            icon: const Icon(Icons.refresh),
                            label: const Text(AppStrings.retry),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openExternal,
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('فتح خارجياً'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )

          // ── Document state ─────────────────────────────────────────────
          // Both PhotoView and SfPdfViewer require tight (bounded) constraints
          // to determine their own size and render correctly — they each handle
          // all internal scrolling and zooming themselves.
          // Positioned.fill converts the Stack's loose constraints into tight
          // ones (top=0, left=0, right=0, bottom=0), giving each widget the
          // exact pixel dimensions it needs (e.g. w=384, h=751).
          else if (_documentBytes != null)
            Positioned.fill(
              child: _isImage
                  ? PhotoView(
                      imageProvider: MemoryImage(_documentBytes!),
                      backgroundDecoration: const BoxDecoration(color: AppColors.background),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2.5,
                    )
                  : SfPdfViewer.memory(
                      _documentBytes!,
                      controller: _pdfViewerController,
                      canShowScrollHead: true,
                      canShowScrollStatus: true,
                    ),
            ),

          // ── Loading overlay ────────────────────────────────────────────
          // Positioned.fill ensures the semi-transparent overlay covers the
          // full Stack area regardless of what other children are visible.
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: AppColors.background.withValues(alpha: 0.8),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 14),
                      Text(
                        'جاري تحميل المستند...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
