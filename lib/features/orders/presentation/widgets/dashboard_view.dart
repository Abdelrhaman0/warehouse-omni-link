import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../models/order_status.dart';
import '../cubits/orders_cubit.dart';
import '../cubits/orders_state.dart';
import 'order_status_donut_chart.dart';

class DashboardView extends StatelessWidget {
  final VoidCallback onNotificationTap;
  final Function(OrdersTab tab, {String? filterStatus}) onNavigateToOrders;

  const DashboardView({
    super.key,
    required this.onNotificationTap,
    required this.onNavigateToOrders,
  });

  String _getArabicDateString() {
    try {
      final now = DateTime.now();
      final formatter = DateFormat('EEEE، d MMMM y', 'ar');
      return '${formatter.format(now)} • الوردية الصباحية';
    } catch (_) {
      return 'الاثنين، 12 أكتوبر 2026 • الوردية الصباحية';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateString = _getArabicDateString();

    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        final totalOrders = state.totalOrdersCount;
        final remainingCount = state.remainingOrdersCount;
        final completedCount = state.completedOrdersCount;

        // Authoritative counts from backend statistics
        final int countPending = state.getStatusCount('pending');
        final int countConfirmed = state.getStatusCount('confirmed');
        final int countProcessing = state.getStatusCount('processing');
        final int countShipped = state.getStatusCount('shipped');
        final int countDelivered = state.getStatusCount('delivered');
        final int countCancelled = state.getStatusCount('cancelled');

        final standardKeys = {
          'pending',
          'confirmed',
          'processing',
          'shipped',
          'delivered',
          'cancelled',
          'refused_delivery',
        };

        final statItems = <StatusStatItem>[
          StatusStatItem(
            label: 'قيد الانتظار',
            count: countPending,
            color: AppColors.statusPending,
            filterKey: 'pending',
            targetTab: OrdersTab.open,
          ),
          StatusStatItem(
            label: 'مؤكد',
            count: countConfirmed,
            color: AppColors.statusConfirmed,
            filterKey: 'confirmed',
            targetTab: OrdersTab.open,
          ),
          StatusStatItem(
            label: 'قيد التجهيز',
            count: countProcessing,
            color: AppColors.statusProcessing,
            filterKey: 'processing',
            targetTab: OrdersTab.open,
          ),
          StatusStatItem(
            label: 'تم الشحن',
            count: countShipped,
            color: AppColors.statusShipped,
            filterKey: 'shipped',
            targetTab: OrdersTab.open,
          ),
          StatusStatItem(
            label: 'تم التسليم',
            count: countDelivered,
            color: AppColors.statusDelivered,
            filterKey: 'delivered',
            targetTab: OrdersTab.completed,
          ),
          StatusStatItem(
            label: 'إلغيت',
            count: countCancelled,
            color: AppColors.statusCancelled,
            filterKey: 'cancelled',
            targetTab: OrdersTab.completed,
          ),
        ];

        // Safely include any additional backend status entries
        if (state.statistics != null) {
          for (final s in state.statistics!) {
            final key = s.status.trim().toLowerCase();
            if (key == 'total' ||
                standardKeys.contains(key) ||
                OrderStatus.fromString(key) == OrderStatus.cancelled) {
              continue;
            }

            final orderStatus = OrderStatus.fromString(key);
            final label = (s.statusText != null && s.statusText!.isNotEmpty)
                ? s.statusText!
                : s.status;
            final color = orderStatus.color;
            final targetTab = orderStatus.targetTab;

            statItems.add(
              StatusStatItem(
                label: label,
                count: s.count,
                color: color,
                filterKey: key,
                targetTab: targetTab,
              ),
            );
          }
        }

        return RefreshIndicator(
          onRefresh: () => context.read<OrdersCubit>().refreshCurrentTab(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── A. Existing App Bar / Header: Logo & Title + Notification Bell ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Container(
                          //   width: 44,
                          //   height: 44,
                          //   decoration: BoxDecoration(
                          //     color: AppColors.primary,
                          //     borderRadius: BorderRadius.circular(12),
                          //     boxShadow: [
                          //       BoxShadow(
                          //         color: AppColors.primary.withValues(alpha: 0.25),
                          //         blurRadius: 8,
                          //         offset: const Offset(0, 3),
                          //       ),
                          //     ],
                          //   ),
                          //   // child: const Icon(
                          //   //   Icons.inventory_2_rounded,
                          //   //   color: Colors.white,
                          //   //   size: 24,
                          //   // ),
                          // ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أومني لينك',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'أمين المستودع',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Container(
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     shape: BoxShape.circle,
                    //     border: Border.all(color: AppColors.cardBorder),
                    //   ),
                    //   child: IconButton(
                    //     icon: const Icon(
                    //       Icons.notifications_none_rounded,
                    //       color: Color(0xFF2563EB),
                    //       size: 22,
                    //     ),
                    //     onPressed: onNotificationTap,
                    //     tooltip: 'التنبيهات',
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 22),

                // ── B. Welcome Section ─────────────────────────────────────────
                // Text(
                //   'صباح الخير، $userName',
                //   style: const TextStyle(
                //     fontSize: 24,
                //     fontWeight: FontWeight.w800,
                //     color: AppColors.textPrimary,
                //     letterSpacing: -0.3,
                //   ),
                // ),
                const SizedBox(height: 4),
                Text(
                  dateString,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),

                // ── C. Order Summary Card (Deep Blue Card) ──────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Completed orders column (Right in RTL)
                      Expanded(
                        child: InkWell(
                          onTap: () => onNavigateToOrders(OrdersTab.completed),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '$completedCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'طلبات تم الانتهاء منها',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Vertical Divider
                      Container(
                        width: 1,
                        height: 52,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),

                      // Remaining orders column (Left in RTL)
                      Expanded(
                        child: InkWell(
                          onTap: () => onNavigateToOrders(OrdersTab.open),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '$remainingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'طلبات متبقية',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── D. New Order Status Statistics Card (Donut Chart) ───────────
                OrderStatusDonutChart(
                  items: statItems,
                  totalOrders: totalOrders,
                  onStatusSelected: onNavigateToOrders,
                  onTotalSelected: () => onNavigateToOrders(OrdersTab.open),
                ),
                const SizedBox(height: 16),

                // ── E. Preparation Cards Grid ────────────────────────────────────
                _buildSectionHeader('إحصائيات الطلبات', '$totalOrders طلبًا'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.9,
                  children: [
                    _PrepCard(
                      label: 'قيد الانتظار',
                      subLabel: 'بانتظار بدء التجهيز',
                      count: countPending,
                      color: AppColors.statusPending,
                      icon: Icons.hourglass_empty_rounded,
                      onTap: () => onNavigateToOrders(
                        OrdersTab.open,
                        filterStatus: 'pending',
                      ),
                    ),
                    _PrepCard(
                      label: 'مؤكد',
                      subLabel: 'تم تأكيد الطلب',
                      count: countConfirmed,
                      color: AppColors.statusConfirmed,
                      icon: Icons.verified_rounded,
                      onTap: () => onNavigateToOrders(
                        OrdersTab.open,
                        filterStatus: 'confirmed',
                      ),
                    ),
                    _PrepCard(
                      label: 'قيد التجهيز',
                      subLabel: 'جار تجهيز الطلبات',
                      count: countProcessing,
                      color: AppColors.statusProcessing,
                      icon: Icons.sync_rounded,
                      onTap: () => onNavigateToOrders(
                        OrdersTab.open,
                        filterStatus: 'processing',
                      ),
                    ),
                    _PrepCard(
                      label: 'تم الشحن',
                      subLabel: 'جاهزة للتوصيل',
                      count: countShipped,
                      color: AppColors.statusShipped,
                      icon: Icons.local_shipping_rounded,
                      onTap: () => onNavigateToOrders(
                        OrdersTab.open,
                        filterStatus: 'shipped',
                      ),
                    ),
                    _PrepCard(
                      label: 'تم التسليم',
                      subLabel: 'وصلت للعميل بنجاح',
                      count: countDelivered,
                      color: AppColors.statusDelivered,
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () => onNavigateToOrders(
                        OrdersTab.completed,
                        filterStatus: 'delivered',
                      ),
                    ),
                    _PrepCard(
                      label: 'إلغيت',
                      subLabel: 'أُلغيت قبل إتمام التنفيذ',
                      count: countCancelled,
                      color: AppColors.statusCancelled,
                      icon: Icons.cancel_outlined,
                      onTap: () => onNavigateToOrders(
                        OrdersTab.completed,
                        filterStatus: 'cancelled',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preparation card widget
// ─────────────────────────────────────────────────────────────────────────────
class _PrepCard extends StatelessWidget {
  final String label;
  final String subLabel;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _PrepCard({
    required this.label,
    required this.subLabel,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count < 10 ? '0$count' : '$count',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Icon badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
