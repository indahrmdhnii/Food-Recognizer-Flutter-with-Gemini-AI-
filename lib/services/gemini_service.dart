// lib/services/gemini_service.dart
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/nutrition_info.dart';

class GeminiService {
  GenerativeModel? _model;
  bool _isInitialized = false;

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  void initialize() {
    if (_isInitialized) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 512,
        ),
      );
      _isInitialized = true;
    }
  }

  Future<NutritionInfo?> getNutritionInfo(String foodName) async {
    if (!_isInitialized) initialize();

    // If no API key, return fallback
    if (_model == null) {
      return _getFallbackNutrition(foodName);
    }

    try {
      final cleanName = foodName.replaceAll('_', ' ');
      final prompt = '''
Berikan informasi nutrisi untuk makanan "$cleanName" per 100 gram.
Jawab HANYA dalam format JSON berikut tanpa teks tambahan, tanpa backticks, tanpa komentar:
{"calories":250,"carbohydrates":30.5,"fat":10.2,"fiber":3.1,"protein":12.4,"serving_size":"100g"}
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final text = (response.text ?? '').trim();

      // Strip markdown code fences if present
      final cleaned = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      // Find JSON object
      final jsonMatch = RegExp(r'\{[\s\S]+?\}').firstMatch(cleaned);
      if (jsonMatch != null) {
        final data = json.decode(jsonMatch.group(0)!);
        return NutritionInfo.fromJson(data);
      }
    } catch (e) {
      print('Gemini error: $e');
    }

    return _getFallbackNutrition(foodName);
  }

  NutritionInfo _getFallbackNutrition(String foodName) {
    // Rough fallback values by food category
    final lower = foodName.toLowerCase();

    if (lower.contains('salad') || lower.contains('vegetable')) {
      return NutritionInfo(calories: 80, carbohydrates: 10, fat: 3, fiber: 4, protein: 3, servingSize: '100g');
    } else if (lower.contains('burger') || lower.contains('pizza')) {
      return NutritionInfo(calories: 280, carbohydrates: 30, fat: 14, fiber: 2, protein: 13, servingSize: '100g');
    } else if (lower.contains('rice') || lower.contains('nasi')) {
      return NutritionInfo(calories: 210, carbohydrates: 45, fat: 1, fiber: 1, protein: 4, servingSize: '100g');
    } else if (lower.contains('chicken') || lower.contains('ayam')) {
      return NutritionInfo(calories: 195, carbohydrates: 0, fat: 9, fiber: 0, protein: 27, servingSize: '100g');
    } else if (lower.contains('cake') || lower.contains('bread')) {
      return NutritionInfo(calories: 320, carbohydrates: 55, fat: 10, fiber: 2, protein: 6, servingSize: '100g');
    }

    return NutritionInfo(
      calories: 250, carbohydrates: 30, fat: 10, fiber: 3, protein: 12, servingSize: '100g',
    );
  }
}
