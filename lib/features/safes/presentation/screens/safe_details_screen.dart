import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/safe.dart';
import '../../models/safe_transaction.dart';
import '../cubits/safe_details_cubit.dart';
import '../cubits/safes_list_cubit.dart';
import '../cubits/safes_state.dart';
import '../widgets/safe_operation_dialogs.dart';
import '../widgets/safe_transaction_card.dart';
import '../widgets/vault_icon.dart';

/// Screen displaying full details of a financial safe, redesigned to match Image 3.
class SafeDetailsScreen extends StatefulWidget {
  final int safeId;

  const SafeDetailsScreen({super.key, required this.safeId});

  @override
  State<SafeDetailsScreen> createState() => _SafeDetailsScreenState();
}

class _SafeDetailsScreenState extends State<SafeDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all'; // 'all', 'deposit', 'withdraw', 'transfer'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SafeDetailsCubit>().loadSafeDetails(widget.safeId);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SafeDetailsCubit>().loadMoreTransactions();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = intPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formattedInt.$decPart';
  }

  List<SafeTransaction> _filterTransactions(List<SafeTransaction> transactions) {
    if (_selectedFilter == 'deposit') {
      return transactions.where((t) => t.isIncome).toList();
    } else if (_selectedFilter == 'withdraw') {
      return transactions.where((t) => !t.isIncome && !t.type.toLowerCase().contains('transfer')).toList();
    } else if (_selectedFilter == 'transfer') {
      return transactions.where((t) => t.type.toLowerCase().contains('transfer')).toList();
    }
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل الخزنة',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'سجل العمليات المالية',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //     child: Container(
        //       width: 40,
        //       height: 40,
        //       decoration: BoxDecoration(
        //         color: Colors.white,
        //         borderRadius: BorderRadius.circular(12),
        //         border: Border.all(color: const Color(0xFFE2E8F0)),
        //       ),
        //       child: IconButton(
        //         padding: EdgeInsets.zero,
        //         icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF1E3A8A)),
        //         onPressed: () {
        //           context.read<SafeDetailsCubit>().refreshSafeDetails();
        //         },
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: BlocBuilder<SafeDetailsCubit, SafeDetailsState>(
        builder: (context, state) {
          if (state is SafeDetailsLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارٍ تحميل تفاصيل الخزنة...', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            );
          }

          if (state is SafeDetailsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<SafeDetailsCubit>().loadSafeDetails(widget.safeId),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SafeDetailsLoaded) {
            final safe = state.safe;
            final allTransactions = state.transactions;
            final filteredTransactions = _filterTransactions(allTransactions);
            final pagination = state.pagination;
            final totalTransactions = pagination?.total ?? allTransactions.length;

            return RefreshIndicator(
              onRefresh: () => context.read<SafeDetailsCubit>().refreshSafeDetails(),
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // 1. Safe Header Card
                  _buildSafeHeader(safe),
                  const SizedBox(height: 14),

                  // 2. Inactive Notice Banner if safe is not active
                  if (!safe.isActive) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF5FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF1E40AF),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'هذه الخزنة غير نشطة. الإيداع والسحب والتحويل غير متاحة، ويمكنك الاطلاع على العمليات السابقة فقط.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E3A8A),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 3. Action Buttons (Deposit / Withdraw / Transfer)
                  _buildActionButtons(context, safe),
                  const SizedBox(height: 24),

                  // 4. Transactions Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'سجل العمليات المالية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '$totalTransactions عملية',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. Filter Row: "كل العمليات" and "تصفية"
                  Row(
                    children: [
                      // Dropdown filter
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedFilter,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1E40AF)),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E40AF),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('كل العمليات')),
                                DropdownMenuItem(value: 'deposit', child: Text('الإيداعات فقط')),
                                DropdownMenuItem(value: 'withdraw', child: Text('السحوبات فقط')),
                                DropdownMenuItem(value: 'transfer', child: Text('التحويلات فقط')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedFilter = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filter button
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = _selectedFilter == 'all' ? 'deposit' : 'all';
                            });
                          },
                          icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF1E40AF)),
                          label: const Text(
                            'تصفية',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 6. Transactions List
                  if (filteredTransactions.isEmpty)
                    _buildEmptyTransactions()
                  else ...[
                    ...filteredTransactions.map((tx) {
                      return SafeTransactionCard(
                        transaction: tx,
                        currency: safe.currency,
                      );
                    }),
                    if (state.isLoadingMoreTransactions)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (state.paginationError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Text(
                              state.paginationError!,
                              style: const TextStyle(fontSize: 12, color: AppColors.error),
                            ),
                            TextButton.icon(
                              onPressed: () => context.read<SafeDetailsCubit>().loadMoreTransactions(),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('إعادة محاولة التحميل'),
                            ),
                          ],
                        ),
                      ),
                  ],

                  // 7. Footer
                  if (totalTransactions > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'عملية سابقة من سجل يضم $totalTransactions عملية',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildSafeHeader(Safe safe) {
    return Container(
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
          // Top Row: Vault icon and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VaultIcon(
                size: 22,
                color: safe.isActive ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
              ),
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
          // Current Balance Label
          const Text(
            'الرصيد الحالي • EGP',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Balance Value
          Text(
            _formatAmount(safe.balance),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          // Subtitle / Notes
          Text(
            !safe.isActive
                ? 'خزنة مؤرشفة • السجل محفوظ للمراجعة'
                : (safe.notes != null && safe.notes!.isNotEmpty
                    ? safe.notes!
                    : '${safe.name} • ${safe.typeLabel ?? safe.type}'),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Safe safe) {
    final isEnabled = safe.isActive;

    return Row(
      children: [
        // 1. Deposit Button
        Expanded(
          child: _buildActionButton(
            label: 'إيداع',
            icon: Icons.arrow_downward_rounded,
            isEnabled: isEnabled,
            onTap: () => DepositSheet.show(
              context,
              safe: safe,
              onSuccess: () => context.read<SafeDetailsCubit>().refreshSafeDetails(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 2. Withdraw Button
        Expanded(
          child: _buildActionButton(
            label: 'سحب',
            icon: Icons.arrow_upward_rounded,
            isEnabled: isEnabled,
            onTap: () => WithdrawSheet.show(
              context,
              safe: safe,
              onSuccess: () => context.read<SafeDetailsCubit>().refreshSafeDetails(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 3. Transfer Button
        Expanded(
          child: _buildActionButton(
            label: 'تحويل',
            icon: Icons.swap_horiz_rounded,
            isEnabled: isEnabled,
            onTap: () {
              final safesListState = context.read<SafesListCubit>().state;
              List<Safe> allSafes = [safe];
              if (safesListState is SafesListLoaded) {
                allSafes = safesListState.safes;
              }
              TransferSheet.show(
                context,
                allSafes: allSafes,
                initialFromSafe: safe,
                onSuccess: () => context.read<SafeDetailsCubit>().refreshSafeDetails(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFFEFF5FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isEnabled ? const Color(0xFF1E40AF) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isEnabled ? const Color(0xFF1E40AF) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_rounded, color: Color(0xFF94A3B8), size: 36),
          SizedBox(height: 12),
          Text(
            'لا توجد عمليات مسجلة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          SizedBox(height: 4),
          Text(
            'لم يتم تسجيل أي عمليات إيداع أو سحب أو تحويل على هذه الخزنة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
