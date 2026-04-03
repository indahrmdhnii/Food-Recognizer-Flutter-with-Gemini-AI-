// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'providers/food_provider.dart';

// ── Firebase ML (Advanced) ──────────────────────────────────────
// Uncomment below after running: flutterfire configure
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// ────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env for GEMINI_API_KEY
  await dotenv.load(fileName: '.env');

  // ── Firebase init (uncomment when Firebase is configured) ──────
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // } catch (e) {
  //   debugPrint('Firebase not configured, using local model: $e');
  // }
  // ──────────────────────────────────────────────────────────────

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const FoodLensApp());
}

class FoodLensApp extends StatelessWidget {
  const FoodLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FoodProvider()),
      ],
      child: MaterialApp(
        title: 'FoodLens',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
