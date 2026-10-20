import 'package:equatable/equatable.dart';

import '../../models/order_status.dart';
import '../../models/order_status_statistic.dart';
import '../../models/order_summary.dart';
import '../../models/orders_tab.dart';

export '../../models/order_status_statistic.dart';
export '../../models/orders_tab.dart';

enum PhotosFilter {
  all,
  withoutPhotos,
  withPhotos;

  String get backendTab {
    switch (this) {
      case PhotosFilter.all:
        return 'pending';
      case PhotosFilter.withoutPhotos:
        return 'without_photos';
      case PhotosFilter.withPhotos:
        return 'with_photos';
    }
  }

  String get label {
    switch (this) {
      case PhotosFilter.all:
        return 'الكل';
      case PhotosFilter.withoutPhotos:
        return 'تحتاج تصوير';
      case PhotosFilter.withPhotos:
        return 'تم تصويرها';
    }
  }
}

class TabOrdersData extends Equatable {
  final List<OrderSummary> orders;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? errorMessage;

  const TabOrdersData({
    this.orders = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.hasMore = false,
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  TabOrdersData copyWith({
    List<OrderSummary>? orders,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? hasMore,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TabOrdersData(
      orders: orders ?? this.orders,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    orders,
    currentPage,
    lastPage,
    total,
    hasMore,
    isLoadingInitial,
    isLoadingMore,
    isRefreshing,
    errorMessage,
  ];
}

class OrdersState extends Equatable {
  final OrdersTab currentTab;
  final PhotosFilter openPhotosFilter;
  final OrderStatus? selectedStatus;
  final TabOrdersData openOrders;
  final TabOrdersData completedOrders;
  final List<OrderStatusStatistic>? statistics;
  final int? metaTotal;

  const OrdersState({
    this.currentTab = OrdersTab.open,
    this.openPhotosFilter = PhotosFilter.all,
    this.selectedStatus,
    this.openOrders = const TabOrdersData(),
    this.completedOrders = const TabOrdersData(),
    this.statistics,
    this.metaTotal,
  });

  TabOrdersData get currentTabData =>
      currentTab == OrdersTab.open ? openOrders : completedOrders;

  OrdersState copyWith({
    OrdersTab? currentTab,
    PhotosFilter? openPhotosFilter,
    OrderStatus? selectedStatus,
    bool clearStatus = false,
    TabOrdersData? openOrders,
    TabOrdersData? completedOrders,
    List<OrderStatusStatistic>? statistics,
    bool clearStatistics = false,
    int? metaTotal,
    bool clearMetaTotal = false,
  }) {
    return OrdersState(
      currentTab: currentTab ?? this.currentTab,
      openPhotosFilter: openPhotosFilter ?? this.openPhotosFilter,
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      openOrders: openOrders ?? this.openOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      statistics: clearStatistics ? null : (statistics ?? this.statistics),
      metaTotal: clearMetaTotal ? null : (metaTotal ?? this.metaTotal),
    );
  }

  /// Total orders count following the required fallback priority:
  /// 1. Find the statistics entry whose status is exactly 'total'.
  /// 2. If that entry exists and its count is valid, display its count.
  /// 3. If it is missing or unusable, fall back to the pagination metadata's meta.total.
  /// 4. If neither source provides a valid value, follow the application's safe fallback behavior.
  int get totalOrdersCount {
    if (statistics != null) {
      for (final stat in statistics!) {
        if (stat.status.trim().toLowerCase() == 'total') {
          if (stat.isValidCount) {
            return stat.count;
          }
          break;
        }
      }
    }

    if (metaTotal != null && metaTotal! >= 0) {
      return metaTotal!;
    }
    if (openOrders.total > 0 || completedOrders.total > 0) {
      return openOrders.total > 0 ? openOrders.total : completedOrders.total;
    }

    return openOrders.orders.length + completedOrders.orders.length;
  }

  /// Authoritative count for a given status identifier from backend statistics.
  /// Matches by backend status identifier (case-insensitive).
  /// If missing or if statistics are null, returns 0.
  int getStatusCount(String statusKey) {
    if (statistics != null) {
      final normalizedKey = statusKey.trim().toLowerCase();
      if (normalizedKey == 'cancelled') {
        int total = 0;
        for (final stat in statistics!) {
          final k = stat.status.trim().toLowerCase();
          if (k == 'cancelled' ||
              k == 'refused_delivery' ||
              OrderStatus.fromString(k) == OrderStatus.cancelled) {
            total += stat.count;
          }
        }
        return total;
      }
      for (final stat in statistics!) {
        if (stat.status.trim().toLowerCase() == normalizedKey) {
          return stat.count;
        }
      }
      return 0;
    }
    return 0;
  }

  /// Total completed orders calculated authoritatively from statistics.
  /// Completed = delivered + cancelled (+ refused_delivery if present).
  int get completedOrdersCount {
    if (statistics != null) {
      int count = 0;
      for (final s in statistics!) {
        final key = s.status.trim().toLowerCase();
        if (key == 'total') continue;
        final st = OrderStatus.fromString(key);
        if (st.targetTab == OrdersTab.completed || key == 'refused_delivery') {
          count += s.count;
        }
      }
      return count;
    }
    if (completedOrders.total > 0) {
      return completedOrders.total;
    }
    return completedOrders.orders.length;
  }

  /// Total remaining (open) orders calculated authoritatively from statistics.
  /// Open = pending + confirmed + processing + shipped.
  int get remainingOrdersCount {
    if (statistics != null) {
      int count = 0;
      for (final s in statistics!) {
        final key = s.status.trim().toLowerCase();
        if (key == 'total') continue;
        final st = OrderStatus.fromString(key);
        if (st.targetTab == OrdersTab.open) {
          count += s.count;
        }
      }
      return count;
    }
    if (openOrders.total > 0) {
      return openOrders.total;
    }
    return openOrders.orders.length;
  }

  @override
  List<Object?> get props => [
    currentTab,
    openPhotosFilter,
    selectedStatus,
    openOrders,
    completedOrders,
    statistics,
    metaTotal,
  ];
}
