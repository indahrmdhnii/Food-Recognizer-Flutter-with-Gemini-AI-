// lib/models/food_prediction.dart

class FoodPrediction {
  final String label;
  final double confidence;
  final String? imagePath;

  FoodPrediction({
    required this.label,
    required this.confidence,
    this.imagePath,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  String get displayLabel => label
      .split(RegExp(r'[_\s]+'))
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}
