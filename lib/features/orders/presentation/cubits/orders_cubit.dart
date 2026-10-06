import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../data/orders_repository.dart';
import '../../models/order_summary.dart';
import '../../models/paginated_orders.dart';
import 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final OrdersRepository ordersRepository;
  static const int defaultPerPage = AppConstants.defaultPerPage;

  OrdersCubit({required this.ordersRepository})
      : super(const OrdersState());

  /// Switch active tab (Open vs Completed)
  void switchTab(OrdersTab tab) {
    if (state.currentTab == tab) return;
    emit(state.copyWith(currentTab: tab));

    // If selected tab has not been loaded yet, load it
    final targetData = tab == OrdersTab.open ? state.openOrders : state.completedOrders;
    if (targetData.orders.isEmpty && !targetData.isLoadingInitial) {
      loadInitial(tab);
    }
  }

  /// Change photo filter for Open Orders (All / Needs Photos / With Photos)
  void setOpenPhotosFilter(PhotosFilter filter) {
    if (state.openPhotosFilter == filter) return;
    emit(state.copyWith(
      openPhotosFilter: filter,
      openOrders: const TabOrdersData(),
    ));
    loadInitial(OrdersTab.open);
  }

  /// Initial load for a specific tab or the current active tab
  Future<void> loadInitial([OrdersTab? tab]) async {
    final targetTab = tab ?? state.currentTab;
    final isTabOpen = targetTab == OrdersTab.open;

    _updateTabData(
      targetTab,
      (data) => data.copyWith(
        isLoadingInitial: true,
        clearError: true,
      ),
    );

    try {
      final PaginatedOrders paginated = isTabOpen
          ? await ordersRepository.getOpenOrders(
              page: 1,
              tab: state.openPhotosFilter.backendTab,
            )
          : await ordersRepository.getCompletedOrders(page: 1);

      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          orders: paginated.orders,
          currentPage: paginated.currentPage,
          lastPage: paginated.lastPage,
          hasMore: paginated.hasMorePages,
          isLoadingInitial: false,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          isLoadingInitial: false,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          isLoadingInitial: false,
          errorMessage: 'حدث خطأ أثناء تحميل الطلبات',
        ),
      );
    }
  }

  /// Load next page when scrolling near the bottom
  Future<void> loadNextPage([OrdersTab? tab]) async {
    final targetTab = tab ?? state.currentTab;
    final currentData = targetTab == OrdersTab.open ? state.openOrders : state.completedOrders;

    // Prevent duplicate triggers if already loading or no more pages
    if (currentData.isLoadingMore ||
        currentData.isLoadingInitial ||
        !currentData.hasMore) {
      return;
    }

    _updateTabData(
      targetTab,
      (data) => data.copyWith(isLoadingMore: true, clearError: true),
    );

    final nextPage = currentData.currentPage + 1;
    final isTabOpen = targetTab == OrdersTab.open;

    try {
      final PaginatedOrders paginated = isTabOpen
          ? await ordersRepository.getOpenOrders(
              page: nextPage,
              tab: state.openPhotosFilter.backendTab,
            )
          : await ordersRepository.getCompletedOrders(page: nextPage);

      // Cleanly de-duplicate orders by id
      final existingIds = currentData.orders.map((o) => o.id).toSet();
      final newUniqueOrders = paginated.orders.where((o) => !existingIds.contains(o.id)).toList();
      final mergedOrders = List<OrderSummary>.from(currentData.orders)..addAll(newUniqueOrders);

      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          orders: mergedOrders,
          currentPage: paginated.currentPage,
          lastPage: paginated.lastPage,
          hasMore: paginated.hasMorePages,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          isLoadingMore: false,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
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
  Future<void> refreshCurrentTab() async {
    final targetTab = state.currentTab;
    final isTabOpen = targetTab == OrdersTab.open;

    _updateTabData(
      targetTab,
      (data) => data.copyWith(isRefreshing: true, clearError: true),
    );

    try {
      final PaginatedOrders paginated = isTabOpen
          ? await ordersRepository.getOpenOrders(
              page: 1,
              tab: state.openPhotosFilter.backendTab,
            )
          : await ordersRepository.getCompletedOrders(page: 1);

      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          orders: paginated.orders,
          currentPage: paginated.currentPage,
          lastPage: paginated.lastPage,
          hasMore: paginated.hasMorePages,
          isRefreshing: false,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          isRefreshing: false,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      _updateTabData(
        targetTab,
        (data) => data.copyWith(
          isRefreshing: false,
          errorMessage: 'حدث خطأ أثناء تحديث الطلبات',
        ),
      );
    }
  }

  void _updateTabData(
    OrdersTab tab,
    TabOrdersData Function(TabOrdersData current) update,
  ) {
    if (tab == OrdersTab.open) {
      emit(state.copyWith(openOrders: update(state.openOrders)));
    } else {
      emit(state.copyWith(completedOrders: update(state.completedOrders)));
    }
  }
}
