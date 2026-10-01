import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Static night sky for the loader: faint stars, three soft nebula blooms and
/// an optional full-canvas grain pass. The grain is what gives the splash a
/// texture (and a byte weight) clearly distinct from the menu artwork.
class NightSkyPainter extends CustomPainter {
  const NightSkyPainter({required this.stars, required this.grain});

  /// Normalised star positions with a radius in the z component.
  final List<Offset> stars;

  /// Pre-built absolute point pairs, or null before the first post-frame pass.
  final List<Float32List>? grain;

  static const List<double> _grainAlpha = <double>[0.06, 0.11, 0.17];
  static const List<double> _grainWidth = <double>[1.8, 1.3, 0.9];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bloom = Paint()..style = PaintingStyle.fill;
    const List<Offset> bloomAt = <Offset>[
      Offset(0.18, 0.22),
      Offset(0.82, 0.38),
      Offset(0.5, 0.86),
    ];
    for (int i = 0; i < bloomAt.length; i++) {
      final Offset center = Offset(
        bloomAt[i].dx * size.width,
        bloomAt[i].dy * size.height,
      );
      final double radius = size.shortestSide * (0.42 + 0.1 * i);
      bloom.shader = ui.Gradient.radial(center, radius, <Color>[
        AppColors.accentSky.withValues(alpha: 0.05),
        AppColors.accentSky.withValues(alpha: 0.0),
      ]);
      canvas.drawCircle(center, radius, bloom);
    }

    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    for (final Offset star in stars) {
      final double radius = 0.6 + (star.dx * 7919 % 10) / 10 * 1.0;
      starPaint.color = AppColors.textPrimary.withValues(
        alpha: 0.25 + (star.dy * 5417 % 10) / 10 * 0.5,
      );
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        radius,
        starPaint,
      );
    }

    final List<Float32List>? layers = grain;
    if (layers != null) {
      for (int i = 0; i < layers.length; i++) {
        final Paint paint = Paint()
          ..color = AppColors.textSecondary.withValues(
            alpha: _grainAlpha[i % _grainAlpha.length],
          )
          ..strokeWidth = _grainWidth[i % _grainWidth.length]
          ..strokeCap = StrokeCap.round;
        canvas.drawRawPoints(ui.PointMode.points, layers[i], paint);
      }
    }
  }

  @override
  bool shouldRepaint(NightSkyPainter oldDelegate) =>
      !identical(oldDelegate.grain, grain) ||
      !identical(oldDelegate.stars, stars);
}

/// Three concentric radar arcs behind the loader's hero sprite.
class RadarArcPainter extends CustomPainter {
  const RadarArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    const List<double> alphas = <double>[0.35, 0.22, 0.12];
    for (int i = 0; i < 3; i++) {
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.accentSky.withValues(alpha: alphas[i]);
      final double radius = size.shortestSide / 2 - 6 - i * 26;
      if (radius <= 0) {
        continue;
      }
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi * 0.08,
        math.pi * 1.84,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(RadarArcPainter oldDelegate) => false;
}

/// The five flight corridors plus the running distance ticks.
class CorridorGridPainter extends CustomPainter {
  const CorridorGridPainter({
    required this.lanes,
    required this.laneHeight,
    required this.top,
    required this.frame,
    required this.offset,
  });

  final int lanes;
  final double laneHeight;
  final double top;
  final double frame;
  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    if (laneHeight <= 0) {
      return;
    }
    final Paint guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.accentSky.withValues(alpha: 0.16);

    for (int i = 0; i <= lanes; i++) {
      final double y = top + frame + laneHeight * i;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + 10, y), guide);
        x += 18;
      }
    }

    final Paint tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.accentSky.withValues(alpha: 0.08);
    final double bottom = top + frame + laneHeight * lanes;
    final double start = -(offset % 80);
    for (double x = start; x < size.width; x += 80) {
      canvas.drawLine(Offset(x, top + frame), Offset(x, bottom), tick);
    }
  }

  @override
  bool shouldRepaint(CorridorGridPainter oldDelegate) =>
      oldDelegate.offset != offset ||
      oldDelegate.laneHeight != laneHeight ||
      oldDelegate.top != top;
}

/// Gate-pass ring burst drawn above the gameplay sprites.
class RingBurstPainter extends CustomPainter {
  const RingBurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: (1 - progress).clamp(0.0, 1.0));
    final double radius =
        size.shortestSide / 2 * (0.6 + progress * 1.0);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(RingBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
