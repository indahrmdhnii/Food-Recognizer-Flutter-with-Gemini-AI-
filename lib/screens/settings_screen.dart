// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Setelan', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 28),
                _buildSection(context, 'Model AI', [
                  Consumer<FoodProvider>(
                    builder: (_, p, __) => _SettingTile(
                      icon: p.isModelFromCloud ? '☁️' : '📱',
                      title: 'Sumber Model',
                      subtitle: p.isModelFromCloud
                          ? 'Firebase ML (Cloud)'
                          : 'Model Lokal (Aset)',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.isModelFromCloud ? AppColors.tertiary : AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p.isModelFromCloud ? 'Cloud' : 'Lokal',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSection(context, 'API', [
                  _SettingTile(
                    icon: '✨',
                    title: 'Gemini AI',
                    subtitle: 'Informasi nutrisi makanan',
                    trailing: const _StatusDot(active: true),
                  ),
                  _SettingTile(
                    icon: '🍳',
                    title: 'MealDB API',
                    subtitle: 'Resep & bahan makanan',
                    trailing: const _StatusDot(active: true),
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSection(context, 'Tentang', [
                  _SettingTile(icon: '🍽️', title: 'FoodLens', subtitle: 'Versi 1.0.0'),
                  _SettingTile(icon: '📚', title: 'Dibuat untuk', subtitle: 'Dicoding Submission — Flutter ML'),
                  _SettingTile(icon: '🎨', title: 'Desain', subtitle: 'Pastel · Font Poppins · Material 3'),
                ]),
                const SizedBox(height: 32),
                _buildCriteriaChecklist(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) const Divider(height: 1, indent: 56, color: Color(0xFFF0E8F0)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildCriteriaChecklist(BuildContext context) {
    final criteria = [
      ('✅', 'Kriteria 1 — Pengambilan Gambar', 'Galeri · Kamera · Crop · Live Feed'),
      ('✅', 'Kriteria 2 — Machine Learning', 'LiteRT · Isolate · Firebase ML'),
      ('✅', 'Kriteria 3 — Halaman Prediksi', 'MealDB API · Gemini AI Nutrisi'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Checklist Submission', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...criteria.map((c) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.tertiary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.tertiary.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Text(c.$1, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.$2, style: Theme.of(context).textTheme.titleMedium),
                    Text(c.$3, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1)),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String icon, title, subtitle;
  final Widget? trailing;
  const _SettingTile({required this.icon, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool active;
  const _StatusDot({required this.active});
  @override
  Widget build(BuildContext context) => Container(
    width: 10, height: 10,
    decoration: BoxDecoration(
      color: active ? AppColors.success : AppColors.error,
      shape: BoxShape.circle,
    ),
  );
}
