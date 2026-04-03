// lib/widgets/confidence_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

class ConfidenceBar extends StatelessWidget {
  final String label;
  final double confidence;
  final bool isTop;

  const ConfidenceBar({
    super.key,
    required this.label,
    required this.confidence,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isTop ? AppColors.primary : AppColors.secondary;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              if (isTop) const Padding(padding: EdgeInsets.only(right: 6), child: Text('🏆', style: TextStyle(fontSize: 13))),
              Text(label, style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: isTop ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.textPrimary,
              )),
            ]),
            Text(
              '${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }
}
