import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/order_details.dart';
import '../../models/order_media.dart';
import '../screens/full_screen_image_viewer.dart';
import '../screens/pdf_viewer_screen.dart';
import '../../../../core/network/authenticated_cache_manager.dart';

/// Read-only section that shows all external warehouse invoices (فاتورة المخزن)
/// attached to an order.
///
/// This section is **view-only** — it does not support any upload interaction,
/// because external warehouse invoices are attached by warehouse personnel outside
/// this application and only displayed here for reference.
class ExternalWarehouseInvoicesSection extends StatelessWidget {
  final OrderDetails order;

  const ExternalWarehouseInvoicesSection({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final invoices = order.externalWarehouseInvoices;
    final warehouseInvoiceUrl = order.warehouseInvoiceUrl?.trim();
    final hasPdfInvoice =
        warehouseInvoiceUrl != null && warehouseInvoiceUrl.isNotEmpty;
    final totalCount = invoices.length + (hasPdfInvoice ? 1 : 0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warehouse_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      AppStrings.sectionExternalWarehouseInvoice,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCount ${totalCount == 1 ? 'ملف' : 'ملفات'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.divider),

            // ── Content ──────────────────────────────────────────────────────
            if (invoices.isEmpty && !hasPdfInvoice)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  AppStrings.noExternalWarehouseInvoice,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              )
            else ...[
              if (hasPdfInvoice) ...[
                _buildPdfInvoiceButton(context, warehouseInvoiceUrl),
                if (invoices.isNotEmpty) const SizedBox(height: 12),
              ],
              if (invoices.isNotEmpty) _InvoiceGallery(invoices: invoices),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPdfInvoiceButton(BuildContext context, String url) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                title: AppStrings.sectionExternalWarehouseInvoice,
                url: url,
              ),
            ),
          );
        },
        icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
        label: const Text(
          AppStrings.viewWarehouseInvoicePdf,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private gallery widget — extracted to keep the parent widget readable.
// ─────────────────────────────────────────────────────────────────────────────
class _InvoiceGallery extends StatelessWidget {
  final List<OrderMedia> invoices;

  const _InvoiceGallery({required this.invoices});

  @override
  Widget build(BuildContext context) {
    // Only image MIME types are shown in the horizontal gallery.
    // Non-image files (e.g. PDF) could be added here in the future.
    final imageInvoices = invoices.where(_isImage).toList();
    final urls = imageInvoices.map((inv) => inv.url).toList();

    if (imageInvoices.isEmpty) {
      // Fallback: show file names as a plain list (for non-image attachments).
      return _FileList(invoices: invoices);
    }

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageInvoices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final inv = imageInvoices[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(
                    imageUrls: urls,
                    initialIndex: index,
                    title:
                        '${AppStrings.sectionExternalWarehouseInvoice} (${index + 1}/${imageInvoices.length})',
                  ),
                ),
              );
            },
            child: Hero(
              tag: '${inv.url}-$index-warehouse',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 90,
                  height: 90,
                  color: AppColors.background,
                  child: CachedNetworkImage(
                    imageUrl: inv.url,
                    cacheManager: AuthenticatedCacheManager.instance,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static bool _isImage(OrderMedia media) {
    final mime = media.mimeType.toLowerCase();
    return mime.startsWith('image/');
  }
}

// Displays a plain list of file names for non-image invoice attachments.
class _FileList extends StatelessWidget {
  final List<OrderMedia> invoices;

  const _FileList({required this.invoices});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: invoices.map((inv) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(
                Icons.attach_file,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  inv.fileName.isNotEmpty ? inv.fileName : inv.url,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
