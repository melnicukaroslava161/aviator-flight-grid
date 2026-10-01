import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../theme.dart';
import '../widgets/painters.dart';

/// Branded splash. Deliberately darker and flatter than the menu so the two
/// frames can never be mistaken for one another, and deliberately *finite* —
/// every animation here runs once and then the screen holds still.
class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen>
    with SingleTickerProviderStateMixin {
  static const int _segments = 5;
  static const int _grainLayers = 3;
  static const int _grainPerLayer = 8800;

  late final AnimationController _intro;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  Timer? _doneTimer;
  Timer? _progressTimer;
  int _activeSegments = 1;

  final List<Offset> _stars = <Offset>[];
  List<Float32List>? _grain;

  @override
  void initState() {
    super.initState();

    final math.Random rng = math.Random(90210);
    for (int i = 0; i < 70; i++) {
      _stars.add(Offset(rng.nextDouble(), rng.nextDouble()));
    }

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
    );

    // Everything below starts from the FIRST PAINTED FRAME, never from
    // initState — a cold start on a loaded emulator can swallow seconds
    // before the splash is actually on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _intro.forward();
      _buildGrain();

      _doneTimer = Timer(
        const Duration(milliseconds: GameConfig.loaderDurationMs),
        () {
          if (mounted) {
            widget.onDone();
          }
        },
      );

      const int step = GameConfig.loaderDurationMs ~/ _segments;
      _progressTimer = Timer.periodic(
        const Duration(milliseconds: step),
        (Timer timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          if (_activeSegments >= _segments) {
            timer.cancel();
            return;
          }
          setState(() => _activeSegments++);
        },
      );
    });
  }

  /// Full-canvas noise built once, off the first frame. It carries the splash's
  /// texture and keeps its encoded weight well clear of the menu's.
  void _buildGrain() {
    final Size size = MediaQuery.sizeOf(context);
    if (size.isEmpty) {
      return;
    }
    final math.Random rng = math.Random(4242);
    final List<Float32List> layers = <Float32List>[];
    for (int layer = 0; layer < _grainLayers; layer++) {
      final Float32List points = Float32List(_grainPerLayer * 2);
      for (int i = 0; i < _grainPerLayer; i++) {
        points[i * 2] = rng.nextDouble() * size.width;
        points[i * 2 + 1] = rng.nextDouble() * size.height;
      }
      layers.add(points);
    }
    if (mounted) {
      setState(() => _grain = layers);
    }
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    _progressTimer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.bgDeep,
              AppColors.bgMid,
              AppColors.bgBase,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            RepaintBoundary(
              child: CustomPaint(
                painter: NightSkyPainter(stars: _stars, grain: _grain),
                size: Size.infinite,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 44, 28, 36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Spacer(),
                    FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  const CustomPaint(
                                    painter: RadarArcPainter(),
                                    size: Size(220, 220),
                                  ),
                                  Image.asset(
                                    AppAssets.spritePlane,
                                    width: 132,
                                    height: 132,
                                    fit: BoxFit.contain,
                                    errorBuilder: _spriteFallback,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'AVIATOR',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'FLIGHT GRID',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 10,
                                height: 1.2,
                                color: AppColors.accentSky,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'FIVE CORRIDORS · 25 MARKERS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.4,
                                height: 1.3,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        for (int i = 0; i < _segments; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: i < _activeSegments
                                    ? AppColors.accentSky
                                    : AppColors.surfaceAlt,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'LOADING…',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                        height: 1.3,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _spriteFallback(BuildContext context, Object error, StackTrace? stack) {
  return const SizedBox.shrink();
}
