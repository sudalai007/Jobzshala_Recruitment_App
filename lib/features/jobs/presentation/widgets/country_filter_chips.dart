import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CountryFilterChips extends StatelessWidget {
  final String selectedCountry;
  final ValueChanged<String> onSelected;

  const CountryFilterChips({
    super.key,
    required this.selectedCountry,
    required this.onSelected,
  });

  static const List<String> countries = ['All', 'UAE', 'Saudi Arabia', 'Qatar'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: countries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final country = countries[index];
          final isSelected = country.toLowerCase() == selectedCountry.toLowerCase();

          return ChoiceChip(
            label: Text(
              country,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            elevation: isSelected ? 2 : 0,
            showCheckmark: false,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onSelected: (_) => onSelected(country),
          );
        },
      ),
    );
  }
}
