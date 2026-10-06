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
}
