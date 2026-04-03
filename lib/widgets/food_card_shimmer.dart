// lib/widgets/food_card_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FoodCardShimmer extends StatelessWidget {
  const FoodCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
