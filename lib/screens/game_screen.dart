import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../assets.dart';
import '../game/flight_engine.dart';
import '../game/game_config.dart';
import '../game/models.dart';
import '../theme.dart';
import '../widgets/hud_bar.dart';
import '../widgets/painters.dart';

/// Floating-controls archetype: HUD strip on top, five-corridor play field in
/// the middle, a detached control pod above the bottom edge.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.options,
    required this.onGameOver,
    required this.onExit,
  });

  final RouteOptions options;
  final ValueChanged<FlightResult> onGameOver;
  final VoidCallback onExit;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final FlightEngine _engine;
  late final Ticker _ticker;

  Timer? _hardAbort;
  Duration _lastTick = Duration.zero;
  bool _finished = false;
  bool _showHint = true;

  static const double _gameTop = GameConfig.headerHeight + 44;

  @override
  void initState() {
    super.initState();
    _engine = FlightEngine(options: widget.options);
    _ticker = createTicker(_onTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _ticker.start();

      // Hard failsafe from the first painted frame. Never re-armed on input —
      // re-arming is what starves the result frame on an untouched run.
      _hardAbort = Timer(
        const Duration(seconds: GameConfig.hardAbortSec),
        () => _finish(forcedSuccess: false),
      );

      Timer(
        const Duration(milliseconds: 2500),
        () {
          if (mounted) {
            setState(() => _showHint = false);
          }
        },
      );
    });
  }

  void _onTick(Duration elapsed) {
    final double dt = _lastTick == Duration.zero
        ? 1 / 60
        : (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (dt <= 0) {
      return;
    }
    _engine.update(math.min(dt, 1 / 20));
    if (_engine.isOver) {
      _finish();
      return;
    }
    setState(() {});
  }

  void _finish({bool? forcedSuccess}) {
    if (_finished) {
      return;
    }
    _finished = true;
    _ticker.stop();
    _hardAbort?.cancel();
    widget.onGameOver(_engine.buildResult(forcedSuccess: forcedSuccess));
  }

  @override
  void dispose() {
    _hardAbort?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final double controlsReserve = GameConfig.controlsReserve + bottomInset;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;
          final double areaHeight = height - _gameTop - controlsReserve;
          final double laneHeight =
              ((areaHeight - 2 * GameConfig.gridFrame) / GameConfig.lanes)
                  .floorToDouble();

          _engine.setLayout(
            width: width,
            gameTop: _gameTop,
            laneHeight: math.max(1.0, laneHeight),
          );

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AppAssets.bgGame),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SizedBox.expand(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.bgBase.withValues(alpha: 0.45),
                ),
                child: const SizedBox.expand(),
              ),
              ..._buildClouds(),
              CustomPaint(
                painter: CorridorGridPainter(
                  lanes: GameConfig.lanes,
                  laneHeight: math.max(1.0, laneHeight),
                  top: _gameTop,
                  frame: GameConfig.gridFrame,
                  offset: _engine.distancePx * 0.45,
                ),
                size: Size.infinite,
              ),
              if (_engine.landingX != null) _buildLandingZone(laneHeight),
              ..._buildGates(laneHeight),
              ..._buildMarkers(),
              ..._buildStorms(),
              ..._buildEffects(),
              _buildPlane(laneHeight),
              if (_engine.hitFlash > 0)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(
                        alpha: 0.30 * (_engine.hitFlash / 0.18),
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragEnd: (DragEndDetails details) {
                  final double velocity =
                      details.velocity.pixelsPerSecond.dy;
                  if (velocity < -80) {
                    _engine.changeLane(-1);
                  } else if (velocity > 80) {
                    _engine.changeLane(1);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    top: _gameTop,
                    bottom: controlsReserve,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: HudBar(
                  targetColor: AppColors.gateColors[
                      _engine.targetColor % AppColors.gateColors.length],
                  markers: _engine.markers,
                  hits: _engine.hits,
                  onBack: widget.onExit,
                ),
              ),
              if (_showHint)
                Positioned(
                  top: _gameTop + 16,
                  left: 24,
                  right: 24,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgDeep.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.accentSky.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'SWIPE OR TAP UP / DOWN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            height: 1.2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24 + bottomInset,
                child: _buildControls(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── layers ───────────────────────────────────────────────────────────────

  List<Widget> _buildClouds() {
    return <Widget>[
      for (final CloudEntity cloud in _engine.clouds)
        Positioned(
          left: cloud.x,
          top: cloud.y - cloud.size / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: cloud.opacity,
              child: Image.asset(
                AppAssets.spriteCloud,
                width: cloud.size,
                fit: BoxFit.contain,
                errorBuilder: _spriteFallback,
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildGates(double laneHeight) {
    final double gateHeight =
        math.min(GameConfig.gateHeight, math.max(40.0, laneHeight * 0.94));
    final double gateWidth = gateHeight * (GameConfig.gateWidth /
        GameConfig.gateHeight);
    const List<String> gateSprites = <String>[
      AppAssets.spriteGateBlue,
      AppAssets.spriteGateIndigo,
      AppAssets.spriteGateGold,
    ];
    return <Widget>[
      for (final GateEntity gate in _engine.gates)
        Positioned(
          left: gate.x - gateWidth / 2,
          top: _engine.laneCenterY(gate.lane) - gateHeight / 2,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors
                        .gateColors[gate.colorIndex %
                            AppColors.gateColors.length]
                        .withValues(alpha: gate.colorIndex ==
                                _engine.targetColor
                            ? 0.45
                            : 0.18),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Image.asset(
                gateSprites[gate.colorIndex % gateSprites.length],
                width: gateWidth,
                height: gateHeight,
                fit: BoxFit.contain,
                errorBuilder: _spriteFallback,
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildMarkers() {
    const double size = GameConfig.markerSize;
    return <Widget>[
      for (final MarkerEntity marker in _engine.markerItems)
        Positioned(
          left: marker.x - size / 2,
          top: _engine.laneCenterY(marker.lane) - size / 2,
          child: IgnorePointer(
            child: Image.asset(
              AppAssets.spriteMarker,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: _spriteFallback,
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildStorms() {
    const double size = GameConfig.stormSize;
    return <Widget>[
      for (final StormEntity storm in _engine.storms)
        Positioned(
          left: storm.x - size / 2,
          top: _engine.laneCenterY(storm.lane) - size / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.75 +
                  0.25 *
                      (0.5 + 0.5 * math.sin(_engine.elapsed * 7 + storm.lane)),
              child: Image.asset(
                AppAssets.spriteStorm,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: _spriteFallback,
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildEffects() {
    return <Widget>[
      for (final EffectEntity effect in _engine.effects)
        if (effect.isMarker)
          Positioned(
            left: effect.x - 24,
            top: effect.y - 26 * (1 - effect.life / 0.5) - 14,
            child: IgnorePointer(
              child: Opacity(
                opacity: (effect.life / 0.5).clamp(0.0, 1.0),
                child: const SizedBox(
                  width: 48,
                  child: Text(
                    '+1',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Positioned(
            left: effect.x - 45,
            top: effect.y - 45,
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size(90, 90),
                painter: RingBurstPainter(
                  progress: (1 - effect.life / 0.42).clamp(0.0, 1.0),
                  color: AppColors.accentSky,
                ),
              ),
            ),
          ),
    ];
  }

  Widget _buildLandingZone(double laneHeight) {
    final double top = _gameTop + GameConfig.gridFrame;
    final double height = laneHeight * GameConfig.lanes;
    return Positioned(
      left: (_engine.landingX ?? 0) - 30,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: 60,
          height: math.max(1.0, height),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                AppColors.accentSky.withValues(alpha: 0.0),
                AppColors.accentSky.withValues(alpha: 0.55),
                AppColors.accentSky.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlane(double laneHeight) {
    final double planeWidth =
        math.min(GameConfig.planeWidth, math.max(48.0, laneHeight * 1.1));
    final bool blink = _engine.invulnerable &&
        (_engine.elapsed * 7).floor().isEven;
    return Positioned(
      left: _engine.planeX - planeWidth / 2 + _engine.shake,
      top: _engine.planeY - planeWidth / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: blink ? 0.35 : 1.0,
          child: Transform.rotate(
            angle: _engine.tilt,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.accentSky.withValues(alpha: 0.35),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Image.asset(
                AppAssets.spritePlane,
                width: planeWidth,
                height: planeWidth,
                fit: BoxFit.contain,
                errorBuilder: _spriteFallback,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accentSky.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.bgDeep.withValues(alpha: 0.55),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _laneButton('UP', Icons.keyboard_arrow_up, -1),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'DIST  ${_engine.distancePx.round()} M',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    height: 1.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GATES  ${_engine.gatesMissed}/${GameConfig.maxGateMisses} MISSED',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    height: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _laneButton('DOWN', Icons.keyboard_arrow_down, 1),
        ],
      ),
    );
  }

  Widget _laneButton(String label, IconData icon, int delta) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: AppColors.accentSky.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _engine.changeLane(delta),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentSky, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 24, color: AppColors.textPrimary),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    height: 1.1,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _spriteFallback(BuildContext context, Object error, StackTrace? stack) {
  return const SizedBox.shrink();
}
