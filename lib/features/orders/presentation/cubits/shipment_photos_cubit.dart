import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/sha256_util.dart';
import '../../data/orders_repository.dart';
import 'shipment_photos_state.dart';

class ShipmentPhotosCubit extends Cubit<ShipmentPhotosState> {
  final OrdersRepository ordersRepository;
  final ImagePicker _imagePicker;
  final int orderId;

  ShipmentPhotosCubit({
    required this.ordersRepository,
    required this.orderId,
    required int existingPhotosCount,
    ImagePicker? imagePicker,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        super(ShipmentPhotosIdle(existingCount: existingPhotosCount));

  /// Update existing photo count when order is refreshed or changed
  void updateExistingCount(int count) {
    emit(ShipmentPhotosIdle(
      selectedImages: state.selectedImages,
      existingCount: count,
    ));
  }

  /// Add images directly from raw bytes (useful for camera, gallery, or tests)
  Future<void> addRawImages(List<({String path, String name, Uint8List bytes})> rawItems) async {
    if (rawItems.isEmpty) return;

    emit(ShipmentPhotosProcessing(
      selectedImages: state.selectedImages,
      existingCount: state.existingCount,
    ));

    final persistedHashes = ordersRepository.getUploadedHashes(orderId);
    final filterResult = Sha256Util.processAndFilter(
      newPicks: rawItems,
      alreadySelected: state.selectedImages,
      persistedHashes: persistedHashes,
    );

    final mergedList = List<HashedImageItem>.from(state.selectedImages)
      ..addAll(filterResult.accepted);

    String? notification;
    if (filterResult.hasDuplicates) {
      notification = AppStrings.duplicateImagesFound;
    }

    emit(ShipmentPhotosIdle(
      selectedImages: mergedList,
      existingCount: state.existingCount,
      notificationMessage: notification,
    ));
  }

  /// Pick single photo using device camera
  Future<void> pickFromCamera() async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Preserve quality while preventing massive payloads
      );
      if (xFile == null) return;

      final bytes = await xFile.readAsBytes();
      await addRawImages([
        (path: xFile.path, name: xFile.name, bytes: bytes),
      ]);
    } catch (_) {
      emit(ShipmentPhotosIdle(
        selectedImages: state.selectedImages,
        existingCount: state.existingCount,
        notificationMessage: 'تعذر التقاط الصورة من الكاميرا',
      ));
    }
  }

  /// Pick multiple photos from gallery
  Future<void> pickFromGallery() async {
    try {
      final xFiles = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      if (xFiles.isEmpty) return;

      final rawList = <({String path, String name, Uint8List bytes})>[];
      for (final file in xFiles) {
        final bytes = await file.readAsBytes();
        rawList.add((path: file.path, name: file.name, bytes: bytes));
      }

      await addRawImages(rawList);
    } catch (_) {
      emit(ShipmentPhotosIdle(
        selectedImages: state.selectedImages,
        existingCount: state.existingCount,
        notificationMessage: 'تعذر اختيار الصور من المعرض',
      ));
    }
  }

  /// Remove single image from pending selection
  void removeImage(HashedImageItem item) {
    final updated = List<HashedImageItem>.from(state.selectedImages)
      ..removeWhere((img) => img.hash == item.hash);
    emit(ShipmentPhotosIdle(
      selectedImages: updated,
      existingCount: state.existingCount,
    ));
  }

  /// Clear all pending selected images
  void clearSelection() {
    emit(ShipmentPhotosIdle(
      selectedImages: const [],
      existingCount: state.existingCount,
    ));
  }

  /// Upload selected shipment photos to backend
  Future<void> uploadPhotos() async {
    // Validate business rule: minimum total photos >= 5
    if (!state.canUpload) {
      emit(ShipmentPhotosFailure(
        message: AppStrings.minShipmentPhotosHint,
        selectedImages: state.selectedImages,
        existingCount: state.existingCount,
      ));
      return;
    }

    emit(ShipmentPhotosUploading(
      selectedImages: state.selectedImages,
      existingCount: state.existingCount,
      progress: 0.0,
    ));

    try {
      final uploadPayload = state.selectedImages
          .map((item) => (name: item.name, bytes: item.bytes, hash: item.hash))
          .toList();

      final refreshedOrder = await ordersRepository.uploadShipmentPhotos(
        orderId: orderId,
        photos: uploadPayload,
        onSendProgress: (sent, total) {
          if (total > 0 && !isClosed) {
            final progress = (sent / total).clamp(0.0, 1.0);
            emit(ShipmentPhotosUploading(
              selectedImages: state.selectedImages,
              existingCount: state.existingCount,
              progress: progress,
            ));
          }
        },
      );

      // Successful: clear temporary queue, update count, return refreshed order
      emit(ShipmentPhotosSuccess(
        refreshedOrder: refreshedOrder,
        existingCount: refreshedOrder.shipmentPhotos.length,
      ));
    } on Failure catch (e) {
      // Robustness requirement: DO NOT lose selected images on failure for retry!
      emit(ShipmentPhotosFailure(
        message: e.message,
        selectedImages: state.selectedImages,
        existingCount: state.existingCount,
      ));
    } catch (_) {
      emit(ShipmentPhotosFailure(
        message: AppStrings.errorShipmentUpload,
        selectedImages: state.selectedImages,
        existingCount: state.existingCount,
      ));
    }
  }
}
