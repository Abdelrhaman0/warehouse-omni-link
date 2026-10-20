import 'package:flutter/material.dart';

class OrderStepItem {
  final String label;

  const OrderStepItem({
    required this.label,
  });
}

class OrderDetailsStepBar extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepSelected;

  static const List<OrderStepItem> steps = [
    OrderStepItem( label: 'العميل'),
    OrderStepItem( label: 'الشحن'),
    OrderStepItem( label: 'الصور'),
    OrderStepItem( label: 'الملخص'),
  ];

  const OrderDetailsStepBar({
    super.key,
    required this.currentStep,
    required this.onStepSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isSelected = currentStep == index;

          return Expanded(
            child: InkWell(
              onTap: () => onStepSelected(index),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Step number badge
                    // Container(
                    //   width: 22,
                    //   height: 22,
                    //   alignment: Alignment.center,
                    //   decoration: BoxDecoration(
                    //     shape: BoxShape.circle,
                    //     color: isSelected
                    //         ? const Color(0xFF2563EB)
                    //         : const Color(0xFFE2E8F0),
                    //   ),
                    //
                    // ),
                    // const SizedBox(width: 5),

                    // Step label
                    Flexible(
                      child: Text(
                        step.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
