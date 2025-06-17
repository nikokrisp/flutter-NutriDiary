// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedMeshBackground extends StatefulWidget {
  const AnimatedMeshBackground({super.key});

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _MeshGradientPainter(_controller.value),
        );
      },
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  final double t;
  _MeshGradientPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final blue = const Color(0xFF2196F3);
    final green = const Color(0xFF32CD32);
    final waveHeight = 40.0 + 30.0 * t;
    final waveLength = size.width * 0.7;

    // Fallback background to avoid gaps
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = blue.withAlpha((0.9 * 255).toInt()),
    );

    // Top wave
    final topPath = Path()..moveTo(0, 0);
    for (double x = 0; x <= size.width; x += 2) {
      final y = size.height * 0.45 +
          waveHeight * math.sin((x / waveLength + t * 2) * math.pi);
      topPath.lineTo(x, y);
    }
    topPath.lineTo(size.width, 0);
    topPath.close();

    final bluePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          blue,
          Color.lerp(blue, green, 0.5 + 0.2 * (0.5 - (t - 0.5).abs()))!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(topPath, bluePaint);

    // Bottom wave
    final bottomPath = Path()..moveTo(size.width, size.height);
    for (double x = size.width; x >= 0; x -= 2) {
      final y = size.height * 0.45 +
          waveHeight * math.sin((x / waveLength + t * 2) * math.pi);
      bottomPath.lineTo(x, y);
    }
    bottomPath.lineTo(0, size.height);
    bottomPath.close();

    final greenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(blue, green, 0.5 + 0.2 * (0.5 - (t - 0.5).abs()))!,
          green,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(bottomPath, greenPaint);

    // Mesh blobs (reduced opacity and radius)
    final blobPaint1 = Paint()..color = blue.withAlpha((0.10 * 255).toInt());
    final blobPaint2 = Paint()..color = green.withAlpha((0.10 * 255).toInt());

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r1 = size.width * 0.45;
    final r2 = size.width * 0.30;

    final offset1 = Offset(
      cx + r1 * 0.2 * (t - 0.5),
      cy - r1 * 0.4 * (t - 0.5),
    );
    final offset2 = Offset(
      cx - r2 * 0.3 * (t - 0.5),
      size.height - r2 * 0.6,
    );

    canvas.drawCircle(offset1, r1, blobPaint1);
    canvas.drawCircle(offset2, r2, blobPaint2);
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) =>
      oldDelegate.t != t;
}
