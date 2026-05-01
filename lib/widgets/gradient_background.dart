import 'package:flutter/material.dart';

import '../config/theme.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.gradient),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _Blob(color: Colors.white.withValues(alpha: 0.15), size: 280),
        ),
        Positioned(
          bottom: -100,
          left: -60,
          child: _Blob(color: Colors.white.withValues(alpha: 0.12), size: 240),
        ),
        SafeArea(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
