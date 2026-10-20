import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../models/order_details.dart';
import '../cubits/shipment_photos_cubit.dart';
import '../cubits/shipment_photos_state.dart';
import '../cubits/waybill_photos_cubit.dart';
import '../cubits/waybill_photos_state.dart';
import 'shipment_photos_section.dart';
import 'waybill_photos_section.dart';

class PhotosTabView extends StatelessWidget {
  final OrderDetails order;

  const PhotosTabView({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShipmentPhotosCubit, ShipmentPhotosState>(
      builder: (context, shipmentState) {
        return BlocBuilder<WaybillPhotosCubit, WaybillPhotosState>(
          builder: (context, waybillState) {
            final shipmentCubit = context.read<ShipmentPhotosCubit>();
            final waybillCubit = context.read<WaybillPhotosCubit>();

            final int shipmentAdded = shipmentState.selectedImages.length;
            final int waybillAdded = waybillState.selectedImages.length;
            final int totalAdded = shipmentAdded + waybillAdded;

            final bool isShipmentUploading =
                shipmentState is ShipmentPhotosUploading;
            final bool isWaybillUploading =
                waybillState is WaybillPhotosUploading;
            final bool isAnyUploading =
                isShipmentUploading || isWaybillUploading;

            final int shipmentTotal =
                order.shipmentPhotos.length + shipmentAdded;
            final int shipmentRemaining =
                (5 - shipmentTotal) > 0 ? (5 - shipmentTotal) : 0;
            final bool hasWaybillPhoto =
                order.waybillPhotos.isNotEmpty || waybillAdded > 0;

            final bool requirementsMet =
                shipmentRemaining == 0 && hasWaybillPhoto;
            final bool canUpload =
                requirementsMet && totalAdded > 0 && !isAnyUploading;

            final String helperText = _buildHelperText(
              shipmentRemaining: shipmentRemaining,
              hasWaybillPhoto: hasWaybillPhoto,
              requirementsMet: requirementsMet,
              totalAdded: totalAdded,
            );

            return Container(
              color: AppColors.redesignBackground,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Page Heading & Subtitle ─────────────────
                          _buildPageHeader(),

                          // ── Cards Section ───────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ShipmentPhotosSection(order: order),
                                const SizedBox(height: 16),
                                WaybillPhotosSection(order: order),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Sticky Bottom Upload Area ─────────────────────────
                  if (!order.isReadOnly)
                    _buildBottomUploadArea(
                      context: context,
                      shipmentCubit: shipmentCubit,
                      waybillCubit: waybillCubit,
                      canUpload: canUpload,
                      isAnyUploading: isAnyUploading,
                      requirementsMet: requirementsMet,
                      totalAdded: totalAdded,
                      helperText: helperText,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Page Header ─────────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.photosTabHeading,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.redesignMainText,
              height: 1.2,
            ),
          ),
          SizedBox(height: 6),
          Text(
            AppStrings.photosTabSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.redesignSecondaryText,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Upload Area (Figma Style) ────────────────────────────────────────

  Widget _buildBottomUploadArea({
    required BuildContext context,
    required ShipmentPhotosCubit shipmentCubit,
    required WaybillPhotosCubit waybillCubit,
    required bool canUpload,
    required bool isAnyUploading,
    required bool requirementsMet,
    required int totalAdded,
    required String helperText,
  }) {
    final String buttonLabel;
    if (isAnyUploading) {
      buttonLabel = 'جارٍ الرفع...';
    } else if (canUpload && totalAdded > 0) {
      buttonLabel =
          'رفع الصور (${ArabicNumberConverter.convert(totalAdded)})';
    } else {
      buttonLabel = 'رفع الصور';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.redesignCardBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Helper text row with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  requirementsMet
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: requirementsMet
                      ? AppColors.redesignSuccessGreen
                      : AppColors.redesignSecondaryText,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    helperText,
                    style: TextStyle(
                      fontSize: 12,
                      color: requirementsMet
                          ? AppColors.redesignSuccessGreen
                          : AppColors.redesignSecondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: canUpload
                    ? () => _uploadAll(
                          context: context,
                          shipmentCubit: shipmentCubit,
                          waybillCubit: waybillCubit,
                        )
                    : null,
                icon: isAnyUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_outlined, size: 20),
                label: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.redesignPrimaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor: AppColors.redesignDisabledBg,
                  disabledForegroundColor: AppColors.redesignDisabledText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Disclaimer subtext
            const Text(
              AppStrings.uploadPhotosDisclaimer,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.redesignSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Upload Both Categories ──────────────────────────────────────────────────

  Future<void> _uploadAll({
    required BuildContext context,
    required ShipmentPhotosCubit shipmentCubit,
    required WaybillPhotosCubit waybillCubit,
  }) async {
    final bool isShipmentUploading =
        shipmentCubit.state is ShipmentPhotosUploading;
    final bool isWaybillUploading =
        waybillCubit.state is WaybillPhotosUploading;
    if (isShipmentUploading || isWaybillUploading) return;

    final bool hasShipment =
        shipmentCubit.state.selectedImages.isNotEmpty;
    final bool hasWaybill =
        waybillCubit.state.selectedImages.isNotEmpty;

    if (!hasShipment && !hasWaybill) return;

    if (hasShipment) {
      await shipmentCubit.uploadPhotos();
      if (shipmentCubit.state is ShipmentPhotosFailure) {
        return;
      }
    }
    if (hasWaybill) {
      await waybillCubit.uploadPhotos();
    }
  }

  // ── Helper Text Formatter ───────────────────────────────────────────────────

  String _buildHelperText({
    required int shipmentRemaining,
    required bool hasWaybillPhoto,
    required bool requirementsMet,
    required int totalAdded,
  }) {
    if (requirementsMet && totalAdded > 0) {
      return AppStrings.uploadPhotosReady;
    }
    if (shipmentRemaining > 0 && !hasWaybillPhoto) {
      if (shipmentRemaining == 5) {
        return 'لإتاحة الرفع، أضف ٥ صور للشحنة وصور البوليصة.';
      } else {
        return 'لإتاحة الرفع، أضف ${ArabicNumberConverter.convert(shipmentRemaining)} صور للشحنة وصور البوليصة.';
      }
    } else if (shipmentRemaining > 0) {
      return 'لإتاحة الرفع، أضف ${ArabicNumberConverter.convert(shipmentRemaining)} صور للشحنة.';
    } else if (!hasWaybillPhoto) {
      return 'لإتاحة الرفع، أضف صورة بوليصة الشحن.';
    } else if (totalAdded == 0) {
      return 'لا توجد صور جديدة للرفع.';
    } else {
      return AppStrings.uploadPhotosReady;
    }
  }
}
