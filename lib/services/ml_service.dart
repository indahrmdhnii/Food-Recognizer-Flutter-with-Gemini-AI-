// lib/services/ml_service.dart
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import '../models/food_prediction.dart';

class MLService {
  static const String _modelAssetPath = 'assets/models/food_classification.tflite';
  static const String _labelsAssetPath = 'assets/models/labels.txt';
  static const int _inputSize = 224;
  static const int _numResults = 5;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized  = false;
  bool _isUint8Input   = false;
  bool _isUint8Output  = false;
  int  _numClasses     = 0;

  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadModelFromAssets();
    await _loadLabels();
    _detectTensorTypes();
    _isInitialized = true;
  }

  Future<void> initializeFromFile(File modelFile) async {
    _interpreter?.close();
    _isInitialized = false;
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = Interpreter.fromFile(modelFile, options: options);
      await _loadLabels();
      _detectTensorTypes();
      _isInitialized = true;
    } catch (e) {
      await initialize();
    }
  }

  void _detectTensorTypes() {
    if (_interpreter == null) return;
    final inShape  = _interpreter!.getInputTensor(0).shape;
    final outShape = _interpreter!.getOutputTensor(0).shape;
    final inType   = _interpreter!.getInputTensor(0).type.toString().toLowerCase();
    final outType  = _interpreter!.getOutputTensor(0).type.toString().toLowerCase();
    _isUint8Input  = inType.contains('uint8');
    _isUint8Output = outType.contains('uint8');
    _numClasses    = outShape.length > 1 ? outShape[1] : outShape[0];
    print('=== MODEL INFO ===');
    print('Input  shape: $inShape  type: $inType');
    print('Output shape: $outShape type: $outType');
    print('Classes: $_numClasses | Labels loaded: ${_labels.length}');
    print('isUint8Input: $_isUint8Input | isUint8Output: $_isUint8Output');
  }

  Future<void> _loadModelFromAssets() async {
    final options = InterpreterOptions()..threads = 4;
    _interpreter = await Interpreter.fromAsset(_modelAssetPath, options: options);
  }

  Future<void> _loadLabels() async {
    try {
      final raw = await rootBundle.loadString(_labelsAssetPath);
      _labels = raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      print('Loaded ${_labels.length} labels. First 3: ${_labels.take(3).toList()}');
    } catch (e) {
      print('Label load error: $e');
      _labels = [];
    }
  }

  // ── Kriteria 2 Skilled: Isolate preprocessing ──────────────────
  Future<List<FoodPrediction>> classifyImageInBackground(File imageFile) async {
    if (!_isInitialized) await initialize();
    final imageBytes = await imageFile.readAsBytes();
    final inputData  = await _preprocessInIsolate(imageBytes, _isUint8Input);
    return _runInference(inputData);
  }

  Future<dynamic> _preprocessInIsolate(Uint8List imageBytes, bool isUint8) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_preprocessTask, [imageBytes, receivePort.sendPort, _inputSize, isUint8]);
    final result = await receivePort.first;
    receivePort.close();
    return result;
  }

  static void _preprocessTask(List<dynamic> args) {
    final imageBytes = args[0] as Uint8List;
    final sendPort   = args[1] as SendPort;
    final inputSize  = args[2] as int;
    final isUint8    = args[3] as bool;
    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        sendPort.send(isUint8
            ? Uint8List(inputSize * inputSize * 3)
            : Float32List(inputSize * inputSize * 3));
        return;
      }
      final resized = img.copyResize(decoded,
          width: inputSize, height: inputSize, interpolation: img.Interpolation.linear);

      if (isUint8) {
        final input = Uint8List(inputSize * inputSize * 3);
        int idx = 0;
        for (int y = 0; y < inputSize; y++) {
          for (int x = 0; x < inputSize; x++) {
            final p = resized.getPixel(x, y);
            input[idx++] = p.r.toInt().clamp(0, 255);
            input[idx++] = p.g.toInt().clamp(0, 255);
            input[idx++] = p.b.toInt().clamp(0, 255);
          }
        }
        sendPort.send(input);
      } else {
        final input = Float32List(inputSize * inputSize * 3);
        int idx = 0;
        for (int y = 0; y < inputSize; y++) {
          for (int x = 0; x < inputSize; x++) {
            final p = resized.getPixel(x, y);
            input[idx++] = p.r / 255.0;
            input[idx++] = p.g / 255.0;
            input[idx++] = p.b / 255.0;
          }
        }
        sendPort.send(input);
      }
    } catch (e) {
      print('Preprocess error: $e');
      sendPort.send(isUint8
          ? Uint8List(inputSize * inputSize * 3)
          : Float32List(inputSize * inputSize * 3));
    }
  }

  List<FoodPrediction> _runInference(dynamic inputData) {
    if (_interpreter == null) return [];

    // ── Build input [1, 224, 224, 3] ──────────────────────────────
    final List inputTensor;
    if (_isUint8Input) {
      final flat = inputData as Uint8List;
      inputTensor = [List.generate(_inputSize, (y) =>
        List.generate(_inputSize, (x) {
          final b = (y * _inputSize + x) * 3;
          return [flat[b], flat[b + 1], flat[b + 2]];
        }))];
    } else {
      final flat = inputData as Float32List;
      inputTensor = [List.generate(_inputSize, (y) =>
        List.generate(_inputSize, (x) {
          final b = (y * _inputSize + x) * 3;
          return [flat[b], flat[b + 1], flat[b + 2]];
        }))];
    }

    // ── Build output [1, numClasses] ──────────────────────────────
    final List outputTensor = _isUint8Output
        ? [List<int>.filled(_numClasses, 0)]
        : [List<double>.filled(_numClasses, 0.0)];

    _interpreter!.run(inputTensor, outputTensor);

    final rawScores = outputTensor[0] as List;

    // ── Debug: cetak top-5 raw scores ─────────────────────────────
    final indexed = List.generate(rawScores.length, (i) => MapEntry(i, rawScores[i]));
    indexed.sort((a, b) {
      final av = a.value is int ? (a.value as int).toDouble() : a.value as double;
      final bv = b.value is int ? (b.value as int).toDouble() : b.value as double;
      return bv.compareTo(av);
    });
    print('=== TOP 5 RAW SCORES ===');
    for (final e in indexed.take(5)) {
      final score = e.value is int ? (e.value as int) / 255.0 : e.value as double;
      final label = e.key < _labels.length ? _labels[e.key] : 'idx_${e.key}';
      print('  [$label] raw=${e.value} score=${(score * 100).toStringAsFixed(2)}%');
    }

    // ── Normalize jika output uint8 ───────────────────────────────
    final scores = _isUint8Output
        ? rawScores.map((v) => (v as int) / 255.0).toList()
        : rawScores.map((v) => v as double).toList();

    // ── Ambil top predictions (threshold diturunkan ke 0.001) ─────
    final predictions = <FoodPrediction>[];
    final used        = <int>{};

    for (int i = 0; i < _numResults; i++) {
      double maxScore = -1; int maxIdx = 0;
      for (int j = 0; j < scores.length; j++) {
        if (!used.contains(j) && scores[j] > maxScore) {
          maxScore = scores[j]; maxIdx = j;
        }
      }
      used.add(maxIdx);
      // Threshold sangat rendah agar selalu ada hasil
      if (maxIdx < _labels.length && maxScore >= 0.0) {
        predictions.add(FoodPrediction(label: _labels[maxIdx], confidence: maxScore));
      }
    }

    print('Predictions: ${predictions.map((p) => "${p.label}:${p.confidencePercent}").toList()}');
    return predictions;
  }

  // ── Kriteria 1 Advanced: live camera stream ────────────────────
  Future<List<FoodPrediction>> classifyFrame(CameraImage cameraImage) async {
    if (!_isInitialized) return [];
    try {
      final inputData = _preprocessCamera(cameraImage);
      return _runInference(inputData);
    } catch (_) { return []; }
  }

  dynamic _preprocessCamera(CameraImage image) {
    final yPlane = image.planes[0];
    final yBytes = yPlane.bytes;
    if (_isUint8Input) {
      final input = Uint8List(_inputSize * _inputSize * 3);
      int idx = 0;
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final srcX = (x * image.width  ~/ _inputSize).clamp(0, image.width  - 1);
          final srcY = (y * image.height ~/ _inputSize).clamp(0, image.height - 1);
          final pos  = srcY * yPlane.bytesPerRow + srcX;
          final luma = pos < yBytes.length ? yBytes[pos] : 128;
          input[idx++] = luma; input[idx++] = luma; input[idx++] = luma;
        }
      }
      return input;
    } else {
      final input = Float32List(_inputSize * _inputSize * 3);
      int idx = 0;
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final srcX = (x * image.width  ~/ _inputSize).clamp(0, image.width  - 1);
          final srcY = (y * image.height ~/ _inputSize).clamp(0, image.height - 1);
          final pos  = srcY * yPlane.bytesPerRow + srcX;
          final luma = pos < yBytes.length ? yBytes[pos] / 255.0 : 0.5;
          input[idx++] = luma; input[idx++] = luma; input[idx++] = luma;
        }
      }
      return input;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}