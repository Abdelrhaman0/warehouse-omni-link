import 'package:equatable/equatable.dart';
import '../../../../core/utils/sha256_util.dart';
import '../../models/order_details.dart';

abstract class ShipmentPhotosState extends Equatable {
  final List<HashedImageItem> selectedImages;
  final int existingCount;

  const ShipmentPhotosState({
    this.selectedImages = const [],
    this.existingCount = 0,
  });

  /// Total unique shipment photos if upload succeeds
  int get totalCount => existingCount + selectedImages.length;

  /// Business rule: minimum final total must be >= 5
  bool get canUpload => totalCount >= 5 && selectedImages.isNotEmpty;

  /// Number of photos still needed to satisfy minimum rule
  int get remainingForMinimum => (5 - totalCount) > 0 ? (5 - totalCount) : 0;

  @override
  List<Object?> get props => [selectedImages, existingCount];
}

class ShipmentPhotosIdle extends ShipmentPhotosState {
  final String? notificationMessage;

  const ShipmentPhotosIdle({
    super.selectedImages = const [],
    super.existingCount = 0,
    this.notificationMessage,
  });

  @override
  List<Object?> get props => [selectedImages, existingCount, notificationMessage];
}

class ShipmentPhotosProcessing extends ShipmentPhotosState {
  const ShipmentPhotosProcessing({
    super.selectedImages = const [],
    super.existingCount = 0,
  });
}

class ShipmentPhotosUploading extends ShipmentPhotosState {
  final double progress; // 0.0 to 1.0

  const ShipmentPhotosUploading({
    required super.selectedImages,
    required super.existingCount,
    required this.progress,
  });

  @override
  List<Object?> get props => [selectedImages, existingCount, progress];
}

class ShipmentPhotosSuccess extends ShipmentPhotosState {
  final OrderDetails refreshedOrder;

  const ShipmentPhotosSuccess({
    required this.refreshedOrder,
    required super.existingCount,
  }) : super(selectedImages: const []);

  @override
  List<Object?> get props => [refreshedOrder, existingCount];
}

class ShipmentPhotosFailure extends ShipmentPhotosState {
  final String message;

  const ShipmentPhotosFailure({
    required this.message,
    required super.selectedImages,
    required super.existingCount,
  });

  @override
  List<Object?> get props => [message, selectedImages, existingCount];
}
