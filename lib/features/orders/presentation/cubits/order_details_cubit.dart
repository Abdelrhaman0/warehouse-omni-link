import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/orders_repository.dart';
import '../../models/order_details.dart';
import 'order_details_state.dart';

class OrderDetailsCubit extends Cubit<OrderDetailsState> {
  final OrdersRepository ordersRepository;
  int? _currentOrderId;

  OrderDetailsCubit({required this.ordersRepository})
      : super(const OrderDetailsInitial());

  int? get currentOrderId => _currentOrderId;

  Future<void> loadOrderDetails(int orderId) async {
    _currentOrderId = orderId;
    emit(const OrderDetailsLoading());

    try {
      final details = await ordersRepository.getOrderDetails(orderId);
      emit(OrderDetailsLoaded(order: details));
    } on Failure catch (e) {
      emit(OrderDetailsFailure(e.message));
    } catch (_) {
      emit(const OrderDetailsFailure(AppStrings.errorOrderDetailsLoad));
    }
  }

  Future<void> refreshOrderDetails() async {
    final orderId = _currentOrderId;
    if (orderId == null) return;

    if (state is OrderDetailsLoaded) {
      emit((state as OrderDetailsLoaded).copyWith(isRefreshing: true));
    }

    try {
      final details = await ordersRepository.getOrderDetails(orderId);
      emit(OrderDetailsLoaded(order: details));
    } on Failure catch (e) {
      // If refresh fails but we already have loaded data, keep loaded data and notify
      if (state is OrderDetailsLoaded) {
        emit((state as OrderDetailsLoaded).copyWith(isRefreshing: false));
      } else {
        emit(OrderDetailsFailure(e.message));
      }
    } catch (_) {
      if (state is OrderDetailsLoaded) {
        emit((state as OrderDetailsLoaded).copyWith(isRefreshing: false));
      } else {
        emit(const OrderDetailsFailure(AppStrings.errorOrderDetailsLoad));
      }
    }
  }

  /// Directly apply freshly fetched OrderDetails (e.g., from successful upload response flow)
  void updateOrder(OrderDetails refreshedOrder) {
    _currentOrderId = refreshedOrder.id;
    emit(OrderDetailsLoaded(order: refreshedOrder));
  }

  /// Sends a PUT request to change the order's status.
  /// While the request is in-flight, emits [OrderDetailsStatusUpdating].
  /// On success, emits [OrderDetailsLoaded] with the refreshed order.
  /// On failure, emits [OrderDetailsStatusUpdateFailure] so the UI can
  /// show an error message while keeping the current order visible.
  ///
  /// For `cancelled` status, [reason] and [restoreStock] must be provided.
  Future<void> updateOrderStatus({
    required OrderDetails currentOrder,
    required String newStatus,
    String? reason,
    bool? restoreStock,
  }) async {
    emit(OrderDetailsStatusUpdating(order: currentOrder));

    try {
      final updated = await ordersRepository.updateOrderStatus(
        orderId: currentOrder.id,
        status: newStatus,
        reason: reason,
        restoreStock: restoreStock,
      );
      _currentOrderId = updated.id;
      emit(OrderDetailsLoaded(order: updated));
    } on Failure catch (e) {
      emit(OrderDetailsStatusUpdateFailure(
        order: currentOrder,
        message: e.message,
      ));
    } catch (_) {
      emit(OrderDetailsStatusUpdateFailure(
        order: currentOrder,
        message: AppStrings.errorStatusUpdate,
      ));
    }
  }
}
