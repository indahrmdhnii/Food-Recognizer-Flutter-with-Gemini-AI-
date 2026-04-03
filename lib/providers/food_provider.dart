// lib/providers/food_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/food_prediction.dart';
import '../models/meal_info.dart';
import '../models/nutrition_info.dart';
import '../services/ml_service.dart';
import '../services/meal_service.dart';
import '../services/gemini_service.dart';

// Uncomment to enable Firebase ML:
// import '../services/firebase_ml_service.dart';

enum AppState { idle, loading, success, error }

class FoodProvider extends ChangeNotifier {
  AppState _state = AppState.idle;
  AppState get state => _state;

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  List<FoodPrediction> _predictions = [];
  List<FoodPrediction> get predictions => _predictions;

  FoodPrediction? _topPrediction;
  FoodPrediction? get topPrediction => _topPrediction;

  MealInfo? _mealInfo;
  MealInfo? get mealInfo => _mealInfo;

  NutritionInfo? _nutritionInfo;
  NutritionInfo? get nutritionInfo => _nutritionInfo;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isModelFromCloud = false;
  bool get isModelFromCloud => _isModelFromCloud;

  bool _isModelReady = false;
  bool get isModelReady => _isModelReady;

  final MLService _mlService = MLService();
  final MealService _mealService = MealService();
  final GeminiService _geminiService = GeminiService();

  // ── Kriteria 2 Advanced: Firebase ML model download ────────────
  // Uncomment the block below and add firebase_ml_service.dart import:
  //
  // final FirebaseMLService _firebaseMLService = FirebaseMLService();
  //
  // Future<void> _tryCloudModel() async {
  //   final cloudFile = await _firebaseMLService.downloadModel();
  //   if (cloudFile != null) {
  //     await _mlService.initializeFromFile(cloudFile);
  //     _isModelFromCloud = true;
  //     return;
  //   }
  //   await _mlService.initialize();
  // }
  // ───────────────────────────────────────────────────────────────

  Future<void> initializeModel() async {
    _geminiService.initialize();

    try {
      // To use Firebase ML, replace the line below with: await _tryCloudModel();
      await _mlService.initialize();
      _isModelFromCloud = false;
    } catch (e) {
      debugPrint('Model init error: $e');
    }

    _isModelReady = true;
    notifyListeners();
  }

  /// Classify an image file. Runs inference in a background Isolate (Kriteria 2 - Skilled).
  Future<void> classifyImage(File image) async {
    _selectedImage = image;
    _state = AppState.loading;
    _predictions = [];
    _mealInfo = null;
    _nutritionInfo = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _predictions = await _mlService.classifyImageInBackground(image);

      if (_predictions.isNotEmpty) {
        _topPrediction = _predictions.first;
        _state = AppState.success;
        notifyListeners();

        // Load MealDB + Gemini in parallel (Kriteria 3)
        await Future.wait([
          _loadMealInfo(_topPrediction!.label),
          _loadNutritionInfo(_topPrediction!.label),
        ]);
      } else {
        // Jika predictions benar-benar kosong, coba jalankan ulang tanpa threshold
        _errorMessage = 'Model tidak menghasilkan prediksi. '
            'Pastikan file food_classification.tflite sudah diletakkan '
            'di assets/models/ dan labels.txt sesuai.';
        _state = AppState.error;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _state = AppState.error;
    }

    notifyListeners();
  }

  Future<void> _loadMealInfo(String label) async {
    try {
      _mealInfo = await _mealService.searchMealFuzzy(label);
      notifyListeners();
    } catch (e) {
      debugPrint('MealDB error: $e');
    }
  }

  Future<void> _loadNutritionInfo(String label) async {
    try {
      _nutritionInfo = await _geminiService.getNutritionInfo(label);
      notifyListeners();
    } catch (e) {
      debugPrint('Gemini error: $e');
    }
  }

  void reset() {
    _state = AppState.idle;
    _selectedImage = null;
    _predictions = [];
    _topPrediction = null;
    _mealInfo = null;
    _nutritionInfo = null;
    _errorMessage = null;
    notifyListeners();
  }
}