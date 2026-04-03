// lib/models/nutrition_info.dart

class NutritionInfo {
  final double calories;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double protein;
  final String servingSize;

  NutritionInfo({
    required this.calories,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.protein,
    required this.servingSize,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      servingSize: json['serving_size']?.toString() ?? '100g',
    );
  }
}
