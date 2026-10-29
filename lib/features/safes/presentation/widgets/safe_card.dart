import 'package:flutter/material.dart';
import '../../models/safe.dart';
import 'vault_icon.dart';

/// Card widget presenting a single financial safe item, matching the Figma design.
class SafeCard extends StatelessWidget {
  final Safe safe;
  final VoidCallback onTap;

  const SafeCard({
    super.key,
    required this.safe,
    required this.onTap,
  });

  Widget _buildTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'wallet':
        return const Icon(
          Icons.account_balance_wallet_outlined,
          color: Color(0xFF1E40AF),
          size: 22,
        );
      case 'bank':
        return const Icon(
          Icons.account_balance_outlined,
          color: Color(0xFF1E40AF),
          size: 22,
        );
      case 'cash':
      default:
        return const VaultIcon(
          size: 22,
          color: Color(0xFF1E40AF),
        );
    }
  }

  String _getTypeSubtitle(Safe safe) {
    final typeLabel = safe.typeLabel ??
        (safe.type.toLowerCase() == 'bank'
            ? 'حساب بنكي'
            : safe.type.toLowerCase() == 'wallet'
                ? 'محفظة إلكترونية'
                : 'خزنة نقدية');

    if (safe.notes != null && safe.notes!.isNotEmpty) {
      return '$typeLabel • ${safe.notes}';
    }
    if (safe.accountNumber != null && safe.accountNumber!.isNotEmpty) {
      return '$typeLabel • ${safe.accountNumber}';
    }
    return '$typeLabel • رئيسية';
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = intPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formattedInt.$decPart';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E9F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon + Name & Subtitle + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF5FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: _buildTypeIcon(safe.type),
                ),
                const SizedBox(width: 12),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safe.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getTypeSubtitle(safe),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: safe.isActive
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    safe.isActive ? 'نشطة' : 'غير نشطة',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: safe.isActive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Available Balance
            const Text(
              'الرصيد المتاح • EGP',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatAmount(safe.balance),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            // Bottom Action Link: "تفاصيل الخزنة وسجل العمليات" with arrow
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تفاصيل الخزنة وسجل العمليات',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: Color(0xFF1E40AF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
