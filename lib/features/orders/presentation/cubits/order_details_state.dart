import 'package:equatable/equatable.dart';
import '../../models/order_details.dart';

abstract class OrderDetailsState extends Equatable {
  const OrderDetailsState();

  @override
  List<Object?> get props => [];
}

class OrderDetailsInitial extends OrderDetailsState {
  const OrderDetailsInitial();
}

class OrderDetailsLoading extends OrderDetailsState {
  const OrderDetailsLoading();
}

class OrderDetailsLoaded extends OrderDetailsState {
  final OrderDetails order;
  final bool isRefreshing;

  const OrderDetailsLoaded({
    required this.order,
    this.isRefreshing = false,
  });

  OrderDetailsLoaded copyWith({
    OrderDetails? order,
    bool? isRefreshing,
  }) {
    return OrderDetailsLoaded(
      order: order ?? this.order,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [order, isRefreshing];
}

class OrderDetailsFailure extends OrderDetailsState {
  final String message;
  const OrderDetailsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Emitted while a status-update PATCH request is in flight.
/// [order] holds the current data so the UI remains visible.
class OrderDetailsStatusUpdating extends OrderDetailsState {
  final OrderDetails order;
  const OrderDetailsStatusUpdating({required this.order});

  @override
  List<Object?> get props => [order];
}

/// Emitted when the status-update request fails.
/// UI can show a SnackBar / dialog and remain on the loaded screen.
class OrderDetailsStatusUpdateFailure extends OrderDetailsState {
  final OrderDetails order;
  final String message;
  const OrderDetailsStatusUpdateFailure({
    required this.order,
    required this.message,
  });

  @override
  List<Object?> get props => [order, message];
}
