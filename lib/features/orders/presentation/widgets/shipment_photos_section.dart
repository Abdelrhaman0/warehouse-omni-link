import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/authenticated_cache_manager.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../../../core/utils/sha256_util.dart';
import '../../models/order_details.dart';
import '../../models/order_media.dart';
import '../cubits/order_details_cubit.dart';
import '../cubits/shipment_photos_cubit.dart';
import '../cubits/shipment_photos_state.dart';
import '../screens/full_screen_image_viewer.dart';

class ShipmentPhotosSection extends StatelessWidget {
  final OrderDetails order;

  const ShipmentPhotosSection({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShipmentPhotosCubit, ShipmentPhotosState>(
      listener: (context, state) {
        if (state is ShipmentPhotosSuccess) {
          context.read<OrderDetailsCubit>().updateOrder(state.refreshedOrder);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.uploadSuccess),
              backgroundColor: AppColors.redesignSuccessGreen,
            ),
          );
        } else if (state is ShipmentPhotosFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is ShipmentPhotosIdle &&
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
        final cubit = context.read<ShipmentPhotosCubit>();
        final isUploading = state is ShipmentPhotosUploading;
        final addedCount = state.selectedImages.length;
        final existingCount = order.shipmentPhotos.length;
        final totalCount = existingCount + addedCount;
        final isSatisfied = totalCount >= 5;

        // Badge styling: "مكتمل" at >=5, else "مطلوب"
        final String badgeLabel = isSatisfied ? 'مكتمل' : 'مطلوب';
        final Color badgeColor = isSatisfied
            ? AppColors.redesignSuccessGreen
            : AppColors.redesignPrimaryBlue;
        final Color badgeBg = isSatisfied
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
              // ── Header (Title + Box Icon + Badge) ─────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.redesignPrimaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      AppStrings.sectionShipmentPhotos,
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
                AppStrings.shipmentPhotosInstruction,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.redesignSecondaryText,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 14),

              // ── Counter row + Segmented Progress Bar ─────────────────
              _buildCounterRow(totalCount, isSatisfied),

              const SizedBox(height: 8),

              _buildSegmentedProgressBar(totalCount),

              const SizedBox(height: 14),

              // ── Photo Grid or Empty State ────────────────────────────
              if (totalCount == 0 && !order.isReadOnly)
                _buildEmptyState()
              else
                _buildPhotoGrid(context, state, cubit),

              // ── Actions & Upload Progress ────────────────────────────
              if (order.isReadOnly) ...[
                const SizedBox(height: 14),
                _buildReadOnlyBanner(),
              ] else ...[
                const SizedBox(height: 14),

                // Primary camera button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isUploading ? null : cubit.pickFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined, size: 20),
                    label: const Text(AppStrings.takePhoto),
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

                // Secondary gallery action
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

                if (state is ShipmentPhotosUploading) ...[
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

  // ── Counter Row ─────────────────────────────────────────────────────────────

  Widget _buildCounterRow(int totalCount, bool isSatisfied) {
    final String leftCountLabel;
    final Color leftCountColor;

    if (isSatisfied) {
      leftCountLabel =
          '${ArabicNumberConverter.convert(totalCount)} صور مضافة';
      leftCountColor = AppColors.redesignSuccessGreen;
    } else if (totalCount == 0) {
      leftCountLabel = '٠ من ٥ صور';
      leftCountColor = AppColors.redesignPrimaryBlue;
    } else {
      leftCountLabel =
          '${ArabicNumberConverter.convert(totalCount)} من ٥ صور';
      leftCountColor = AppColors.redesignPrimaryBlue;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            leftCountLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: leftCountColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '٥ صور على الأقل',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.redesignSecondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Segmented Progress Bar (5 visual segments) ──────────────────────────────

  Widget _buildSegmentedProgressBar(int totalCount) {
    return Row(
      children: List.generate(5, (index) {
        final isFilled = index < totalCount;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: index == 4 ? 0 : 3,
              right: index == 0 ? 0 : 3,
            ),
            height: 4,
            decoration: BoxDecoration(
              color: isFilled
                  ? AppColors.redesignPrimaryBlue
                  : AppColors.redesignSegmentUnfilled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.redesignEmptyBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.shipmentPhotosEmptyState,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.redesignSecondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.photo_outlined,
            size: 22,
            color: Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }

  // ── Photo Grid ──────────────────────────────────────────────────────────────

  Widget _buildPhotoGrid(
    BuildContext context,
    ShipmentPhotosState state,
    ShipmentPhotosCubit cubit,
  ) {
    final isUploading = state is ShipmentPhotosUploading;
    final existingPhotos = order.shipmentPhotos;
    final selectedImages = state.selectedImages;
    final urls = existingPhotos.map((p) => p.url).toList();
    final bool showAddTile = !isUploading && !order.isReadOnly;
    final totalItems =
        existingPhotos.length + selectedImages.length + (showAddTile ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index < existingPhotos.length) {
          return _buildExistingPhotoCell(
            context,
            existingPhotos[index],
            index,
            urls,
          );
        }
        final selectedIndex = index - existingPhotos.length;
        if (selectedIndex < selectedImages.length) {
          return _buildSelectedPhotoCell(
            selectedImages[selectedIndex],
            cubit,
            isUploading,
          );
        }
        return _buildAddPhotoCell(cubit, isUploading);
      },
    );
  }

  Widget _buildExistingPhotoCell(
    BuildContext context,
    OrderMedia photo,
    int index,
    List<String> urls,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(
              imageUrls: urls,
              initialIndex: index,
              title: 'صور الشحنة (${index + 1}/${urls.length})',
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: photo.url,
          cacheManager: AuthenticatedCacheManager.instance,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.redesignEmptyBg,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.redesignEmptyBg,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.redesignSecondaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPhotoCell(
    HashedImageItem item,
    ShipmentPhotosCubit cubit,
    bool isUploading,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            item.bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
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
            top: 4,
            left: 4,
            child: Semantics(
              label: AppStrings.deletePhotoSemantics,
              button: true,
              child: GestureDetector(
                key: ValueKey('remove_shipment_photo_${item.hash}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => cubit.removeImage(item),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.topLeft,
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
    );
  }

  Widget _buildAddPhotoCell(ShipmentPhotosCubit cubit, bool isUploading) {
    return GestureDetector(
      onTap: isUploading ? null : cubit.pickFromCamera,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.redesignAddTileBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: AppColors.redesignPrimaryBlue,
              size: 26,
            ),
            SizedBox(height: 4),
            Text(
              'إضافة صورة',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.redesignPrimaryBlue,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Upload Progress Bar ───────────────────────────────────────────────────────

  Widget _buildProgressBar(ShipmentPhotosUploading state) {
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
