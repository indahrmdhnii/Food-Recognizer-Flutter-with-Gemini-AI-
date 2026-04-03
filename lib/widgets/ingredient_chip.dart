// lib/widgets/ingredient_chip.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class IngredientChip extends StatelessWidget {
  final String ingredient;
  final String measure;
  const IngredientChip({super.key, required this.ingredient, required this.measure});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Text(
        measure.isNotEmpty ? '$measure $ingredient' : ingredient,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      ),
    );
  }
}
