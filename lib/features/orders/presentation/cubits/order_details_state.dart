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
