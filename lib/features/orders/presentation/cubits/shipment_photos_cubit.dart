import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/storage/pending_photos_storage.dart';
import '../../../../core/utils/sha256_util.dart';
import '../../data/orders_repository.dart';
import 'shipment_photos_state.dart';

class ShipmentPhotosCubit extends Cubit<ShipmentPhotosState> {
  final OrdersRepository ordersRepository;
  final ImagePicker _imagePicker;
  final int orderId;
  final PendingPhotosStorage? pendingPhotosStorage;

  ShipmentPhotosCubit({
    required this.ordersRepository,
    required this.orderId,
    required int existingPhotosCount,
    this.pendingPhotosStorage,
    ImagePicker? imagePicker,
    bool autoLoad = true,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        super(ShipmentPhotosIdle(existingCount: existingPhotosCount)) {
    if (autoLoad && pendingPhotosStorage != null) {
      loadPendingPhotos();
    }
  }

  /// Update existing photo count when order is refreshed or changed
  void updateExistingCount(int count) {
    emit(ShipmentPhotosIdle(
      selectedImages: state.selectedImages,
      existingCount: count,
    ));
  }

  /// Load persisted pending photos from local storage for this order
  Future<void> loadPendingPhotos() async {
    if (pendingPhotosStorage == null) return;
    try {
      final persisted = await pendingPhotosStorage!.loadPendingPhotos(
        orderId: orderId,
        category: 'shipment',
      );
      if (persisted.isEmpty) return;

      final uploadedHashes = ordersRepository.getUploadedHashes(orderId);
      final notYetUploaded = <HashedImageItem>[];

      for (final item in persisted) {
        if (uploadedHashes.contains(item.hash)) {
          // Already uploaded to server previously, clean up from pending
          await pendingPhotosStorage!.removePhoto(
            orderId: orderId,
            category: 'shipment',
            hash: item.hash,
          );
        } else {
          notYetUploaded.add(item);
        }
      }

      if (notYetUploaded.isNotEmpty && !isClosed) {
        emit(ShipmentPhotosIdle(
          selectedImages: notYetUploaded,
          existingCount: state.existingCount,
        ));
      }
    } catch (_) {
      // Gracefully ignore local read errors
    }
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

    final acceptedList = <HashedImageItem>[];
    for (final item in filterResult.accepted) {
      if (pendingPhotosStorage != null) {
        final savedItem = await pendingPhotosStorage!.saveImageFile(
          orderId: orderId,
          category: 'shipment',
          name: item.name,
          bytes: item.bytes,
          hash: item.hash,
          originalPath: item.path,
        );
        acceptedList.add(savedItem);
      } else {
        acceptedList.add(item);
      }
    }

    final mergedList = List<HashedImageItem>.from(state.selectedImages)
      ..addAll(acceptedList);

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
  Future<void> removeImage(HashedImageItem item) async {
    final updated = List<HashedImageItem>.from(state.selectedImages)
      ..removeWhere((img) => img.hash == item.hash);

    if (pendingPhotosStorage != null) {
      await pendingPhotosStorage!.removePhoto(
        orderId: orderId,
        category: 'shipment',
        hash: item.hash,
      );
    }

    emit(ShipmentPhotosIdle(
      selectedImages: updated,
      existingCount: state.existingCount,
    ));
  }

  /// Clear all pending selected images
  Future<void> clearSelection() async {
    if (pendingPhotosStorage != null) {
      await pendingPhotosStorage!.clearCategoryPhotos(
        orderId: orderId,
        category: 'shipment',
      );
    }

    emit(ShipmentPhotosIdle(
      selectedImages: const [],
      existingCount: state.existingCount,
    ));
  }

  /// Upload selected shipment photos to backend
  Future<void> uploadPhotos() async {
    // Prevent duplicate concurrent upload submissions
    if (state is ShipmentPhotosUploading) return;

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

      // Successful: clear temporary queue and durable files only after server confirms success
      if (pendingPhotosStorage != null) {
        await pendingPhotosStorage!.clearCategoryPhotos(
          orderId: orderId,
          category: 'shipment',
        );
      }

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
