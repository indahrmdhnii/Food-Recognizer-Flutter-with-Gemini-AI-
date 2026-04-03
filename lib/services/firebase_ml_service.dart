// lib/services/firebase_ml_service.dart
import 'dart:io';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';

class FirebaseMLService {
  static const String _modelName = 'food_classification';

  static final FirebaseMLService _instance = FirebaseMLService._internal();
  factory FirebaseMLService() => _instance;
  FirebaseMLService._internal();

  Future<File?> downloadModel() async {
    try {
      final customModel = await FirebaseModelDownloader.instance.getModel(
        _modelName,
        FirebaseModelDownloadType.localModelUpdateInBackground,
        FirebaseModelDownloadConditions(
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: false,
          androidChargingRequired: false,
          androidWifiRequired: false,
          androidDeviceIdleRequired: false,
        ),
      );
      final file = customModel.file;
      if (await file.exists()) return file;
      return null;
    } catch (e) {
      print('Firebase ML error: $e');
      return null;
    }
  }
}
