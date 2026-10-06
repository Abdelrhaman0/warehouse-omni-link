import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/sha256_util.dart';
import '../../data/orders_repository.dart';
import 'waybill_photos_state.dart';

class WaybillPhotosCubit extends Cubit<WaybillPhotosState> {
  final OrdersRepository ordersRepository;
  final ImagePicker _imagePicker;
  final int orderId;

  WaybillPhotosCubit({
    required this.ordersRepository,
    required this.orderId,
    required int existingPhotosCount,
    ImagePicker? imagePicker,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        super(WaybillPhotosIdle(existingCount: existingPhotosCount));

  void updateExistingCount(int count) {
    emit(WaybillPhotosIdle(
      selectedImages: state.selectedImages,
      existingCount: count,
    ));
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

    final mergedList = List<HashedImageItem>.from(state.selectedImages)
      ..addAll(filterResult.accepted);

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

  void removeImage(HashedImageItem item) {
    final updated = List<HashedImageItem>.from(state.selectedImages)
      ..removeWhere((img) => img.hash == item.hash);
    emit(WaybillPhotosIdle(
      selectedImages: updated,
      existingCount: state.existingCount,
    ));
  }

  void clearSelection() {
    emit(WaybillPhotosIdle(
      selectedImages: const [],
      existingCount: state.existingCount,
    ));
  }

  Future<void> uploadPhotos() async {
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
