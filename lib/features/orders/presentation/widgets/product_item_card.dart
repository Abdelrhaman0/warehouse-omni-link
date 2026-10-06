import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/order_item.dart';
import '../screens/full_screen_image_viewer.dart';
import '../../../../core/network/authenticated_cache_manager.dart';

class ProductItemCard extends StatelessWidget {
  final OrderItem item;

  const ProductItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final hasImage = item.productImage != null && item.productImage!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Product Thumbnail
          GestureDetector(
            onTap: hasImage
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          imageUrls: [item.productImage!],
                          initialIndex: 0,
                          title: item.productName,
                        ),
                      ),
                    );
                  }
                : null,
            child: MouseRegion(
              cursor: hasImage ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      color: AppColors.background,
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: item.productImage!,
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
                                Icons.image_not_supported_outlined,
                                color: AppColors.textMuted,
                                size: 28,
                              ),
                            )
                          : const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.textMuted,
                              size: 28,
                            ),
                    ),
                    if (hasImage)
                      PositionedDirectional(
                        bottom: 3,
                        end: 3,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (item.sku.isNotEmpty)
                      Text.rich(
                        TextSpan(
                          text: '${AppStrings.sku}: ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: item.sku,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '${AppStrings.quantity}: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
