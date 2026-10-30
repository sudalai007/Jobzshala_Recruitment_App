import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class SalaryBadge extends StatelessWidget {
  final int minSalary;
  final int maxSalary;

  const SalaryBadge({
    super.key,
    required this.minSalary,
    required this.maxSalary,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final formattedMin = formatter.format(minSalary);
    final formattedMax = formatter.format(maxSalary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 15,
            color: AppColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            '$formattedMin – $formattedMax AED/mo',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

