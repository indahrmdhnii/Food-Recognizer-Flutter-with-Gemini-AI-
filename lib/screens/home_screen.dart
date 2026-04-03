// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../utils/app_theme.dart';
import 'camera_screen.dart';
import 'result_screen.dart';
import '../widgets/pastel_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodProvider>().initializeModel();
    });
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image != null && mounted) await _cropAndProcess(image.path);
  }

  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (image != null && mounted) await _cropAndProcess(image.path);
  }

  Future<void> _openLiveCamera() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (result != null && mounted) await _processImage(result);
  }

  // Kriteria 1 - Skilled: crop image using image_cropper
  Future<void> _cropAndProcess(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Gambar',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Gambar',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
          ],
        ),
      ],
    );
    await _processImage(croppedFile?.path ?? imagePath);
  }

  Future<void> _processImage(String path) async {
    final provider = context.read<FoodProvider>();
    await provider.classifyImage(File(path));

    if (!mounted) return;

    if (provider.state == AppState.success) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const ResultScreen(),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      );
    } else if (provider.state == AppState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Terjadi kesalahan'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Consumer<FoodProvider>(
            builder: (_, provider, __) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(provider),
                        const SizedBox(height: 28),
                        _buildHeroCard(),
                        const SizedBox(height: 28),
                        _buildActionButtons(),
                        const SizedBox(height: 28),
                        _buildHowItWorks(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  // Loading overlay
                  if (provider.state == AppState.loading)
                    _buildLoadingOverlay(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FoodProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FoodLens 🍽️', style: Theme.of(context).textTheme.displayMedium)
                .animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
            Text('Kenali makananmu dengan AI', style: Theme.of(context).textTheme.bodyMedium)
                .animate().fadeIn(delay: 200.ms),
          ],
        ),
        _buildModelBadge(provider).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildModelBadge(FoodProvider provider) {
    if (!provider.isModelReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 6),
            Text('Memuat...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: provider.isModelFromCloud ? AppColors.tertiary : AppColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            provider.isModelFromCloud ? Icons.cloud_done_rounded : Icons.phone_android_rounded,
            size: 13,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            provider.isModelFromCloud ? 'Cloud ML' : 'Local ML',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB5C8), Color(0xFFD4B5FF), Color(0xFFB5D8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            'Identifikasi Makanan\ndengan AI',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              shadows: [Shadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Foto makananmu dan dapatkan resep\nserta informasi nutrisi lengkap!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 700.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Metode', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: PastelButton(
                icon: Icons.photo_library_rounded,
                label: 'Galeri',
                color: AppColors.secondary,
                onTap: _pickFromGallery,
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PastelButton(
                icon: Icons.camera_alt_rounded,
                label: 'Kamera',
                color: AppColors.primary,
                onTap: _pickFromCamera,
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PastelButton(
                icon: Icons.videocam_rounded,
                label: 'Live',
                color: AppColors.lavender,
                onTap: _openLiveCamera,
                badge: 'AI',
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      {'emoji': '📸', 'title': 'Ambil Foto', 'desc': 'Foto atau pilih dari galeri', 'color': AppColors.accent},
      {'emoji': '🧠', 'title': 'Analisis AI', 'desc': 'Model ML mengidentifikasi makanan', 'color': AppColors.secondary},
      {'emoji': '📊', 'title': 'Lihat Info', 'desc': 'Resep, nutrisi & detail lengkap', 'color': AppColors.tertiary},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cara Kerja', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        ...steps.asMap().entries.map((e) {
          final step = e.value;
          final color = step['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(step['emoji'] as String, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step['title'] as String, style: Theme.of(context).textTheme.titleMedium),
                        Text(step['desc'] as String, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 800 + e.key * 100)).slideX(begin: 0.1),
          );
        }),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 56, height: 56,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text('Menganalisis makanan...', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Mohon tunggu sebentar', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
