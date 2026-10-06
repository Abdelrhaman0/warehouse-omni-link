import 'package:equatable/equatable.dart';
import '../../models/order_summary.dart';

enum OrdersTab { open, completed }

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
  final bool hasMore;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? errorMessage;

  const TabOrdersData({
    this.orders = const [],
    this.currentPage = 1,
    this.lastPage = 1,
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
  final TabOrdersData openOrders;
  final TabOrdersData completedOrders;

  const OrdersState({
    this.currentTab = OrdersTab.open,
    this.openPhotosFilter = PhotosFilter.all,
    this.openOrders = const TabOrdersData(),
    this.completedOrders = const TabOrdersData(),
  });

  TabOrdersData get currentTabData =>
      currentTab == OrdersTab.open ? openOrders : completedOrders;

  OrdersState copyWith({
    OrdersTab? currentTab,
    PhotosFilter? openPhotosFilter,
    TabOrdersData? openOrders,
    TabOrdersData? completedOrders,
  }) {
    return OrdersState(
      currentTab: currentTab ?? this.currentTab,
      openPhotosFilter: openPhotosFilter ?? this.openPhotosFilter,
      openOrders: openOrders ?? this.openOrders,
      completedOrders: completedOrders ?? this.completedOrders,
    );
  }

  @override
  List<Object?> get props => [
        currentTab,
        openPhotosFilter,
        openOrders,
        completedOrders,
      ];
}
