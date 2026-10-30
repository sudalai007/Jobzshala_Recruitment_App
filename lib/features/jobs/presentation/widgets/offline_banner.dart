import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;

  const OfflineBanner({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.warningLight,
        border: Border(
          bottom: BorderSide(color: AppColors.warning, width: 1.5),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "You're offline — showing saved jobs",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF944A00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
