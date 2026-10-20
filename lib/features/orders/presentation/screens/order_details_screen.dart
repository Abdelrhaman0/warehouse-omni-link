import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/orders_repository.dart';
import '../../models/order_details.dart';
import '../cubits/order_details_cubit.dart';
import '../cubits/order_details_state.dart';
import '../cubits/shipment_photos_cubit.dart';
import '../cubits/waybill_photos_cubit.dart';
import '../widgets/handover_tab_view.dart';
import '../widgets/order_details_header.dart';
import '../widgets/order_details_step_bar.dart';
import '../widgets/order_status_update_sheet.dart';
import '../widgets/packing_tab_view.dart';
import '../widgets/photos_tab_view.dart';
import '../widgets/picking_tab_view.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final int initialTab;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.initialTab = 2,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }


  void _showMoreActionsSheet(BuildContext context, OrderDetails order) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'تحديث حالة الطلب',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showOrderStatusUpdateSheet(context, order);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF2563EB),
                  ),
                  title: const Text(
                    'تحديث البيانات',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.read<OrderDetailsCubit>().refreshOrderDetails();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF64748B),
                  ),
                  title: const Text(
                    'نسخ رقم الطلب',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(order.orderNumber),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Clipboard.setData(ClipboardData(text: order.orderNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ رقم الطلب إلى الحافظة'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          OrderDetailsCubit(ordersRepository: context.read<OrdersRepository>())
            ..loadOrderDetails(widget.orderId),
      child: BlocListener<OrderDetailsCubit, OrderDetailsState>(
        listener: (context, state) {
          if (state is OrderDetailsStatusUpdateFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
          }
        },
        listenWhen: (previous, current) {
          if (previous is OrderDetailsStatusUpdating &&
              current is OrderDetailsLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.statusUpdateSuccess),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
            });
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: Color(0xFF0F172A),
              ),
              tooltip: 'رجوع',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'تفاصيل الطلب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                //  const SizedBox(height: 2),
                //  Text(
                //    _getSubtitleForTab(_selectedTab),
                //   style: const TextStyle(
                //      fontSize: 12,
                //      fontWeight: FontWeight.w500,
                //      color: Color(0xFF64748B),
                //    ),
                // ),
              ],
            ),
            centerTitle: true,
            actions: [
              Builder(
                builder: (ctx) {
                  final state = ctx.watch<OrderDetailsCubit>().state;
                  final OrderDetails? order = switch (state) {
                    OrderDetailsLoaded(:final order) => order,
                    OrderDetailsStatusUpdating(:final order) => order,
                    OrderDetailsStatusUpdateFailure(:final order) => order,
                    _ => null,
                  };

                  if (order == null) return const SizedBox.shrink();

                  return IconButton(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 26,
                      color: Color(0xFF1E3A8A),
                    ),
                    tooltip: 'خيارات إضافية',
                    onPressed: () => _showMoreActionsSheet(ctx, order),
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<OrderDetailsCubit, OrderDetailsState>(
            builder: (context, state) {
              if (state is OrderDetailsLoading) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'جارٍ تحميل تفاصيل الطلب...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              if (state is OrderDetailsFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context
                              .read<OrderDetailsCubit>()
                              .loadOrderDetails(widget.orderId),
                          icon: const Icon(Icons.refresh),
                          label: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final OrderDetails? order = switch (state) {
                OrderDetailsLoaded(:final order) => order,
                OrderDetailsStatusUpdating(:final order) => order,
                OrderDetailsStatusUpdateFailure(:final order) => order,
                _ => null,
              };
              final bool isStatusUpdating = state is OrderDetailsStatusUpdating;

              if (order != null) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (context) => ShipmentPhotosCubit(
                        ordersRepository: context.read<OrdersRepository>(),
                        orderId: order.id,
                        existingPhotosCount: order.shipmentPhotos.length,
                      ),
                    ),
                    BlocProvider(
                      create: (context) => WaybillPhotosCubit(
                        ordersRepository: context.read<OrdersRepository>(),
                        orderId: order.id,
                        existingPhotosCount: order.waybillPhotos.length,
                      ),
                    ),
                  ],
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // 0. Persistent order header
                          OrderDetailsHeader(order: order),

                          // 1. Step Navigation Bar
                          OrderDetailsStepBar(
                            currentStep: _selectedTab,
                            onStepSelected: (index) {
                              setState(() {
                                _selectedTab = index;
                              });
                            },
                          ),

                          // 2. Tab Contents
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () => context
                                  .read<OrderDetailsCubit>()
                                  .refreshOrderDetails(),
                              child: IndexedStack(
                                index: _selectedTab,
                                children: [
                                  // Tab 1: العميل — Customer info + items
                                  PickingTabView(order: order),

                                  // Tab 2: الشحن — Shipping + invoice
                                  PackingTabView(order: order),

                                  // Tab 3: الصور — Photos
                                  PhotosTabView(order: order),

                                  // Tab 4: الملخص — Summary + status button
                                  HandoverTabView(
                                    order: order,
                                    onUpdateStatus: () {
                                      showOrderStatusUpdateSheet(
                                          context, order);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Overlay during status update in-flight
                      if (isStatusUpdating)
                        Positioned.fill(
                          child: AbsorbPointer(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.2),
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 14),
                                    Text(
                                      AppStrings.updatingStatus,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
