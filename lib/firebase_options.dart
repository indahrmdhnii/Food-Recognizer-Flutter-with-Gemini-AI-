// lib/firebase_options.dart
// 
// PENTING: File ini harus digenerate menggunakan FlutterFire CLI:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Atau buat manual berdasarkan google-services.json dari Firebase Console.
//
// Untuk submission Dicoding tanpa Firebase, file ini tidak diperlukan
// karena app akan fallback ke model lokal secara otomatis.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Ganti semua nilai di bawah dengan konfigurasi Firebase project Anda.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default: throw UnsupportedError('Platform tidak didukung');
    }
  }

  // Ganti dengan nilai dari Firebase Console > Project Settings
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'YOUR_ANDROID_API_KEY',
    appId:             '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId:         'your-project-id',
    storageBucket:     'your-project-id.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'YOUR_IOS_API_KEY',
    appId:             '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId:         'your-project-id',
    storageBucket:     'your-project-id.appspot.com',
    iosBundleId:       'com.example.foodRecognizer',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'YOUR_WEB_API_KEY',
    appId:             '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId:         'your-project-id',
    storageBucket:     'your-project-id.appspot.com',
  );
}
