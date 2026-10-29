import 'package:flutter/material.dart';
import '../../models/safe_transaction.dart';

/// Card widget presenting a single safe transaction, matching Image 3 design.
class SafeTransactionCard extends StatelessWidget {
  final SafeTransaction transaction;
  final String currency;

  const SafeTransactionCard({
    super.key,
    required this.transaction,
    this.currency = 'EGP',
  });

  bool get _isIncome => transaction.isIncome;

  String get _typeTitle {
    if (transaction.typeLabel != null && transaction.typeLabel!.isNotEmpty) {
      return transaction.typeLabel!;
    }
    final type = transaction.type.toLowerCase();
    if (type.contains('transfer')) return 'تحويل';
    if (type == 'deposit') return 'إيداع';
    if (type == 'withdraw') return 'سحب';
    return _isIncome ? 'إيداع' : 'سحب';
  }

  Color get _color {
    final type = transaction.type.toLowerCase();
    if (type.contains('transfer')) {
      return const Color(0xFF2563EB); // Royal Blue
    }
    return _isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
  }

  Color get _bgColor {
    final type = transaction.type.toLowerCase();
    if (type.contains('transfer')) {
      return const Color(0xFFEFF5FF);
    }
    return _isIncome ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
  }

  IconData get _icon {
    final type = transaction.type.toLowerCase();
    if (type.contains('transfer')) {
      return Icons.swap_horiz_rounded;
    }
    return _isIncome ? Icons.south_west_rounded : Icons.north_east_rounded;
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
    final color = _color;
    final bgColor = _bgColor;
    final icon = _icon;
    final title = _typeTitle;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Type & Icon on Right, Large signed amount on Left
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Right: Icon + Type + "المبلغ بالجنيه المصري"
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'المبلغ بالجنيه المصري',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Left: Signed Amount
              Text(
                '${_isIncome ? '+' : '-'}${_formatAmount(transaction.amount)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Performer & Date
          if (transaction.performer?.name != null || transaction.createdAt != null) ...[
            const Text(
              'بواسطة',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              transaction.performer?.name ?? 'المسؤول',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            if (transaction.createdAt != null) ...[
              const SizedBox(height: 2),
              Text(
                transaction.createdAt!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],

          // Balance Progression Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Right: قبل العملية
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'قبل العملية',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatAmount(transaction.balanceBefore),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                // Arrow
                const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
                // Left: بعد العملية
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'بعد العملية',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatAmount(transaction.balanceAfter),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Footnote
          const Center(
            child: Text(
              'أرصدة تاريخية - لا تمثل الرصيد الحالي للخزنة',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
