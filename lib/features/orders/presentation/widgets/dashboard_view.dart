import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../models/order_status.dart';
import '../cubits/orders_cubit.dart';
import '../cubits/orders_state.dart';
import 'order_status_donut_chart.dart';
import '../../../safes/presentation/widgets/vault_icon.dart';

class DashboardView extends StatelessWidget {
  final VoidCallback onNotificationTap;
  final Function(OrdersTab tab, {String? filterStatus}) onNavigateToOrders;

  const DashboardView({
    super.key,
    required this.onNotificationTap,
    required this.onNavigateToOrders,
  });

  @override
  Widget build(BuildContext context) {
    // Defense-in-depth: Boundary level authorization guard
    AuthCubit? authCubit;
    try {
      authCubit = context.read<AuthCubit>();
    } catch (_) {
      authCubit = null;
    }
    bool isSuperAdmin = false;
    if (authCubit != null) {
      final authState = authCubit.state;
      if (authState is Authenticated) {
        if (!authState.user.canAccessDashboard) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                AppStrings.unauthorizedDashboardAccess,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }
        isSuperAdmin = authState.user.isSuperAdmin;
      }
    }

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
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── A. Existing App Bar / Header: Logo & Title + Notification Bell ──
                Container(
                  color: const Color(0xFF1B3478),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: onNotificationTap,
                            tooltip: 'التنبيهات',
                            icon: const Icon(Icons.notifications_none_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const Spacer(),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('OMNI LINK', style: TextStyle(color: Colors.white,
                                  fontSize: 19, fontWeight: FontWeight.w800)),
                              Text('Store Keeper • مسؤول المخزن', style: TextStyle(
                                  color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('لوحة تحكم المخزن', textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('تابع الطلبات وحركة المخزن من مكان واحد',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white.withValues(alpha: .78),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(children: [
                      _buildSummaryTile('$remainingCount', 'المتبقي',
                          const Color(0xFF294AAB), () => onNavigateToOrders(OrdersTab.open)),
                      const SizedBox(width: 9),
                      _buildSummaryTile('$completedCount', 'المكتمل',
                          const Color(0xFF159B5A), () => onNavigateToOrders(OrdersTab.completed)),
                      const SizedBox(width: 9),
                      _buildSummaryTile('$totalOrders', 'إجمالي الطلبات',
                          AppColors.textPrimary, () => onNavigateToOrders(OrdersTab.open)),
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: OrderStatusDonutChart(
                    items: statItems,
                    totalOrders: totalOrders,
                    onStatusSelected: onNavigateToOrders,
                    onTotalSelected: () => onNavigateToOrders(OrdersTab.open),
                  ),
                ),
                const SizedBox(height: 16),
                // ── D. New Order Status Statistics Card (Donut Chart) ───────────

                // ── E. Preparation Cards Grid ────────────────────────────────────
                // _buildSectionHeader('إحصائيات الطلبات', '$totalOrders طلبًا'),
                // const SizedBox(height: 12),
                // GridView.count(
                //   crossAxisCount: 2,
                //   crossAxisSpacing: 12,
                //   mainAxisSpacing: 12,
                //   shrinkWrap: true,
                //   physics: const NeverScrollableScrollPhysics(),
                //   childAspectRatio: 1.9,
                  // children: [
                  //   _PrepCard(
                  //     label: 'قيد الانتظار',
                  //     subLabel: 'بانتظار بدء التجهيز',
                  //     count: countPending,
                  //     color: AppColors.statusPending,
                  //     icon: Icons.hourglass_empty_rounded,
                  //     onTap: () => onNavigateToOrders(
                  //       OrdersTab.open,
                  //       filterStatus: 'pending',
                  //     ),
                  //   ),
                  //   _PrepCard(
                  //     label: 'مؤكد',
                  //     subLabel: 'تم تأكيد الطلب',
                  //     count: countConfirmed,
                  //     color: AppColors.statusConfirmed,
                  //     icon: Icons.verified_rounded,
                  //     onTap: () => onNavigateToOrders(
                  //       OrdersTab.open,
                  //       filterStatus: 'confirmed',
                  //     ),
                  //   ),
                  //   _PrepCard(
                  //     label: 'قيد التجهيز',
                  //     subLabel: 'جار تجهيز الطلبات',
                  //     count: countProcessing,
                  //     color: AppColors.statusProcessing,
                  //     icon: Icons.sync_rounded,
                  //     onTap: () => onNavigateToOrders(
                  //       OrdersTab.open,
                  //       filterStatus: 'processing',
                  //     ),
                  //   ),
                  //   _PrepCard(
                  //     label: 'تم الشحن',
                  //     subLabel: 'جاهزة للتوصيل',
                  //     count: countShipped,
                  //     color: AppColors.statusShipped,
                  //     icon: Icons.local_shipping_rounded,
                  //     onTap: () => onNavigateToOrders(
                  //       OrdersTab.open,
                  //       filterStatus: 'shipped',
                  //     ),
                  //   ),
                  //   _PrepCard(
                  //     label: 'تم التسليم',
                  //     subLabel: 'وصلت للعميل بنجاح',
                  //     count: countDelivered,
                  //     color: AppColors.statusDelivered,
                  //     icon: Icons.check_circle_outline_rounded,
                  //     onTap: () => onNavigateToOrders(
                  //       OrdersTab.completed,
                  //       filterStatus: 'delivered',
                  //     ),
                  //   ),
                  //   _PrepCard(
                  //     label: 'إلغيت',
                  //     subLabel: 'أُلغيت قبل إتمام التنفيذ',
                  //     count: countCancelled,
                  //     color: AppColors.statusCancelled,
                  //     icon: Icons.cancel_outlined,
                  //     onTap: () => onNavigateToOrders(
                  //       OrdersTab.completed,
                  //       filterStatus: 'cancelled',
                  //     ),
                  //   ),
                  // ],
                // ),
                if (isSuperAdmin) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSafesManagementCard(context),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTile(String value, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFF0F2F6)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(value, style: TextStyle(color: color, fontSize: 23,
                  fontWeight: FontWeight.w800, height: 1.1)),
              const SizedBox(height: 4),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF8491A7), fontSize: 10)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSafesManagementCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4E3FC), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(AppRouter.safes),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Vault icon with deep navy background
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3B8A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const VaultIcon(
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                // Titles
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة الخزن المالية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172554),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'الأرصدة والإيداع والسحب والتحويل',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // End badge and arrow

                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: const Color(0xFF1B3B8A).withValues(alpha: 0.8),
                    ),
              ],
            ),
          ),
        ),
      ),
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
// class _PrepCard extends StatelessWidget {
//   final String label;
//   final String subLabel;
//   final int count;
//   final Color color;
//   final IconData icon;
//   final VoidCallback onTap;
//
//   const _PrepCard({
//     required this.label,
//     required this.subLabel,
//     required this.count,
//     required this.color,
//     required this.icon,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: AppColors.cardBorder, width: 1.2),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.025),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // Count
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     count < 10 ? '0$count' : '$count',
//                     style: TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.w800,
//                       color: AppColors.textPrimary,
//                       height: 1,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     label,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                   Text(
//                     subLabel,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.textSecondary,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Icon badge
//             Container(
//               width: 36,
//               height: 36,
//               decoration: BoxDecoration(
//                 color: color.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Icon(icon, color: color, size: 18),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
