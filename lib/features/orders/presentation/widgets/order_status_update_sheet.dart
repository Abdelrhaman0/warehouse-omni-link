import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/order_details.dart';
import '../../models/order_status.dart';
import '../cubits/order_details_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the status-update bottom sheet.
/// The caller must have [OrderDetailsCubit] accessible in [context].
Future<void> showOrderStatusUpdateSheet(
  BuildContext context,
  OrderDetails order,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<OrderDetailsCubit>(),
      child: OrderStatusUpdateSheet(order: order),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main sheet widget
// ─────────────────────────────────────────────────────────────────────────────

/// Statuses the warehouse keeper is allowed to set.
/// Only these three values may be sent to the API.
const List<OrderStatus> _kAllowedStatuses = [
  OrderStatus.shipped,
  OrderStatus.delivered,
  OrderStatus.cancelled,
];

class OrderStatusUpdateSheet extends StatefulWidget {
  final OrderDetails order;

  const OrderStatusUpdateSheet({super.key, required this.order});

  @override
  State<OrderStatusUpdateSheet> createState() => _OrderStatusUpdateSheetState();
}

class _OrderStatusUpdateSheetState extends State<OrderStatusUpdateSheet> {
  late OrderStatus _selected;

  // Cancellation sub-form state
  final _reasonController = TextEditingController();
  bool? _restoreStock; // null = not chosen yet
  bool _reasonError = false;
  bool _restoreStockError = false;

  bool get _isCancelled => _selected == OrderStatus.cancelled;

  @override
  void initState() {
    super.initState();
    _selected = _kAllowedStatuses.contains(widget.order.status)
        ? widget.order.status
        : _kAllowedStatuses.first;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ───────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.updateStatusSheetTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${AppStrings.currentStatus}: ${(widget.order.rawStatus.trim().isNotEmpty && (widget.order.status == OrderStatus.cancelled || widget.order.status == OrderStatus.unknown)) ? widget.order.rawStatus.trim() : widget.order.status.localizedLabel}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 24, color: AppColors.divider),
            ),

            // ── Status tiles ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _kAllowedStatuses.map((status) {
                  final isCurrent = status == widget.order.status;
                  final isSelected = status == _selected;
                  return _StatusTile(
                    status: status,
                    isCurrent: isCurrent,
                    isSelected: isSelected,
                    onTap: () => setState(() {
                      _selected = status;
                      if (status != OrderStatus.cancelled) {
                        _reasonError = false;
                        _restoreStockError = false;
                      }
                    }),
                  );
                }).toList(),
              ),
            ),

            // ── Cancellation sub-form ────────────────────────────────────────
            if (_isCancelled) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 28, color: AppColors.divider),
              ),
              _CancellationForm(
                reasonController: _reasonController,
                restoreStock: _restoreStock,
                reasonError: _reasonError,
                restoreStockError: _restoreStockError,
                onRestoreStockChanged: (value) =>
                    setState(() => _restoreStock = value),
              ),
            ],

            const SizedBox(height: 16),

            // ── Action buttons ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: (!_isCancelled && _selected == widget.order.status)
                          ? null
                          : _onConfirm,
                      icon: Icon(
                        _isCancelled
                            ? Icons.cancel_outlined
                            : Icons.check_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _isCancelled
                            ? AppStrings.confirmCancellation
                            : AppStrings.updateStatusButton,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isCancelled ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.35),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onConfirm() {
    if (_isCancelled) {
      final trimmedReason = _reasonController.text.trim();
      final reasonOk = trimmedReason.isNotEmpty;
      final restoreOk = _restoreStock != null;

      if (!reasonOk || !restoreOk) {
        setState(() {
          _reasonError = !reasonOk;
          _restoreStockError = !restoreOk;
        });
        return;
      }

      Navigator.of(context).pop();
      context.read<OrderDetailsCubit>().updateOrderStatus(
            currentOrder: widget.order,
            newStatus: OrderStatus.cancelled.apiValue,
            reason: trimmedReason,
            restoreStock: _restoreStock,
          );
    } else {
      Navigator.of(context).pop();
      context.read<OrderDetailsCubit>().updateOrderStatus(
            currentOrder: widget.order,
            newStatus: _selected.apiValue,
          );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cancellation sub-form
// ─────────────────────────────────────────────────────────────────────────────
class _CancellationForm extends StatelessWidget {
  final TextEditingController reasonController;
  final bool? restoreStock;
  final bool reasonError;
  final bool restoreStockError;
  final ValueChanged<bool> onRestoreStockChanged;

  const _CancellationForm({
    required this.reasonController,
    required this.restoreStock,
    required this.reasonError,
    required this.restoreStockError,
    required this.onRestoreStockChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                AppStrings.cancellationSheetTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: reasonController,
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: AppStrings.cancellationReason,
              hintText: AppStrings.cancellationReasonHint,
              errorText:
                  reasonError ? AppStrings.cancellationReasonRequired : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: reasonError ? AppColors.error : AppColors.cardBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            AppStrings.restoreStockHint,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: restoreStockError
                  ? AppColors.error
                  : AppColors.textPrimary,
            ),
          ),
          if (restoreStockError) ...[
            const SizedBox(height: 4),
            const Text(
              'يرجى اختيار أحد الخيارين',
              style: TextStyle(fontSize: 11, color: AppColors.error),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RestoreStockOption(
                  label: AppStrings.restoreStockYes,
                  icon: Icons.inventory_2_outlined,
                  isSelected: restoreStock == true,
                  color: AppColors.success,
                  onTap: () => onRestoreStockChanged(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RestoreStockOption(
                  label: AppStrings.restoreStockNo,
                  icon: Icons.close_rounded,
                  isSelected: restoreStock == false,
                  color: AppColors.error,
                  onTap: () => onRestoreStockChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestoreStockOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RestoreStockOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : icon,
              size: 16,
              color: isSelected ? color : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable status tile
// ─────────────────────────────────────────────────────────────────────────────
class _StatusTile extends StatelessWidget {
  final OrderStatus status;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusTile({
    required this.status,
    required this.isCurrent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = status.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? statusColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? statusColor : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? statusColor : AppColors.textMuted,
                  width: 2,
                ),
                color: isSelected ? statusColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status.localizedLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? statusColor : AppColors.textPrimary,
                ),
              ),
            ),
            if (isCurrent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppStrings.currentStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
