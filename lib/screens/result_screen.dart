// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/food_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/confidence_bar.dart';
import '../widgets/ingredient_chip.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Consumer<FoodProvider>(
          builder: (_, provider, __) => CustomScrollView(
            slivers: [
              _SliverImageAppBar(provider: provider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _PredictionHeader(provider: provider),
                      const SizedBox(height: 20),
                      _ConfidenceSection(provider: provider),
                      const SizedBox(height: 24),
                      _NutritionSection(provider: provider),
                      const SizedBox(height: 24),
                      _MealSection(provider: provider),
                      const SizedBox(height: 32),
                      _ActionButtons(provider: provider),
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

// ─── Sliver App Bar ───────────────────────────────────────────────
class _SliverImageAppBar extends StatelessWidget {
  final FoodProvider provider;
  const _SliverImageAppBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (provider.selectedImage != null)
              Image.file(provider.selectedImage!, fit: BoxFit.cover)
            else
              Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 64))),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.background.withOpacity(0.9)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Prediction Header ────────────────────────────────────────────
class _PredictionHeader extends StatelessWidget {
  final FoodProvider provider;
  const _PredictionHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final p = provider.topPrediction;
    if (p == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _Badge(label: '✨ AI Terdeteksi', bg: AppColors.primary.withOpacity(0.2), fg: AppColors.primary),
            if (provider.isModelFromCloud)
              _Badge(label: '☁️ Firebase ML', bg: AppColors.tertiary.withOpacity(0.3), fg: const Color(0xFF0F6E56)),
          ],
        ),
        const SizedBox(height: 12),
        Text(p.displayLabel, style: Theme.of(context).textTheme.displayMedium)
            .animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
        const SizedBox(height: 4),
        Text(
          provider.mealInfo != null
              ? '${provider.mealInfo!.strCategory ?? "Food"} · ${provider.mealInfo!.strArea ?? "International"}'
              : 'Memuat informasi...',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Badge({required this.label, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
  );
}

// ─── Confidence Bars ──────────────────────────────────────────────
class _ConfidenceSection extends StatelessWidget {
  final FoodProvider provider;
  const _ConfidenceSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎯 Tingkat Keyakinan', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...provider.predictions.take(3).map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ConfidenceBar(
              label: p.displayLabel,
              confidence: p.confidence,
              isTop: p == provider.predictions.first,
            ),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1);
  }
}

// ─── Nutrition (Gemini) ───────────────────────────────────────────
class _NutritionSection extends StatelessWidget {
  final FoodProvider provider;
  const _NutritionSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final n = provider.nutritionInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('⚡ Informasi Nutrisi', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            _Badge(
              label: '✨ Gemini AI',
              bg: AppColors.lavender.withOpacity(0.25),
              fg: const Color(0xFF3C3489),
            ),
          ],
        ),
        if (n == null) ...[
          const SizedBox(height: 10),
          _LoadingCard(color: AppColors.lavender, message: 'Memuat nutrisi dari Gemini AI...'),
        ] else ...[
          const SizedBox(height: 4),
          Text('Per ${n.servingSize}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: NutritionCard(label: 'Kalori', value: n.calories.toStringAsFixed(0), unit: 'kcal', color: AppColors.primary, icon: '🔥')),
              const SizedBox(width: 10),
              Expanded(child: NutritionCard(label: 'Karbohidrat', value: n.carbohydrates.toStringAsFixed(1), unit: 'g', color: AppColors.accent, icon: '🌾')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: NutritionCard(label: 'Protein', value: n.protein.toStringAsFixed(1), unit: 'g', color: AppColors.secondary, icon: '💪')),
              const SizedBox(width: 10),
              Expanded(child: NutritionCard(label: 'Lemak', value: n.fat.toStringAsFixed(1), unit: 'g', color: AppColors.lavender, icon: '🥑')),
              const SizedBox(width: 10),
              Expanded(child: NutritionCard(label: 'Serat', value: n.fiber.toStringAsFixed(1), unit: 'g', color: AppColors.tertiary, icon: '🥦')),
            ],
          ),
        ],
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }
}

// ─── Meal Info (MealDB) ───────────────────────────────────────────
class _MealSection extends StatelessWidget {
  final FoodProvider provider;
  const _MealSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final meal = provider.mealInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('🍳 Resep & Info', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            _Badge(label: 'MealDB', bg: AppColors.accent.withOpacity(0.3), fg: const Color(0xFF854F0B)),
          ],
        ),
        const SizedBox(height: 14),

        if (meal == null)
          _LoadingCard(color: AppColors.accent, message: 'Mencari resep dari MealDB...')
        else ...[
          if (meal.strMealThumb != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: meal.strMealThumb!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 180,
                  color: AppColors.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 180,
                  color: AppColors.surfaceVariant,
                  child: const Center(child: Text('🍴', style: TextStyle(fontSize: 48))),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(meal.strMeal, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('🧂 Bahan-bahan', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(
              meal.ingredients.length,
              (i) => IngredientChip(ingredient: meal.ingredients[i], measure: meal.measures[i]),
            ),
          ),
          if (meal.strInstructions != null) ...[
            const SizedBox(height: 20),
            Text('📋 Cara Membuat', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _InstructionsCard(instructions: meal.strInstructions!),
          ],
        ],
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 500.ms);
  }
}

class _InstructionsCard extends StatefulWidget {
  final String instructions;
  const _InstructionsCard({required this.instructions});
  @override
  State<_InstructionsCard> createState() => _InstructionsCardState();
}

class _InstructionsCardState extends State<_InstructionsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.instructions,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
            maxLines: _expanded ? null : 6,
            overflow: _expanded ? null : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Tampilkan lebih sedikit ▲' : 'Tampilkan semua ▼',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final FoodProvider provider;
  const _ActionButtons({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              provider.reset();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Scan Makanan Lain'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Kembali ke Home'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final Color color;
  final String message;
  const _LoadingCard({required this.color, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color)),
          const SizedBox(width: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
