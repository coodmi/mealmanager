import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class QuickActionBar extends StatelessWidget {
  final VoidCallback onUpdateMeal;
  final VoidCallback onBazarSchedule;

  const QuickActionBar({
    super.key,
    required this.onUpdateMeal,
    required this.onBazarSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onUpdateMeal,
              icon: const Icon(Icons.restaurant_menu, size: 16),
              label: const Text('Update Meal', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: BorderSide(
                  color: AppColors.primaryGreen.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onBazarSchedule,
              icon: const Icon(Icons.shopping_basket_rounded, size: 16),
              label: const Text(
                'Bazar Schedule',
                style: TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
