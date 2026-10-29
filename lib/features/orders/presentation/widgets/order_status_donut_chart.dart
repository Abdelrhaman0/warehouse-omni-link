import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../cubits/orders_state.dart';

class StatusStatItem {
  final String label;
  final int count;
  final Color color;
  final String? filterKey;
  final OrdersTab targetTab;

  const StatusStatItem({
    required this.label,
    required this.count,
    required this.color,
    this.filterKey,
    required this.targetTab,
  });
}

class OrderStatusDonutChart extends StatefulWidget {
  final List<StatusStatItem> items;
  final int totalOrders;
  final Function(OrdersTab tab, {String? filterStatus}) onStatusSelected;
  final VoidCallback onTotalSelected;

  const OrderStatusDonutChart({
    super.key,
    required this.items,
    required this.totalOrders,
    required this.onStatusSelected,
    required this.onTotalSelected,
  });

  @override
  State<OrderStatusDonutChart> createState() => _OrderStatusDonutChartState();
}

class _OrderStatusDonutChartState extends State<OrderStatusDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _hoveredOrSelectedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant OrderStatusDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalOrders != widget.totalOrders) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapOnChart(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final outerRadius = size.width / 2;
    const strokeWidth = 18.0;
    final innerRadius = outerRadius - strokeWidth;

    // Tapped the center text (total orders)
    if (distance < innerRadius) {
      widget.onTotalSelected();
      return;
    }

    // Tapped inside the ring
    if (distance >= innerRadius && distance <= outerRadius + 8) {
      if (widget.totalOrders <= 0) return;

      var angle = math.atan2(dy, dx);
      // Normalize to [0, 2*pi), starting from top (-pi/2)
      var normalized = angle + math.pi / 2;
      if (normalized < 0) {
        normalized += 2 * math.pi;
      }

      double currentAngle = 0;
      for (int i = 0; i < widget.items.length; i++) {
        final item = widget.items[i];
        if (item.count <= 0) continue;
        final sweep = (item.count / widget.totalOrders) * (2 * math.pi);
        if (normalized >= currentAngle && normalized <= currentAngle + sweep) {
          setState(() {
            _hoveredOrSelectedIndex = (_hoveredOrSelectedIndex == i) ? null : i;
          });
          widget.onStatusSelected(item.targetTab, filterStatus: item.filterKey);
          return;
        }
        currentAngle += sweep;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalOrders;
    const chartSize = 130.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          const Text(
            'إحصائيات حالات الطلبات',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'توزيع جميع الطلبات',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Centered chart followed by full-width, readable status rows.
          Center(
            child: SizedBox(
                width: chartSize,
                height: chartSize,
                child: GestureDetector(
                  onTapUp: (details) {
                    _handleTapOnChart(
                      details.localPosition,
                      const Size(chartSize, chartSize),
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(chartSize, chartSize),
                            painter: _DonutChartPainter(
                              items: widget.items,
                              totalOrders: total,
                              progress: _animation.value,
                              selectedIndex: _hoveredOrSelectedIndex,
                            ),
                          ),
                          InkWell(
                            onTap: widget.onTotalSelected,
                            borderRadius: BorderRadius.circular(50),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  total > 0 ? '$total' : '0',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  'إجمالي الطلبات',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            const Center(
              child: Text(
                'لا توجد طلبات مسجلة حالياً',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted,
                    fontWeight: FontWeight.w500),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < widget.items.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: Color(0xFFE1E7F0)),
                  _LegendRow(
                    item: widget.items[i],
                    total: total,
                    isSelected: _hoveredOrSelectedIndex == i,
                    onTap: () {
                      setState(() {
                        _hoveredOrSelectedIndex =
                            _hoveredOrSelectedIndex == i ? null : i;
                      });
                      widget.onStatusSelected(widget.items[i].targetTab,
                          filterStatus: widget.items[i].filterKey);
                    },
                  ),
                ],
              ],
            ),

          // ── Footer hint ───────────────────────────────────────────────
          // if (total > 0) ...[
          //   const SizedBox(height: 10),
          //   const Divider(color: Color(0xFFF1F5F9), height: 1),
          //   const SizedBox(height: 6),
          //   const Text(
          //     'المجموع = الأرقام توضيحية • النسب تستخدم قيم دقيقة',
          //     style: TextStyle(
          //       fontSize: 10,
          //       color: AppColors.textMuted,
          //       fontWeight: FontWeight.w400,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legend row widget
// ─────────────────────────────────────────────────────────────────────────────
class _LegendRow extends StatelessWidget {
  final StatusStatItem item;
  final int total;
  final bool isSelected;
  final VoidCallback onTap;

  const _LegendRow({
    required this.item,
    required this.total,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? ((item.count / total) * 100) : 0.0;
    final percentageStr = '${percentage.toStringAsFixed(1)}%';
    final countStr = item.count < 10 && item.count >= 0
        ? '0${item.count}'
        : '${item.count}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? item.color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
          SizedBox(
            width: 45,
            child: Text(percentageStr, textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 11, color: Color(0xFF71809A))),
          ),
          const SizedBox(width: 8),
          // Count
          SizedBox(
            width: 38,
            child: Text(countStr, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                    color: isSelected ? item.color : AppColors.textPrimary)),
          ),
          const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
              textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Container(width: 7, height: 7, decoration: BoxDecoration(
              color: item.color, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<StatusStatItem> items;
  final int totalOrders;
  final double progress;
  final int? selectedIndex;

  _DonutChartPainter({
    required this.items,
    required this.totalOrders,
    required this.progress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 18.0;
    final radius = (size.width - strokeWidth) / 2;

    // Background track if empty
    if (totalOrders <= 0) {
      final trackPaint = Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, trackPaint);
      return;
    }

    // Number of active items with count > 0
    final activeCount = items.where((i) => i.count > 0).length;
    final double gapAngle = activeCount > 1 ? 0.045 : 0.0; // Spacing in radians
    final totalGap = gapAngle * activeCount;
    final availableAngle = (2 * math.pi - totalGap) * progress;

    double currentAngle = -math.pi / 2; // Start from 12 o'clock

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.count <= 0) continue;

      final sweep = (item.count / totalOrders) * availableAngle;
      final isSelected = selectedIndex == i;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? (strokeWidth + 5.0) : strokeWidth
        ..strokeCap = StrokeCap.butt;

      final rect = Rect.fromCircle(
        center: center,
        radius: isSelected ? (radius + 2.0) : radius,
      );

      canvas.drawArc(rect, currentAngle, sweep, false, paint);
      currentAngle += sweep + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.totalOrders != totalOrders ||
        oldDelegate.items != items;
  }
}
