import 'order_status.dart';
import 'orders_tab.dart';

/// Centralized mapper that determines the correct tab for each supported backend order status.
class OrderStatusTabMapper {
  OrderStatusTabMapper._();

  /// Returns the corresponding [OrdersTab] for a given [OrderStatus].
  ///
  /// Verified business rules:
  /// - [OrderStatus.pending] -> [OrdersTab.open]
  /// - [OrderStatus.confirmed] -> [OrdersTab.open]
  /// - [OrderStatus.processing] -> [OrdersTab.open]
  /// - [OrderStatus.shipped] -> [OrdersTab.open]
  /// - [OrderStatus.delivered] -> [OrdersTab.completed]
  /// - [OrderStatus.cancelled] -> [OrdersTab.completed]
  /// - [OrderStatus.unknown] -> [OrdersTab.open]
  static OrdersTab getTabForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.processing:
      case OrderStatus.shipped:
        return OrdersTab.open;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return OrdersTab.completed;
      case OrderStatus.unknown:
        return OrdersTab.open;
    }
  }

  /// Checks whether a given [status] is compatible with a given [tab].
  static bool isStatusCompatibleWithTab(OrderStatus status, OrdersTab tab) {
    return getTabForStatus(status) == tab;
  }
}
