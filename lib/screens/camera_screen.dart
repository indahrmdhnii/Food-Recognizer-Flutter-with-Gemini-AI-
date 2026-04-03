// lib/screens/camera_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../services/ml_service.dart';
import '../models/food_prediction.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isCapturing = false;
  List<FoodPrediction> _livePredictions = [];
  int _frameCount = 0;
  static const int _inferenceEvery = 25;
  int _cameraIndex = 0;

  final MLService _mlService = MLService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() { _controller = controller; _isInitialized = true; });
      // Kriteria 1 - Advanced: start live image stream
      _controller!.startImageStream(_onCameraFrame);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _onCameraFrame(CameraImage image) {
    _frameCount++;
    if (_frameCount % _inferenceEvery != 0 || _isProcessing) return;
    _isProcessing = true;
    _mlService.classifyFrame(image).then((results) {
      if (mounted && results.isNotEmpty) {
        setState(() => _livePredictions = results);
      }
      _isProcessing = false;
    // ignore: invalid_return_type_for_catch_error
    }).catchError((_) => _isProcessing = false);
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _controller?.stopImageStream();
    await _controller?.dispose();
    _isInitialized = false;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _initCamera();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      await _controller!.stopImageStream();
      final file = await _controller!.takePicture();
      if (mounted) Navigator.pop(context, file.path);
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          // Dark vignette overlay + scanner rect
          CustomPaint(painter: _ScannerPainter()),

          // Live prediction chips
          if (_livePredictions.isNotEmpty) _buildLiveChips(),

          // Top bar
          _buildTopBar(),

          // Bottom controls
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _CircleBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
                      .animate(onPlay: (c) => c.repeat()).fadeIn(duration: 500.ms).then().fadeOut(duration: 500.ms),
                  const SizedBox(width: 6),
                  const Text('Live AI', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveChips() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.13,
      left: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _livePredictions.take(3).map((p) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.primary.withOpacity(0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(p.displayLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.8), borderRadius: BorderRadius.circular(10)),
                child: Text(p.confidencePercent, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 250.ms)).toList(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(40, 20, 40, 50),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.85), Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            Text('Arahkan kamera ke makanan',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_cameras.length > 1)
                  _CircleBtn(icon: Icons.flip_camera_ios_rounded, onTap: _flipCamera)
                else
                  const SizedBox(width: 52),
                const SizedBox(width: 32),
                // Shutter button
                GestureDetector(
                  onTap: _capture,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: _isCapturing ? 72 : 80,
                    height: _isCapturing ? 72 : 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.lavender],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 20, spreadRadius: 4)],
                    ),
                    child: const Icon(Icons.camera_rounded, color: Colors.white, size: 36),
                  ),
                ).animate(onPlay: (c) => c.repeat())
                    .scaleXY(begin: 1.0, end: 1.05, duration: 1200.ms, curve: Curves.easeInOut)
                    .then().scaleXY(end: 1.0, duration: 1200.ms),
                const SizedBox(width: 32),
                const SizedBox(width: 52),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52, height: 52,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 22),
    ),
  );
}

class _ScannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withOpacity(0.45);
    const boxSize = 260.0;
    final cx = size.width / 2, cy = size.height / 2 - 30;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: boxSize, height: boxSize);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(18));

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlay);

    // Border
    canvas.drawRRect(rRect, Paint()..color = AppColors.primary.withOpacity(0.8)..strokeWidth = 2..style = PaintingStyle.stroke);

    // Corners
    final c = Paint()..color = AppColors.primary..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const len = 28.0; const r = 18.0;
    // TL
    canvas.drawLine(Offset(rect.left + r, rect.top), Offset(rect.left + len, rect.top), c);
    canvas.drawLine(Offset(rect.left, rect.top + r), Offset(rect.left, rect.top + len), c);
    // TR
    canvas.drawLine(Offset(rect.right - len, rect.top), Offset(rect.right - r, rect.top), c);
    canvas.drawLine(Offset(rect.right, rect.top + r), Offset(rect.right, rect.top + len), c);
    // BL
    canvas.drawLine(Offset(rect.left + r, rect.bottom), Offset(rect.left + len, rect.bottom), c);
    canvas.drawLine(Offset(rect.left, rect.bottom - len), Offset(rect.left, rect.bottom - r), c);
    // BR
    canvas.drawLine(Offset(rect.right - len, rect.bottom), Offset(rect.right - r, rect.bottom), c);
    canvas.drawLine(Offset(rect.right, rect.bottom - len), Offset(rect.right, rect.bottom - r), c);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
