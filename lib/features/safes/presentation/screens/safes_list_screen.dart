import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../models/safe.dart';
import '../../models/safe_summary.dart';
import '../cubits/safes_list_cubit.dart';
import '../cubits/safes_state.dart';
import '../widgets/safe_card.dart';
import '../widgets/safe_operation_dialogs.dart';
import '../widgets/vault_icon.dart';

/// Screen listing all financial safes with summary metrics, live search,
/// and quick actions, redesigned according to the Figma specification.
class SafesListScreen extends StatefulWidget {
  const SafesListScreen({super.key});

  @override
  State<SafesListScreen> createState() => _SafesListScreenState();
}

class _SafesListScreenState extends State<SafesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SafesListCubit>().loadSafes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isSuperAdmin(BuildContext context) {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        return authState.user.isSuperAdmin;
      }
    } catch (_) {}
    return false;
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
    if (!_isSuperAdmin(context)) {
      return Scaffold(
        appBar: AppBar(title: const Text('إدارة الخزن')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_rounded, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'غير مصرح بالوصول',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'خاصية إدارة الخزن المالية متاحة فقط للمشرف العام (Super Admin).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('العودة للرئيسية'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              'إدارة الخزن المالية',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'أومني لينك • إدارة المخزن',
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
        //           context.read<SafesListCubit>().refreshSafes();
        //         },
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: BlocBuilder<SafesListCubit, SafesListState>(
        builder: (context, state) {
          if (state is SafesListLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارٍ تحميل بيانات الخزن...', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            );
          }

          if (state is SafesListError) {
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
                      style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<SafesListCubit>().loadSafes(),
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

          if (state is SafesListLoaded) {
            final allSafes = state.safes;
            final summary = state.summary;

            final filteredSafes = _searchQuery.isEmpty
                ? allSafes
                : allSafes.where((s) {
                    final nameMatch = s.name.toLowerCase().contains(_searchQuery);
                    final typeMatch = s.type.toLowerCase().contains(_searchQuery);
                    final accountMatch = s.accountNumber?.toLowerCase().contains(_searchQuery) ?? false;
                    return nameMatch || typeMatch || accountMatch;
                  }).toList();

            return RefreshIndicator(
              onRefresh: () => context.read<SafesListCubit>().refreshSafes(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // 1. Subheader: "الإدارة المالية" & "سوبر أدمن فقط"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الإدارة المالية',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF5FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'سوبر أدمن فقط',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Summary Banner (Deep Navy Solid Card)
                  _buildSummaryBanner(summary, allSafes),
                  const SizedBox(height: 16),

                  // 3. Action Buttons Row: "+ إضافة خزنة" & "تحويل بين الخزن"
                  _buildActionButtonsRow(context, allSafes),
                  const SizedBox(height: 20),

                  // 4. Section Title & Total Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الخزن المالية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${allSafes.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 5. Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'ابحث باسم الخزنة',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Safes List Cards
                  if (filteredSafes.isEmpty)
                    _buildEmptySearchState(context)
                  else
                    ...filteredSafes.map((safe) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SafeCard(
                          safe: safe,
                          onTap: () async {
                            final cubit = context.read<SafesListCubit>();
                            await Navigator.of(context).pushNamed(
                              AppRouter.safeDetails,
                              arguments: safe.id,
                            );
                            cubit.refreshSafes();
                          },
                        ),
                      );
                    }),

                  // 7. Footer showing count
                  if (allSafes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'عرض ${filteredSafes.length} خزن من أصل ${allSafes.length} خزن',
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

  Widget _buildSummaryBanner(SafeSummary? summary, List<Safe> safes) {
    final totalBalance = summary?.totalBalance ??
        safes.fold<double>(0.0, (sum, s) => sum + s.balance);
    final totalSafes = summary?.totalSafes ?? safes.length;
    final activeSafes = summary?.activeSafes ??
        safes.where((s) => s.isActive).length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF17306B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17306B).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Vault icon + "إجمالي أرصدة الخزن"
          const Row(
            children: [
              VaultIcon(
                size: 16,
                color: Color(0xFFD0E1FD),
              ),
              SizedBox(width: 8),
              Text(
                'إجمالي أرصدة الخزن',
                style: TextStyle(
                  color: Color(0xFFD0E1FD),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Big bold balance
          Text(
            _formatAmount(totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'الجنيه المصري • EGP',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Bottom row: checkmark + "X خزن • Y نشطة"
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4ADE80),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '$totalSafes خزن • $activeSafes نشطة',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow(BuildContext context, List<Safe> safes) {
    return Row(
      children: [
        // 1. Right Button (in RTL): "+ إضافة خزنة"
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => CreateSafeSheet.show(
              context,
              onSuccess: () => context.read<SafesListCubit>().loadSafes(isRefresh: true),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'إضافة خزنة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 2. Left Button (in RTL): "تحويل بين الخزن"
        Expanded(
          child: OutlinedButton.icon(
            onPressed: safes.length < 2
                ? null
                : () => TransferSheet.show(
                      context,
                      allSafes: safes,
                      onSuccess: () => context.read<SafesListCubit>().loadSafes(isRefresh: true),
                    ),
            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
            label: const Text(
              'تحويل بين الخزن',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E40AF),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySearchState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.search_off_rounded, color: Color(0xFF1E40AF), size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'لم يتم العثور على خزن',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'لا توجد خزن مطابقة لكلمة البحث المدخلة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
