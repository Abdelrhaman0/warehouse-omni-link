import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../data/orders_repository.dart';
import '../../models/order_status.dart';
import '../../models/order_summary.dart';
import '../../models/paginated_orders.dart';
import 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final OrdersRepository ordersRepository;
  static const int defaultPerPage = AppConstants.defaultPerPage;

  int _openRequestId = 0;
  int _completedRequestId = 0;

  OrdersCubit({required this.ordersRepository}) : super(const OrdersState());

  /// Switch active tab (Open vs Completed).
  /// If the current selected status is incompatible with the new tab,
  /// it is cleared to prevent contradictory queries.
  void switchTab(OrdersTab tab) {
    if (state.currentTab == tab) return;

    final isStatusIncompatible =
        state.selectedStatus != null && state.selectedStatus!.targetTab != tab;
    final newStatus = isStatusIncompatible ? null : state.selectedStatus;

    emit(
      state.copyWith(
        currentTab: tab,
        selectedStatus: newStatus,
        clearStatus: isStatusIncompatible,
      ),
    );

    final targetData = tab == OrdersTab.open
        ? state.openOrders
        : state.completedOrders;
    if ((targetData.orders.isEmpty || isStatusIncompatible) &&
        !targetData.isLoadingInitial &&
        targetData.errorMessage == null) {
      loadInitial(tab);
    }
  }

  /// Change status filter.
  /// Automatically selects the appropriate tab based on the centralized mapping.
  void setStatusFilter(OrderStatus? status) {
    if (state.selectedStatus == status) return;

    final targetTab = status?.targetTab ?? state.currentTab;

    if (targetTab == OrdersTab.open) {
      _openRequestId++;
    } else {
      _completedRequestId++;
    }

    emit(
      state.copyWith(
        currentTab: targetTab,
        selectedStatus: status,
        clearStatus: status == null,
        openOrders: targetTab == OrdersTab.open
            ? const TabOrdersData()
            : state.openOrders,
        completedOrders: targetTab == OrdersTab.completed
            ? const TabOrdersData()
            : state.completedOrders,
      ),
    );

    loadInitial(targetTab);
  }

  /// Change photo filter for Open Orders (All / Needs Photos / With Photos)
  void setOpenPhotosFilter(PhotosFilter filter) {
    if (state.openPhotosFilter == filter) return;
    _openRequestId++;
    emit(
      state.copyWith(
        openPhotosFilter: filter,
        openOrders: const TabOrdersData(),
      ),
    );
    loadInitial(OrdersTab.open);
  }

  /// Initial load for a specific tab or the current active tab
  Future<void> loadInitial([OrdersTab? tab, String? dataType]) async {
    final targetTab = tab ?? state.currentTab;
    final isTabOpen = targetTab == OrdersTab.open;
    final currentData = isTabOpen ? state.openOrders : state.completedOrders;

    if (currentData.isLoadingInitial || currentData.isRefreshing) {
      return;
    }

    final requestId = isTabOpen ? ++_openRequestId : ++_completedRequestId;
    final activeFilter = state.openPhotosFilter;
    final activeStatus = state.selectedStatus;

    _updateTabData(
      targetTab,
      (data) => data.copyWith(isLoadingInitial: true, clearError: true),
    );

    try {
      final PaginatedOrders paginated = isTabOpen
          ? await ordersRepository.getOpenOrders(
              page: 1,
              tab: activeFilter.backendTab,
              status: activeStatus?.apiValue,
              dataType: dataType,
            )
          : await ordersRepository.getCompletedOrders(
              page: 1,
              status: activeStatus?.apiValue,
              dataType: dataType,
            );

      if (_isStale(isTabOpen, requestId, activeFilter, activeStatus)) {
        return;
      }

      final deduplicatedOrders = _deduplicate(paginated.orders);

      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          orders: deduplicatedOrders,
          currentPage: paginated.currentPage,
          lastPage: paginated.lastPage,
          total: paginated.total,
          hasMore: paginated.hasMorePages,
          isLoadingInitial: false,
          clearError: true,
        ),
        statistics: paginated.statistics,
        metaTotal: paginated.statistics != null ? paginated.total : null,
      );
    } on Failure catch (e) {
      if (_isStale(isTabOpen, requestId, activeFilter, activeStatus)) return;
      _updateTabData(
        targetTab,
        (data) =>
            data.copyWith(isLoadingInitial: false, errorMessage: e.message),
      );
    } catch (_) {
      if (_isStale(isTabOpen, requestId, activeFilter, activeStatus)) return;
      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          isLoadingInitial: false,
          errorMessage: 'حدث خطأ أثناء تحميل الطلبات',
        ),
      );
    }
  }

  /// Load next page when scrolling near the bottom or retrying
  Future<void> loadNextPage([OrdersTab? tab, String? dataType]) async {
    final targetTab = tab ?? state.currentTab;
    final isTabOpen = targetTab == OrdersTab.open;
    final currentData = isTabOpen ? state.openOrders : state.completedOrders;

    // Prevent duplicate triggers if already loading, refreshing, or no more pages
    if (currentData.isLoadingMore ||
        currentData.isLoadingInitial ||
        currentData.isRefreshing ||
        !currentData.hasMore) {
      return;
    }

    final requestId = isTabOpen ? _openRequestId : _completedRequestId;
    final activeFilter = state.openPhotosFilter;
    final activeStatus = state.selectedStatus;

    _updateTabData(
      targetTab,
      (data) => data.copyWith(isLoadingMore: true, clearError: true),
    );

    final nextPage = currentData.currentPage + 1;

    try {
      final PaginatedOrders paginated = isTabOpen
          ? await ordersRepository.getOpenOrders(
              page: nextPage,
              tab: activeFilter.backendTab,
              status: activeStatus?.apiValue,
              dataType: dataType,
            )
          : await ordersRepository.getCompletedOrders(
              page: nextPage,
              status: activeStatus?.apiValue,
              dataType: dataType,
            );

      if (_isStale(isTabOpen, requestId, activeFilter, activeStatus)) {
        return;
      }

      // Cleanly de-duplicate orders by stable order id
      final existingIds = currentData.orders.map((o) => o.id).toSet();
      final newUniqueOrders = paginated.orders
          .where((o) => !existingIds.contains(o.id))
          .toList();
      final mergedOrders = List<OrderSummary>.from(currentData.orders)
        ..addAll(newUniqueOrders);

      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          orders: mergedOrders,
          currentPage: paginated.currentPage,
          lastPage: paginated.lastPage,
          total: paginated.total,
          hasMore: paginated.hasMorePages,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      if (_isStale(isTabOpen, requestId, activeFilter, activeStatus)) return;
      _updateTabData(
        targetTab,
        (data) => data.copyWith(isLoadingMore: false, errorMessage: e.message),
      );
    } catch (_) {
      if (_isStale(isTabOpen, requestId, activeFilter, activeStatus)) return;
      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          isLoadingMore: false,
          errorMessage: 'حدث خطأ أثناء تحميل الصفحة التالية',
        ),
      );
    }
  }

  /// Pull-to-refresh: resets pagination and re-fetches first page
  Future<void> refreshCurrentTab({String? dataType}) async {
    final targetTab = state.currentTab;
    final isTabOpen = targetTab == OrdersTab.open;
    final currentData = isTabOpen ? state.openOrders : state.completedOrders;

    if (currentData.isRefreshing) {
      return;
    }

    final requestId = isTabOpen ? ++_openRequestId : ++_completedRequestId;
    final activeFilter = state.openPhotosFilter;
    final activeStatus = state.selectedStatus;

    _updateTabData(
      targetTab,
      (data) => data.copyWith(isRefreshing: true, clearError: true),
    );

    try {
      final PaginatedOrders paginated = isTabOpen
          ? await ordersRepository.getOpenOrders(
              page: 1,
              tab: activeFilter.backendTab,
              status: activeStatus?.apiValue,
              dataType: dataType,
            )
          : await ordersRepository.getCompletedOrders(
              page: 1,
              status: activeStatus?.apiValue,
              dataType: dataType,
            );

      if (_isStale(isTabOpen, requestId, activeFilter, activeStatus)) {
        return;
      }

      final deduplicatedOrders = _deduplicate(paginated.orders);

      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          orders: deduplicatedOrders,
          currentPage: paginated.currentPage,
          lastPage: paginated.lastPage,
          total: paginated.total,
          hasMore: paginated.hasMorePages,
          isRefreshing: false,
          clearError: true,
        ),
        statistics: paginated.statistics,
        metaTotal: paginated.statistics != null ? paginated.total : null,
      );
    } on Failure catch (e) {
      if (_isStale(isTabOpen, requestId, activeFilter, activeStatus)) return;
      _updateTabData(
        targetTab,
        (data) => data.copyWith(isRefreshing: false, errorMessage: e.message),
      );
    } catch (_) {
      if (_isStale(isTabOpen, requestId, activeFilter, activeStatus)) return;
      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          isRefreshing: false,
          errorMessage: 'حدث خطأ أثناء تحديث الطلبات',
        ),
      );
    }
  }

  bool _isStale(
    bool isTabOpen,
    int requestId,
    PhotosFilter activeFilter,
    OrderStatus? activeStatus,
  ) {
    if (state.selectedStatus != activeStatus) return true;
    if (isTabOpen) {
      return requestId != _openRequestId ||
          state.openPhotosFilter != activeFilter;
    } else {
      return requestId != _completedRequestId;
    }
  }

  List<OrderSummary> _deduplicate(List<OrderSummary> orders) {
    final seen = <int>{};
    final unique = <OrderSummary>[];
    for (final order in orders) {
      if (seen.add(order.id)) {
        unique.add(order);
      }
    }
    return unique;
  }

  void _updateTabData(
    OrdersTab tab,
    TabOrdersData Function(TabOrdersData current) update, {
    List<OrderStatusStatistic>? statistics,
    int? metaTotal,
  }) {
    final newStats = statistics ?? state.statistics;
    final newMetaTotal = metaTotal ?? state.metaTotal;

    if (tab == OrdersTab.open) {
      emit(
        state.copyWith(
          openOrders: update(state.openOrders),
          statistics: newStats,
          metaTotal: newMetaTotal,
        ),
      );
    } else {
      emit(
        state.copyWith(
          completedOrders: update(state.completedOrders),
          statistics: newStats,
          metaTotal: newMetaTotal,
        ),
      );
    }
  }

  /// Reset all orders, tabs, and dashboard statistics state (e.g. on logout or session expiration).
  /// Guarantees that no stale dashboard statistics or cached orders leak across sessions.
  void reset() {
    _openRequestId++;
    _completedRequestId++;
    emit(const OrdersState());
  }
}
