// lib/services/meal_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal_info.dart';

class MealService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  static final MealService _instance = MealService._internal();
  factory MealService() => _instance;
  MealService._internal();

  Future<MealInfo?> searchMeal(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final response = await http
          .get(Uri.parse('$_baseUrl/search.php?s=$encoded'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;
        if (meals != null && meals.isNotEmpty) {
          return MealInfo.fromJson(meals[0] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('MealDB error: $e');
    }
    return null;
  }

  /// Fuzzy search: try exact → first word → underscores replaced
  Future<MealInfo?> searchMealFuzzy(String foodLabel) async {
    var result = await searchMeal(foodLabel);
    if (result != null) return result;

    final firstWord = foodLabel.split(RegExp(r'[_\s]+')).first;
    result = await searchMeal(firstWord);
    if (result != null) return result;

    final spaced = foodLabel.replaceAll('_', ' ');
    return await searchMeal(spaced);
  }
}
