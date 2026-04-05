// lib/services/history_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryItem {
  final String id;
  final String foodLabel;
  final double confidence;
  final String imagePath;
  final DateTime scannedAt;

  HistoryItem({
    required this.id,
    required this.foodLabel,
    required this.confidence,
    required this.imagePath,
    required this.scannedAt,
  });

  String get displayLabel => foodLabel
      .split(RegExp(r'[_\s]+'))
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  Map<String, dynamic> toJson() => {
    'id':         id,
    'foodLabel':  foodLabel,
    'confidence': confidence,
    'imagePath':  imagePath,
    'scannedAt':  scannedAt.toIso8601String(),
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    id:         json['id'] ?? '',
    foodLabel:  json['foodLabel'] ?? '',
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    imagePath:  json['imagePath'] ?? '',
    scannedAt:  DateTime.tryParse(json['scannedAt'] ?? '') ?? DateTime.now(),
  );
}

class HistoryService {
  static const String _key = 'scan_history';
  static const int _maxItems = 50;

  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  Future<List<HistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr == null) return [];
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => HistoryItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addItem(HistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      // Tambah di depan (terbaru dulu)
      history.insert(0, item);

      // Batasi maksimal 50 item
      final trimmed = history.take(_maxItems).toList();

      await prefs.setString(_key, json.encode(trimmed.map((e) => e.toJson()).toList()));
    } catch (e) {
      print('History save error: $e');
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      history.removeWhere((e) => e.id == id);
      await prefs.setString(_key, json.encode(history.map((e) => e.toJson()).toList()));
    } catch (e) {
      print('History delete error: $e');
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
