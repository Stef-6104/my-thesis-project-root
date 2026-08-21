import 'package:flutter/material.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onAddTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.count,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.darkGray,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.pastelYellow,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.cascadingWhite,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
