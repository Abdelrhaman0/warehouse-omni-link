import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../cubits/orders_cubit.dart';
import '../cubits/orders_state.dart';
import '../widgets/order_card.dart';
import 'order_details_screen.dart';

class HomeOrdersScreen extends StatefulWidget {
  const HomeOrdersScreen({super.key});

  @override
  State<HomeOrdersScreen> createState() => _HomeOrdersScreenState();
}

class _HomeOrdersScreenState extends State<HomeOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _openScrollController = ScrollController();
  final ScrollController _completedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial fetch for open orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersCubit>().loadInitial(OrdersTab.open);
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tab = _tabController.index == 0 ? OrdersTab.open : OrdersTab.completed;
        context.read<OrdersCubit>().switchTab(tab);
      }
    });

    _openScrollController.addListener(() {
      _onScroll(_openScrollController, OrdersTab.open);
    });

    _completedScrollController.addListener(() {
      _onScroll(_completedScrollController, OrdersTab.completed);
    });
  }

  void _onScroll(ScrollController controller, OrdersTab tab) {
    if (!controller.hasClients) return;
    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    // Trigger load when 200px from the bottom
    if (maxScroll - currentScroll <= 200) {
      context.read<OrdersCubit>().loadNextPage(tab);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _openScrollController.dispose();
    _completedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(AppStrings.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: AppStrings.profile,
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              tabAlignment: TabAlignment.fill,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt_rounded, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          AppStrings.openOrders,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.task_alt_outlined, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          AppStrings.completedOrders,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(
                tabData: state.openOrders,
                scrollController: _openScrollController,
                emptyMessage: AppStrings.noOpenOrders,
                tab: OrdersTab.open,
                openPhotosFilter: state.openPhotosFilter,
              ),
              _buildOrdersList(
                tabData: state.completedOrders,
                scrollController: _completedScrollController,
                emptyMessage: AppStrings.noCompletedOrders,
                tab: OrdersTab.completed,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhotoFilterChips(PhotosFilter currentFilter) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: PhotosFilter.values.map((filter) {
            final isSelected = filter == currentFilter;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilterChip(
                selected: isSelected,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
                label: Text(
                  filter.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  ),
                ),
                onSelected: (_) {
                  context.read<OrdersCubit>().setOpenPhotosFilter(filter);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersList({
    required TabOrdersData tabData,
    required ScrollController scrollController,
    required String emptyMessage,
    required OrdersTab tab,
    PhotosFilter? openPhotosFilter,
  }) {
    final showFilterChips = tab == OrdersTab.open;

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
        child: tabData.orders.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                padding: const EdgeInsets.all(16),
                itemCount: tabData.orders.length + (tabData.hasMore ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == tabData.orders.length) {
                    return _buildPaginationLoader(tabData, tab);
                  }

                  final order = tabData.orders[index];
                  return OrderCard(
                    order: order,
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final cubit = context.read<OrdersCubit>();
                      await navigator.push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(orderId: order.id),
                        ),
                      );
                      // Refresh order list on return so photo counts/status reflect any external or local changes
                      if (mounted) {
                        cubit.refreshCurrentTab();
                      }
                    },
                  );
                },
              ),
      );
    }

    if (showFilterChips) {
      return Column(
        children: [
          _buildPhotoFilterChips(openPhotosFilter ?? PhotosFilter.all),
          Expanded(child: content),
        ],
      );
    }

    return content;
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
          child: TextButton.icon(
            onPressed: () => context.read<OrdersCubit>().loadNextPage(tab),
            icon: const Icon(Icons.refresh, size: 16),
            label: Text('${AppStrings.retry} (${tabData.errorMessage})'),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
