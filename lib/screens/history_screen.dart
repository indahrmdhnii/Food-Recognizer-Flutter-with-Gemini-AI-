// lib/screens/history_screen.dart
// Halaman riwayat scan (placeholder - dapat diperluas dengan SharedPreferences/SQLite)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Text('Riwayat Scan', style: Theme.of(context).textTheme.displayMedium),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: Text('📋', style: TextStyle(fontSize: 44))),
                      ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 20),
                      Text('Belum ada riwayat', style: Theme.of(context).textTheme.titleLarge)
                          .animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Mulai scan makananmu untuk\nmelihat riwayat di sini.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
