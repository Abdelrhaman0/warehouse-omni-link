import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../models/order_status.dart';
import '../../models/order_summary.dart';
import '../cubits/orders_cubit.dart';
import '../cubits/orders_state.dart';
import '../widgets/dashboard_view.dart';
import '../widgets/order_card.dart';
import 'order_details_screen.dart';

class HomeOrdersScreen extends StatefulWidget {
  final int initialNavIndex;

  const HomeOrdersScreen({super.key, this.initialNavIndex = 1});

  @override
  State<HomeOrdersScreen> createState() => _HomeOrdersScreenState();
}

class _HomeOrdersScreenState extends State<HomeOrdersScreen>
    with SingleTickerProviderStateMixin {
  late int _currentNavIndex;
  late TabController _tabController;
  final ScrollController _openScrollController = ScrollController();
  final ScrollController _completedScrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _canAccessDashboard(BuildContext context) {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        return authState.user.canAccessDashboard;
      }
    } catch (_) {}
    return false;
  }

  @override
  void initState() {
    super.initState();
    final canAccess = _canAccessDashboard(context);
    if (!canAccess && widget.initialNavIndex == 0) {
      _currentNavIndex = 1;
    } else {
      _currentNavIndex = widget.initialNavIndex;
    }
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final canAccess = _canAccessDashboard(context);
      if (canAccess) {
        context.read<OrdersCubit>().loadInitial(OrdersTab.open);
        context.read<OrdersCubit>().loadInitial(OrdersTab.completed);
      } else {
        context.read<OrdersCubit>().loadInitial(OrdersTab.open);
      }
    });

    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (!_tabController.indexIsChanging) {
        final tab = _tabController.index == 0
            ? OrdersTab.open
            : OrdersTab.completed;
        if (context.read<OrdersCubit>().state.currentTab != tab) {
          context.read<OrdersCubit>().switchTab(tab);
        }
      }
    });

    _openScrollController.addListener(() {
      _onScroll(_openScrollController, OrdersTab.open);
    });

    _completedScrollController.addListener(() {
      _onScroll(_completedScrollController, OrdersTab.completed);
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  void _onScroll(ScrollController controller, OrdersTab tab) {
    if (!controller.hasClients) return;
    final cubit = context.read<OrdersCubit>();
    final data = tab == OrdersTab.open
        ? cubit.state.openOrders
        : cubit.state.completedOrders;
    if (data.errorMessage != null || data.isLoadingMore || !data.hasMore)
      return;

    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    if (maxScroll - currentScroll <= 250) {
      cubit.loadNextPage(tab);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _openScrollController.dispose();
    _completedScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleNavigateFromDashboard(OrdersTab tab, {String? filterStatus}) {
    setState(() {
      _currentNavIndex = 1; // Switch to Orders tab
    });
    final status = filterStatus != null
        ? OrderStatus.fromString(filterStatus)
        : null;
    if (status != null) {
      context.read<OrdersCubit>().setStatusFilter(status);
    } else {
      context.read<OrdersCubit>().switchTab(tab);
    }
  }

  void _openStatusFilterSheet(
    BuildContext context,
    OrderStatus? currentStatus,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.8;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'تصفية حسب الحالة',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.all_inclusive_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('كل الحالات'),
                    trailing: currentStatus == null
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      context.read<OrdersCubit>().setStatusFilter(null);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ...OrderStatus.values
                      .where((s) => s != OrderStatus.unknown)
                      .map((status) {
                        final isSelected = currentStatus == status;
                        return ListTile(
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(status.localizedLabel),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () {
                            context.read<OrdersCubit>().setStatusFilter(status);
                            Navigator.of(ctx).pop();
                          },
                        );
                      }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAccess = _canAccessDashboard(context);

    // Guard against unauthorized dashboard access
    if (!canAccess && _currentNavIndex == 0) {
      _currentNavIndex = 1;
    }

    final bottomNavItems = canAccess
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'الطلبات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'حسابي',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'الطلبات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'حسابي',
            ),
          ];

    final bottomNavCurrentIndex = canAccess
        ? _currentNavIndex.clamp(0, 2)
        : (_currentNavIndex == 2 ? 1 : 0);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            // 0: Dashboard (Screen 1)
            DashboardView(
              onNotificationTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لا توجد تنبيهات جديدة'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              onNavigateToOrders: _handleNavigateFromDashboard,
            ),

            // 1: Orders Management (Screen 2)
            _buildOrdersTab(context),

            // 2: Profile Screen
            _buildProfileTab(context),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: bottomNavCurrentIndex,
          onTap: (index) {
            setState(() {
              if (canAccess) {
                _currentNavIndex = index;
              } else {
                _currentNavIndex = index == 0 ? 1 : 2;
              }
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: bottomNavItems,
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    AuthRepository? authRepo;
    try {
      authRepo = context.read<AuthRepository>();
    } catch (_) {
      authRepo = null;
    }
    if (authRepo == null) {
      return const Center(child: Text(AppStrings.profile));
    }
    return const ProfileScreen();
  }

  Widget _buildOrdersTab(BuildContext context) {
    return BlocConsumer<OrdersCubit, OrdersState>(
      listener: (context, state) {
        final targetIndex = state.currentTab == OrdersTab.open ? 0 : 1;
        if (_tabController.index != targetIndex) {
          _tabController.animateTo(targetIndex);
        }
      },
      builder: (context, state) {
        final isOpenTab = state.currentTab == OrdersTab.open;
        return Column(
          children: [
            // ── 1. Title row: "الطلبات" on right, status dropdown on left ──
            _buildTitleRow(context, state.selectedStatus),

            const SizedBox(height: 12),

            // ── 2. Full-width search field ──────────────────────────────
            _buildSearchField(),

            const SizedBox(height: 12),

            // ── 3. Open/completed tabs with thin blue underline ─────────
            _buildTabsRow(),

            // ── 4. Photography filters (compact RTL row) ────────────────
            if (isOpenTab) ...[
              const SizedBox(height: 12),
              _buildPhotographyFilters(state.openPhotosFilter),
            ],

            const SizedBox(height: 6),

            // ── 5. Orders TabView Body ──────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(
                    tabData: state.openOrders,
                    scrollController: _openScrollController,
                    emptyMessage: AppStrings.noOpenOrders,
                    tab: OrdersTab.open,
                    selectedStatus: state.selectedStatus,
                  ),
                  _buildOrdersList(
                    tabData: state.completedOrders,
                    scrollController: _completedScrollController,
                    emptyMessage: AppStrings.noCompletedOrders,
                    tab: OrdersTab.completed,
                    selectedStatus: state.selectedStatus,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitleRow(BuildContext context, OrderStatus? selectedStatus) {
    final statusLabel = selectedStatus != null
        ? selectedStatus.localizedLabel
        : 'كل الحالات';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title: "الطلبات" (start in RTL => right side)
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'الطلبات',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Status Dropdown (compact outlined button, end in RTL => left side)
            Semantics(
              button: true,
              label: 'تصفية حسب الحالة: $statusLabel',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openStatusFilterSheet(context, selectedStatus),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: _searchController,
          textDirection: TextDirection.rtl,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'رقم الطلب أو اسم العميل',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.cardBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.cardBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabsRow() {
    return SizedBox(
      height: 46,
      child: TabBar(
        controller: _tabController,
        tabAlignment: TabAlignment.fill,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 2.5),
        ),
        dividerColor: AppColors.cardBorder,
        dividerHeight: 1.0,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(AppStrings.openOrders, maxLines: 1),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(AppStrings.completedOrders, maxLines: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotographyFilters(PhotosFilter currentFilter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 36,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: PhotosFilter.values.map((filter) {
              final isSelected = filter == currentFilter;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: filter.label,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.read<OrdersCubit>().setOpenPhotosFilter(filter);
                        if (_tabController.index != 0) {
                          _tabController.animateTo(0);
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 14 : 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.infoBg
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              filter.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _normalizeSearchText(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var text = input;
    for (int i = 0; i < arabicDigits.length; i++) {
      text = text.replaceAll(arabicDigits[i], '$i');
    }
    return text.toLowerCase().trim();
  }

  List<OrderSummary> _applyLocalFilters(
    List<OrderSummary> orders,
    OrderStatus? selectedStatus,
  ) {
    var result = orders;
    if (_searchQuery.isNotEmpty) {
      final normalizedQuery = _normalizeSearchText(_searchQuery);
      result = result.where((o) {
        final normalizedOrderNumber = _normalizeSearchText(o.orderNumber);
        final normalizedCustomerName = _normalizeSearchText(o.customerName);
        return normalizedOrderNumber.contains(normalizedQuery) ||
            normalizedCustomerName.contains(normalizedQuery);
      }).toList();
    }
    if (selectedStatus != null) {
      result = result.where((o) => o.status == selectedStatus).toList();
    }
    return result;
  }

  Widget _buildOrdersList({
    required TabOrdersData tabData,
    required ScrollController scrollController,
    required String emptyMessage,
    required OrdersTab tab,
    required OrderStatus? selectedStatus,
  }) {
    final filteredOrders = _applyLocalFilters(tabData.orders, selectedStatus);

    Widget content;
    if (tabData.isLoadingInitial) {
      content = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'جارٍ تحميل الطلبات...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    } else if (tabData.errorMessage != null && tabData.orders.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                tabData.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.read<OrdersCubit>().loadInitial(tab),
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: () => context.read<OrdersCubit>().refreshCurrentTab(),
        child: filteredOrders.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 56,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            emptyMessage,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            AppStrings.pullToRefresh,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : ListView.separated(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount:
                    filteredOrders.length +
                    (tabData.isLoadingMore ||
                            tabData.errorMessage != null ||
                            (!tabData.hasMore && tabData.orders.isNotEmpty)
                        ? 1
                        : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == filteredOrders.length) {
                    return _buildPaginationLoader(tabData, tab);
                  }

                  final order = filteredOrders[index];
                  return OrderCard(
                    order: order,
                    onStatusUpdated: () {
                      if (mounted) {
                        context.read<OrdersCubit>().refreshCurrentTab();
                      }
                    },
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final cubit = context.read<OrdersCubit>();
                      await navigator.push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(orderId: order.id),
                        ),
                      );
                      if (mounted) {
                        cubit.refreshCurrentTab();
                      }
                    },
                  );
                },
              ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'طلبات المستودع',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${filteredOrders.length} من ${tabData.orders.length} طلبًا',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildPaginationLoader(TabOrdersData tabData, OrdersTab tab) {
    if (tabData.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(height: 8),
              Text(
                AppStrings.loadingMore,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (tabData.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: () => context.read<OrdersCubit>().loadNextPage(tab),
            icon: const Icon(Icons.refresh, size: 16),
            label: Text('${AppStrings.retry} (${tabData.errorMessage})'),
          ),
        ),
      );
    }

    if (!tabData.hasMore && tabData.orders.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 32, height: 1, color: AppColors.cardBorder),
              const SizedBox(width: 8),
              const Text(
                AppStrings.noMoreOrders,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 32, height: 1, color: AppColors.cardBorder),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
