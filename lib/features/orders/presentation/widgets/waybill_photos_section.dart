import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/authenticated_cache_manager.dart';
import '../../../../core/utils/sha256_util.dart';
import '../../models/order_details.dart';
import '../../models/order_media.dart';
import '../cubits/order_details_cubit.dart';
import '../cubits/waybill_photos_cubit.dart';
import '../cubits/waybill_photos_state.dart';
import '../screens/full_screen_image_viewer.dart';

class WaybillPhotosSection extends StatelessWidget {
  final OrderDetails order;

  const WaybillPhotosSection({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WaybillPhotosCubit, WaybillPhotosState>(
      listener: (context, state) {
        if (state is WaybillPhotosSuccess) {
          context.read<OrderDetailsCubit>().updateOrder(state.refreshedOrder);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.uploadSuccess),
              backgroundColor: AppColors.redesignSuccessGreen,
            ),
          );
        } else if (state is WaybillPhotosFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is WaybillPhotosIdle &&
            state.notificationMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.notificationMessage!),
              backgroundColor: AppColors.accentDark,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<WaybillPhotosCubit>();
        final isUploading = state is WaybillPhotosUploading;
        final addedCount = state.selectedImages.length;
        final existingCount = order.waybillPhotos.length;
        final hasAny = existingCount > 0 || addedCount > 0;

        // Badge: "مضافة" when photo present, else "مطلوب"
        final String badgeLabel = hasAny ? 'مضافة' : 'مطلوب';
        final Color badgeColor = hasAny
            ? AppColors.redesignSuccessGreen
            : AppColors.redesignPrimaryBlue;
        final Color badgeBg = hasAny
            ? AppColors.redesignBadgeGreenBg
            : AppColors.redesignBadgeBlueBg;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.redesignCardBorder, width: 1.2),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (Title + Receipt Icon + Badge) ─────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: AppColors.redesignPrimaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      AppStrings.sectionWaybillPhotos,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.redesignMainText,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Instruction ──────────────────────────────────────────
              const Text(
                AppStrings.waybillPhotosInstruction,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.redesignSecondaryText,
                  height: 1.4,
                ),
              ),

              // ── Selected Previews with Removal Controls ──────────────
              if (addedCount > 0) ...[
                const SizedBox(height: 14),
                ...state.selectedImages.map(
                  (item) => _buildWaybillSelectedCard(item, cubit, isUploading),
                ),
              ],

              // ── Existing Remote Previews (if any) ────────────────────
              if (existingCount > 0) ...[
                const SizedBox(height: 14),
                ...order.waybillPhotos.asMap().entries.map(
                      (entry) => _buildWaybillExistingCard(
                        context,
                        entry.value,
                        entry.key,
                        order.waybillPhotos.map((p) => p.url).toList(),
                      ),
                    ),
              ],

              // ── Action Buttons ───────────────────────────────────────
              if (order.isReadOnly) ...[
                const SizedBox(height: 14),
                _buildReadOnlyBanner(),
              ] else ...[
                const SizedBox(height: 14),

                // Primary button: تصوير البوليصة
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isUploading ? null : cubit.pickFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined, size: 20),
                    label: const Text(AppStrings.captureWaybill),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.redesignPrimaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Secondary gallery action: اختيار من المعرض
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton.icon(
                    onPressed: isUploading ? null : cubit.pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text(AppStrings.chooseFromGallery),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.redesignPrimaryBlue,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                if (state is WaybillPhotosUploading) ...[
                  const SizedBox(height: 10),
                  _buildProgressBar(state),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Waybill Selected Card (Figma Style) ──────────────────────────────────────

  Widget _buildWaybillSelectedCard(
    HashedImageItem item,
    WaybillPhotosCubit cubit,
    bool isUploading,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redesignEmptyBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Info Text
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.waybillPhotoAdded,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.redesignMainText,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  AppStrings.waybillClarityHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.redesignSecondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Thumbnail Preview with accessible removal button
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  item.bytes,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.redesignEmptyBg,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.redesignSecondaryText,
                    ),
                  ),
                ),
              ),
              if (!isUploading)
                Positioned(
                  top: -6,
                  left: -6,
                  child: Semantics(
                    label: AppStrings.deleteWaybillSemantics,
                    button: true,
                    child: GestureDetector(
                      key: ValueKey('remove_waybill_photo_${item.hash}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => cubit.removeImage(item),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.redesignSecondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Existing Remote Waybill Card ──────────────────────────────────────────────

  Widget _buildWaybillExistingCard(
    BuildContext context,
    OrderMedia photo,
    int index,
    List<String> urls,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redesignEmptyBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بوليصة شحن مرفوعة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.redesignMainText,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'اضغط على الصورة لمعاينتها بالحجم الكامل.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.redesignSecondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(
                    imageUrls: urls,
                    initialIndex: index,
                    title: 'صور بوليصة الشحن (${index + 1}/${urls.length})',
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: photo.url,
                cacheManager: AuthenticatedCacheManager.instance,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 72,
                  height: 72,
                  color: Colors.white,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 72,
                  height: 72,
                  color: Colors.white,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.redesignSecondaryText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload Progress Bar ───────────────────────────────────────────────────────

  Widget _buildProgressBar(WaybillPhotosUploading state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              AppStrings.uploadingPhotos,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.redesignPrimaryBlue,
              ),
            ),
            Text(
              '${(state.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.redesignPrimaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: state.progress,
          backgroundColor: AppColors.redesignSegmentUnfilled,
          color: AppColors.redesignPrimaryBlue,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  // ── Read-only Banner ──────────────────────────────────────────────────────────

  Widget _buildReadOnlyBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusDelivered.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.statusDelivered.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.statusDelivered,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.completedOrderReadOnly,
              style: TextStyle(
                color: AppColors.statusDelivered,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
