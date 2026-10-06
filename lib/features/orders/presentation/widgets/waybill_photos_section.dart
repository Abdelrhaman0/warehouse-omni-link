import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/order_details.dart';
import '../../models/order_media.dart';
import '../cubits/order_details_cubit.dart';
import '../cubits/waybill_photos_cubit.dart';
import '../cubits/waybill_photos_state.dart';
import '../screens/full_screen_image_viewer.dart';
import '../../../../core/network/authenticated_cache_manager.dart';

class WaybillPhotosSection extends StatelessWidget {
  final OrderDetails order;

  const WaybillPhotosSection({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WaybillPhotosCubit, WaybillPhotosState>(
      listener: (context, state) {
        if (state is WaybillPhotosSuccess) {
          // Section 38: Update order details from backend response
          context.read<OrderDetailsCubit>().updateOrder(state.refreshedOrder);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.uploadSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is WaybillPhotosFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is WaybillPhotosIdle && state.notificationMessage != null) {
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              AppStrings.sectionWaybillPhotos,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${order.waybillPhotos.length} صورة',
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

                // Existing Photos
                if (order.waybillPhotos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      AppStrings.noPhotosYet,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  )
                else ...[
                  const Text(
                    AppStrings.existingPhotos,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildExistingGallery(context, order.waybillPhotos),
                ],

                // Upload controls (Hidden if delivered / read-only)
                if (order.isReadOnly) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusDelivered.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.statusDelivered.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_outline, color: AppColors.statusDelivered, size: 18),
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
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Camera & Gallery action buttons
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cameraButton = OutlinedButton.icon(
                        onPressed: state is WaybillPhotosUploading ? null : cubit.pickFromCamera,
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text(AppStrings.takePhoto),
                      );

                      final galleryButton = OutlinedButton.icon(
                        onPressed: state is WaybillPhotosUploading ? null : cubit.pickFromGallery,
                        icon: const Icon(Icons.photo_size_select_actual_outlined, size: 18),
                        label: const Text(AppStrings.chooseFromGallery),
                      );

                      if (constraints.maxWidth < 400) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            cameraButton,
                            const SizedBox(height: 10),
                            galleryButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cameraButton),
                          const SizedBox(width: 10),
                          Expanded(child: galleryButton),
                        ],
                      );
                    },
                  ),

                  // Selected Images Preview Grid
                  if (state.selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppStrings.selectedPhotos} (${state.selectedImages.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: state is WaybillPhotosUploading ? null : cubit.clearSelection,
                          child: const Text(
                            AppStrings.clearSelection,
                            style: TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSelectedGallery(state, cubit),
                  ],

                  const SizedBox(height: 16),

                  // Progress
                  if (state is WaybillPhotosUploading) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              AppStrings.uploadingPhotos,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '${(state.progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: state.progress,
                          backgroundColor: AppColors.divider,
                          color: AppColors.primary,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],

                  // Upload button
                  ElevatedButton.icon(
                    onPressed: (state.canUpload && state is! WaybillPhotosUploading)
                        ? cubit.uploadPhotos
                        : null,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      state is WaybillPhotosFailure
                          ? AppStrings.retryUpload
                          : AppStrings.uploadWaybillPhotos,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExistingGallery(BuildContext context, List<OrderMedia> photos) {
    // Extract plain URLs for the full-screen viewer (which accepts List<String>)
    final urls = photos.map((p) => p.url).toList();
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = photos[index].url;
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(
                    imageUrls: urls,
                    initialIndex: index,
                    title: 'صور بوليصة الشحن (${index + 1}/${photos.length})',
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 90,
                height: 90,
                color: AppColors.background,
                child: CachedNetworkImage(
                  imageUrl: url,
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
          );
        },
      ),
    );
  }

  Widget _buildSelectedGallery(WaybillPhotosState state, WaybillPhotosCubit cubit) {
    final isUploading = state is WaybillPhotosUploading;
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.selectedImages.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = state.selectedImages[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 90,
                  height: 90,
                  color: AppColors.background,
                  child: Image.memory(
                    item.bytes,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (!isUploading)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => cubit.removeImage(item),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
