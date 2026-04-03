// lib/models/meal_info.dart

class MealInfo {
  final String idMeal;
  final String strMeal;
  final String? strMealThumb;
  final String? strInstructions;
  final String? strCategory;
  final String? strArea;
  final List<String> ingredients;
  final List<String> measures;

  MealInfo({
    required this.idMeal,
    required this.strMeal,
    this.strMealThumb,
    this.strInstructions,
    this.strCategory,
    this.strArea,
    required this.ingredients,
    required this.measures,
  });

  factory MealInfo.fromJson(Map<String, dynamic> json) {
    final ingredients = <String>[];
    final measures = <String>[];

    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add(ingredient.toString().trim());
        measures.add(measure?.toString().trim() ?? '');
      }
    }

    return MealInfo(
      idMeal: json['idMeal'] ?? '',
      strMeal: json['strMeal'] ?? '',
      strMealThumb: json['strMealThumb'],
      strInstructions: json['strInstructions'],
      strCategory: json['strCategory'],
      strArea: json['strArea'],
      ingredients: ingredients,
      measures: measures,
    );
  }
}
