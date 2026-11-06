import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// AnimationController ile döndürülen basit bir 3B küp.
/// Sadece Sohbet 3'te gösterilir.
class RotatingCube3D extends StatefulWidget {
  const RotatingCube3D({super.key, this.size = 130});

  /// Testlerde sonsuz animasyonu kapatmak için kullanılır.
  static bool animationsEnabled = true;

  final double size;

  @override
  State<RotatingCube3D> createState() => _RotatingCube3DState();
}

class _RotatingCube3DState extends State<RotatingCube3D>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (RotatingCube3D.animationsEnabled) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 6),
      )..repeat();
    } else {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double half = widget.size / 2;

    return SizedBox(
      height: widget.size + 40,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller!,
          builder: (BuildContext context, Widget? child) {
            final double angle = _controller!.value * 2 * math.pi;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(angle * 0.7)
                ..rotateY(angle),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  children: <Widget>[
                    _CubeFace(
                      transform: Matrix4.translationValues(0, 0, half),
                      color: AppColors.primary,
                      label: 'ÖN',
                    ),
                    _CubeFace(
                      transform: Matrix4.translationValues(0, 0, -half)
                        ..rotateY(math.pi),
                      color: AppColors.cyan,
                      label: 'ARKA',
                    ),
                    _CubeFace(
                      transform: Matrix4.translationValues(half, 0, 0)
                        ..rotateY(math.pi / 2),
                      color: AppColors.amber,
                      label: 'SAĞ',
                    ),
                    _CubeFace(
                      transform: Matrix4.translationValues(-half, 0, 0)
                        ..rotateY(-math.pi / 2),
                      color: const Color(0xFF34D399),
                      label: 'SOL',
                    ),
                    _CubeFace(
                      transform: Matrix4.translationValues(0, -half, 0)
                        ..rotateX(math.pi / 2),
                      color: const Color(0xFFF472B6),
                      label: 'ÜST',
                    ),
                    _CubeFace(
                      transform: Matrix4.translationValues(0, half, 0)
                        ..rotateX(-math.pi / 2),
                      color: const Color(0xFF60A5FA),
                      label: 'ALT',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CubeFace extends StatelessWidget {
  const _CubeFace({
    required this.transform,
    required this.color,
    required this.label,
  });

  final Matrix4 transform;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0.55),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
