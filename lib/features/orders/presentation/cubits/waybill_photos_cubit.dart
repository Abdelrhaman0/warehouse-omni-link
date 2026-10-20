import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/storage/pending_photos_storage.dart';
import '../../../../core/utils/sha256_util.dart';
import '../../data/orders_repository.dart';
import 'waybill_photos_state.dart';

class WaybillPhotosCubit extends Cubit<WaybillPhotosState> {
  final OrdersRepository ordersRepository;
  final ImagePicker _imagePicker;
  final int orderId;
  final PendingPhotosStorage? pendingPhotosStorage;

  WaybillPhotosCubit({
    required this.ordersRepository,
    required this.orderId,
    required int existingPhotosCount,
    this.pendingPhotosStorage,
    ImagePicker? imagePicker,
    bool autoLoad = true,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        super(WaybillPhotosIdle(existingCount: existingPhotosCount)) {
    if (autoLoad && pendingPhotosStorage != null) {
      loadPendingPhotos();
    }
  }

  void updateExistingCount(int count) {
    emit(WaybillPhotosIdle(
      selectedImages: state.selectedImages,
      existingCount: count,
    ));
  }

  /// Load persisted pending waybill photos from local storage for this order
  Future<void> loadPendingPhotos() async {
    if (pendingPhotosStorage == null) return;
    try {
      final persisted = await pendingPhotosStorage!.loadPendingPhotos(
        orderId: orderId,
        category: 'waybill',
      );
      if (persisted.isEmpty) return;

      final uploadedHashes = ordersRepository.getUploadedHashes(orderId);
      final notYetUploaded = <HashedImageItem>[];

      for (final item in persisted) {
        if (uploadedHashes.contains(item.hash)) {
          await pendingPhotosStorage!.removePhoto(
            orderId: orderId,
            category: 'waybill',
            hash: item.hash,
          );
        } else {
          notYetUploaded.add(item);
        }
      }

      if (notYetUploaded.isNotEmpty && !isClosed) {
        emit(WaybillPhotosIdle(
          selectedImages: notYetUploaded,
          existingCount: state.existingCount,
        ));
      }
    } catch (_) {
      // Gracefully handle local read errors
    }
  }

  Future<void> addRawImages(List<({String path, String name, Uint8List bytes})> rawItems) async {
    if (rawItems.isEmpty) return;

    emit(WaybillPhotosProcessing(
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
          category: 'waybill',
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

    emit(WaybillPhotosIdle(
      selectedImages: mergedList,
      existingCount: state.existingCount,
      notificationMessage: notification,
    ));
  }

  Future<void> pickFromCamera() async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (xFile == null) return;

      final bytes = await xFile.readAsBytes();
      await addRawImages([
        (path: xFile.path, name: xFile.name, bytes: bytes),
      ]);
    } catch (_) {
      emit(WaybillPhotosIdle(
        selectedImages: state.selectedImages,
        existingCount: state.existingCount,
        notificationMessage: 'تعذر التقاط صورة البوليصة',
      ));
    }
  }

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
      emit(WaybillPhotosIdle(
        selectedImages: state.selectedImages,
        existingCount: state.existingCount,
        notificationMessage: 'تعذر اختيار صور البوليصة',
      ));
    }
  }

  Future<void> removeImage(HashedImageItem item) async {
    final updated = List<HashedImageItem>.from(state.selectedImages)
      ..removeWhere((img) => img.hash == item.hash);

    if (pendingPhotosStorage != null) {
      await pendingPhotosStorage!.removePhoto(
        orderId: orderId,
        category: 'waybill',
        hash: item.hash,
      );
    }

    emit(WaybillPhotosIdle(
      selectedImages: updated,
      existingCount: state.existingCount,
    ));
  }

  Future<void> clearSelection() async {
    if (pendingPhotosStorage != null) {
      await pendingPhotosStorage!.clearCategoryPhotos(
        orderId: orderId,
        category: 'waybill',
      );
    }

    emit(WaybillPhotosIdle(
      selectedImages: const [],
      existingCount: state.existingCount,
    ));
  }

  Future<void> uploadPhotos() async {
    // Prevent duplicate concurrent upload submissions
    if (state is WaybillPhotosUploading) return;
    if (!state.canUpload) return;

    emit(WaybillPhotosUploading(
      selectedImages: state.selectedImages,
      existingCount: state.existingCount,
      progress: 0.0,
    ));

    try {
      final uploadPayload = state.selectedImages
          .map((item) => (name: item.name, bytes: item.bytes, hash: item.hash))
          .toList();

      final refreshedOrder = await ordersRepository.uploadWaybillPhotos(
        orderId: orderId,
        photos: uploadPayload,
        onSendProgress: (sent, total) {
          if (total > 0 && !isClosed) {
            final progress = (sent / total).clamp(0.0, 1.0);
            emit(WaybillPhotosUploading(
              selectedImages: state.selectedImages,
              existingCount: state.existingCount,
              progress: progress,
            ));
          }
        },
      );

      // Successful: clear pending storage only after confirmation
      if (pendingPhotosStorage != null) {
        await pendingPhotosStorage!.clearCategoryPhotos(
          orderId: orderId,
          category: 'waybill',
        );
      }

      emit(WaybillPhotosSuccess(
        refreshedOrder: refreshedOrder,
        existingCount: refreshedOrder.waybillPhotos.length,
      ));
    } on Failure catch (e) {
      emit(WaybillPhotosFailure(
        message: e.message,
        selectedImages: state.selectedImages,
        existingCount: state.existingCount,
      ));
    } catch (_) {
      emit(WaybillPhotosFailure(
        message: AppStrings.errorWaybillUpload,
        selectedImages: state.selectedImages,
        existingCount: state.existingCount,
      ));
    }
  }
}
