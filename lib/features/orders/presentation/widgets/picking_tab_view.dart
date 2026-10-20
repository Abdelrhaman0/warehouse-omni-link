import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/authenticated_cache_manager.dart';
import '../../models/order_details.dart';
import '../../models/order_item.dart';
import '../../models/order_status.dart';
import '../screens/full_screen_image_viewer.dart';

class PickingTabView extends StatelessWidget {
  final OrderDetails order;

  const PickingTabView({
    super.key,
    required this.order,
  });

  int get totalUnits =>
      order.items.fold(0, (sum, item) => sum + item.quantity);

  String _formatItemsCount(int count) {
    if (count == 1) return 'صنف واحد';
    if (count == 2) return 'صنفان';
    if (count >= 3 && count <= 10) return '$count أصناف';
    return '$count صنف ';
  }

  String _formatUnitsCount(int count) {
    if (count == 1) return 'وحدة واحدة';
    if (count == 2) return 'وحدتان';
    if (count >= 3 && count <= 10) return '$count وحدات';
    return '$count وحدة';
  }

  String _formatArabicDateTime(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) {
      return 'تأكيد الطلب • جاهز للالتقاط';
    }
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        const months = [
          'يناير',
          'فبراير',
          'مارس',
          'أبريل',
          'مايو',
          'يونيو',
          'يوليو',
          'أغسطس',
          'سبتمبر',
          'أكتوبر',
          'نوفمبر',
          'ديسمبر'
        ];
        final monthName = months[parsed.month - 1];
        final hour = parsed.hour.toString().padLeft(2, '0');
        final minute = parsed.minute.toString().padLeft(2, '0');
        return 'تأكيد الطلب • ${parsed.day} $monthName ${parsed.year}، $hour:$minute';
      }
    } catch (_) {}
    return 'تأكيد الطلب • $dateStr';
  }

  String _generatePickingGuide(List<OrderItem> items) {
    if (items.isEmpty) {
      return 'تحقّق من رمز كل صنف قبل البدء بالالتقاط.';
    }
    final aisles = items
        .map((i) => i.displayLocation.split('-').first)
        .toSet()
        .toList()
      ..sort();

    if (aisles.length > 1) {
      return 'ابدأ من الممر ${aisles[0]}، ثم انتقل إلى الممر ${aisles[1]}. تحقّق من رمز كل صنف.';
    } else if (aisles.length == 1) {
      return 'جميع الأصناف تقع في الممر ${aisles.first}. تحقّق من رمز كل صنف.';
    }
    return 'ابدأ من الممر A، ثم انتقل إلى الممر B. تحقّق من رمز كل صنف.';
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) return;
    final Uri phoneUri = Uri(scheme: 'tel', path: trimmed);
    try {
      final launched = await launchUrl(phoneUri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح تطبيق الهاتف'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Order Code Card
          _buildOrderCodeCard(),
          const SizedBox(height: 16),

          // 2. Customer & Shipping Card
          _buildCustomerAndShippingCard(context),
          const SizedBox(height: 16),

          // 3. Items & Locations Card
          _buildItemsAndLocationsCard(context),
          const SizedBox(height: 14),

          // 4. Picking Route Banner
          _buildRouteBanner(),
        ],
      ),
    );
  }

  Widget _buildOrderCodeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Order Number
              Text(
                order.orderNumber,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.2,
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: order.status == OrderStatus.confirmed
                      ? const Color(0xFFE0F2FE)
                      : order.status.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.rawStatus.isNotEmpty
                      ? order.rawStatus
                      : order.status.localizedLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: order.status == OrderStatus.confirmed
                        ? const Color(0xFF0284C7)
                        : order.status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Subtitle / Date
          Text(
            _formatArabicDateTime(order.confirmedAt ?? order.createdAt),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerAndShippingCard(BuildContext context) {
    final shippingCompany = order.shippingDetails?.shippingCompany?.trim();
    final hasShippingCompany =
        shippingCompany != null && shippingCompany.isNotEmpty;
    final shippingValue = hasShippingCompany
        ? (order.shippingDetails?.internalStatusText != null &&
                order.shippingDetails!.internalStatusText!.isNotEmpty
            ? '$shippingCompany • ${order.shippingDetails!.internalStatusText}'
            : '$shippingCompany • خدمة قياسية')
        : 'سمسا • خدمة قياسية';

    final hasCustomerName = order.customerName.trim().isNotEmpty;
    final customerName = hasCustomerName ? order.customerName : 'أحمد الراشد';
    final hasPhone = order.phone != null && order.phone!.trim().isNotEmpty;
    final phone = hasPhone ? order.phone! : '+966 50 218 6042';
    final hasAddress = order.address != null && order.address!.trim().isNotEmpty;
    final address = hasAddress
        ? order.address!
        : 'حي الياسمين، شارع أنس بن مالك، الرياض';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'العميل والشحن',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Customer Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _makePhoneCall(context, phone),
                      child: Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 14),

          // Shipping Company Row
          Row(
            children: [
              // const Icon(
              //   Icons.local_shipping_outlined,
              //   color: Color(0xFF2563EB),
              //   size: 20,
              // ),
              // const SizedBox(width: 8),
              const Text(
                'شركة الشحن',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shippingValue,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),

          if (order.total != null && order.total!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildCardInfoRow(
              // icon: Icons.payments_outlined,
              // iconColor: const Color(0xFF10B981),
              label: AppStrings.orderTotal,
              value: order.total!.trim(),
            ),
          ],

          if (order.remainingAmount != null &&
              order.remainingAmount!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildCardInfoRow(
              // icon: Icons.account_balance_wallet_outlined,
              // iconColor: const Color(0xFFF59E0B),
              label: AppStrings.remainingAmount,
              value: order.remainingAmount!.trim(),
            ),
          ],

          if (order.remainingType != null &&
              order.remainingType!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildCardInfoRow(
              // icon: Icons.category_outlined,
              // iconColor: const Color(0xFF6366F1),
              label: AppStrings.remainingType,
              value: order.remainingType!.trim(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardInfoRow({
    // required IconData icon,
    // required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        // Icon(
        //   icon,
        //   color: iconColor,
        //   size: 20,
        // ),
        // const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsAndLocationsCard(BuildContext context) {
    final itemsCountFormatted = _formatItemsCount(order.items.length);
    final unitsCountFormatted = _formatUnitsCount(totalUnits);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Expanded(
                child: Text(
                  'الأصناف ومواقعها',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$itemsCountFormatted • $unitsCountFormatted',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (order.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'لا توجد أصناف مسجلة لهذا الطلب',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildPickingItemRow(context, order.items[index], index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPickingItemRow(
      BuildContext context, OrderItem item, int itemIndex) {
    final hasImage =
        item.productImage != null && item.productImage!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Quantity Column (Left)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.quantity} ×',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                  height: 1.1,
                ),
              ),
              const Text(
                'وحدات',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Details Column (Center)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.sku.isNotEmpty)
                  Text(
                    item.sku,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.displayLocation,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Item Icon / Thumbnail (Right)
          GestureDetector(
            onTap: hasImage
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          imageUrls: [item.productImage!],
                          initialIndex: 0,
                          title: item.productName,
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: item.productImage!,
                        cacheManager: AuthenticatedCacheManager.instance,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF94A3B8),
                          size: 24,
                        ),
                      )
                    : Icon(
                        itemIndex % 2 == 0
                            ? Icons.pan_tool_outlined
                            : Icons.radio_button_unchecked,
                        color: const Color(0xFF1E3A8A),
                        size: 26,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.alt_route_rounded,
            color: Color(0xFF2563EB),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _generatePickingGuide(order.items),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E40AF),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
