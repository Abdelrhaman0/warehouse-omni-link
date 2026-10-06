import 'package:equatable/equatable.dart';
import '../../../../core/utils/sha256_util.dart';
import '../../models/order_details.dart';

abstract class WaybillPhotosState extends Equatable {
  final List<HashedImageItem> selectedImages;
  final int existingCount;

  const WaybillPhotosState({
    this.selectedImages = const [],
    this.existingCount = 0,
  });

  bool get canUpload => selectedImages.isNotEmpty;

  @override
  List<Object?> get props => [selectedImages, existingCount];
}

class WaybillPhotosIdle extends WaybillPhotosState {
  final String? notificationMessage;

  const WaybillPhotosIdle({
    super.selectedImages = const [],
    super.existingCount = 0,
    this.notificationMessage,
  });

  @override
  List<Object?> get props => [selectedImages, existingCount, notificationMessage];
}

class WaybillPhotosProcessing extends WaybillPhotosState {
  const WaybillPhotosProcessing({
    super.selectedImages = const [],
    super.existingCount = 0,
  });
}

class WaybillPhotosUploading extends WaybillPhotosState {
  final double progress;

  const WaybillPhotosUploading({
    required super.selectedImages,
    required super.existingCount,
    required this.progress,
  });

  @override
  List<Object?> get props => [selectedImages, existingCount, progress];
}

class WaybillPhotosSuccess extends WaybillPhotosState {
  final OrderDetails refreshedOrder;

  const WaybillPhotosSuccess({
    required this.refreshedOrder,
    required super.existingCount,
  }) : super(selectedImages: const []);

  @override
  List<Object?> get props => [refreshedOrder, existingCount];
}

class WaybillPhotosFailure extends WaybillPhotosState {
  final String message;

  const WaybillPhotosFailure({
    required this.message,
    required super.selectedImages,
    required super.existingCount,
  });

  @override
  List<Object?> get props => [message, selectedImages, existingCount];
}
