import 'dart:math' as math;

import 'game_config.dart';
import 'models.dart';

/// dt-driven simulation for one flight. Owns spawning, collisions, scoring and
/// the no-input backstop. Holds no Flutter types so it stays trivially testable.
class FlightEngine {
  FlightEngine({required this.options}) : _rng = math.Random(20261001);

  final RouteOptions options;
  final math.Random _rng;

  // ── layout, pushed in from the widget once constraints are known ──────────
  double width = 0;
  double gameTop = 0;
  double laneHeight = 0;
  double planeX = 0;

  // ── run state ────────────────────────────────────────────────────────────
  GameState state = GameState.idle;
  double elapsed = 0;
  double distancePx = 0;

  int markers = 0;
  int gatesPassed = 0;
  int gatesMissed = 0;
  int hits = 0;
  int targetColor = 0;

  int lane = GameConfig.idleLane;
  double laneValue = GameConfig.idleLane.toDouble();
  double tilt = 0;

  double invulnerableLeft = 0;
  double hitFlash = 0;
  double shake = 0;
  double landingProgress = 0;

  bool get isOver => state == GameState.over;
  bool succeeded = false;

  final List<GateEntity> gates = <GateEntity>[];
  final List<MarkerEntity> markerItems = <MarkerEntity>[];
  final List<StormEntity> storms = <StormEntity>[];
  final List<CloudEntity> clouds = <CloudEntity>[];
  final List<EffectEntity> effects = <EffectEntity>[];

  double? landingX;

  // ── internals ────────────────────────────────────────────────────────────
  double _laneFrom = GameConfig.idleLane.toDouble();
  double _laneTo = GameConfig.idleLane.toDouble();
  double _laneT = 1;

  double _gateAcc = 0;
  double _stormAcc = 0;
  double _markerTimer = 0;
  int _gateGroup = 0;
  int _markerIndex = 0;
  bool _landingSpawned = false;

  /// Lanes the target gate occupies, group by group. The opening lanes sit on
  /// [GameConfig.idleLane] so a still plane scores a few passes before the
  /// route drifts away from it.
  static const List<int> _targetGateLanes = <int>[2, 2, 2, 1, 3, 0, 2, 4, 1, 3];
  static const List<int> _markerLanes = <int>[2, 1, 2, 3, 2, 0, 4];

  final List<double> _scriptedHits = <double>[
    GameConfig.idleFirstHitSec.toDouble(),
    GameConfig.idleSecondHitSec.toDouble(),
    GameConfig.idleThirdHitSec.toDouble(),
  ];

  double get scrollSpeed {
    if (state == GameState.landing) {
      return options.scrollPxPerSec * (1 - landingProgress).clamp(0.0, 1.0);
    }
    return options.scrollPxPerSec;
  }

  int get distanceKm => (distancePx / 1000).floor();

  int get score {
    final int raw = markers * 40 + gatesPassed * 25 + distanceKm * 3;
    return (raw * options.scoreMultiplier).round();
  }

  bool get invulnerable => invulnerableLeft > 0;

  double laneCenterY(int index) =>
      gameTop + GameConfig.gridFrame + laneHeight * index + laneHeight / 2;

  double laneCenterYFor(double value) =>
      gameTop + GameConfig.gridFrame + laneHeight * value + laneHeight / 2;

  double get planeY => laneCenterYFor(laneValue);

  FlightResult buildResult({bool? forcedSuccess}) {
    return FlightResult(
      success: forcedSuccess ?? succeeded,
      markers: markers,
      gatesPassed: gatesPassed,
      gatesMissed: gatesMissed,
      distanceKm: distanceKm,
      score: score,
    );
  }

  void setLayout({
    required double width,
    required double gameTop,
    required double laneHeight,
  }) {
    this.width = width;
    this.gameTop = gameTop;
    this.laneHeight = laneHeight;
    planeX = width * GameConfig.planeXFraction;
    if (clouds.isEmpty) {
      _seedClouds();
    }
  }

  void _seedClouds() {
    for (int i = 0; i < 4; i++) {
      clouds.add(
        CloudEntity(
          x: width * (0.2 + 0.26 * i),
          y: laneCenterY(i % GameConfig.lanes),
          size: 120 + _rng.nextDouble() * 90,
          opacity: 0.35 + _rng.nextDouble() * 0.25,
        ),
      );
    }
  }

  void changeLane(int delta) {
    if (state != GameState.flying && state != GameState.hit) {
      return;
    }
    final int next = (lane + delta).clamp(0, GameConfig.lanes - 1);
    if (next == lane) {
      return;
    }
    lane = next;
    _laneFrom = laneValue;
    _laneTo = next.toDouble();
    _laneT = 0;
  }

  void update(double dt) {
    if (state == GameState.over || laneHeight <= 0) {
      return;
    }

    elapsed += dt;

    if (state == GameState.idle && elapsed >= GameConfig.introSec) {
      state = GameState.flying;
    }

    final double speed = scrollSpeed;
    distancePx += speed * dt;

    _advanceLaneTween(dt);
    _decayEffects(dt);

    _spawnGates(speed * dt);
    _spawnMarkers(dt);
    _spawnStorms(speed * dt);
    _scheduleScriptedStorms(speed);
    _driftClouds(speed * dt);

    _moveAndResolve(speed * dt);

    if (state == GameState.landing) {
      landingProgress = (landingProgress + dt / 1.0).clamp(0.0, 1.0);
      if (landingProgress >= 1) {
        succeeded = true;
        state = GameState.over;
      }
      return;
    }

    if (hits >= GameConfig.maxHits ||
        gatesMissed >= GameConfig.maxGateMisses) {
      succeeded = false;
      state = GameState.over;
    }
  }

  void _advanceLaneTween(double dt) {
    if (_laneT < 1) {
      _laneT =
          (_laneT + dt * 1000 / GameConfig.laneSwitchMs).clamp(0.0, 1.0);
      final double eased = _easeOutCubic(_laneT);
      laneValue = _laneFrom + (_laneTo - _laneFrom) * eased;
      final double direction = _laneTo > _laneFrom ? 1 : -1;
      tilt = 0.14 * direction * math.sin(math.pi * _laneT);
    } else {
      laneValue = _laneTo;
      tilt = tilt * (1 - (dt * 6).clamp(0.0, 1.0));
    }

    if (invulnerableLeft > 0) {
      invulnerableLeft = math.max(0.0, invulnerableLeft - dt);
    }
    if (hitFlash > 0) {
      hitFlash = math.max(0.0, hitFlash - dt);
      shake = hitFlash > 0 ? math.sin(elapsed * 60) * 6 * (hitFlash / 0.18) : 0.0;
      if (hitFlash == 0 && state == GameState.hit) {
        state = GameState.flying;
        shake = 0;
      }
    }
  }

  void _decayEffects(double dt) {
    for (int i = effects.length - 1; i >= 0; i--) {
      effects[i].life -= dt;
      if (effects[i].life <= 0) {
        effects.removeAt(i);
      }
    }
  }

  void _spawnGates(double travelled) {
    _gateAcc += travelled;
    if (_gateAcc < GameConfig.gateIntervalPx || width <= 0) {
      return;
    }
    _gateAcc = 0;

    targetColor = _gateGroup % AppGateColors.count;
    final int targetLane =
        _targetGateLanes[_gateGroup % _targetGateLanes.length];
    final double spawnX = width + GameConfig.gateWidth;

    gates.add(
      GateEntity(x: spawnX, lane: targetLane, colorIndex: targetColor),
    );

    // One decoy in a different lane with a different colour.
    int decoyLane = (targetLane + 2) % GameConfig.lanes;
    if (decoyLane == targetLane) {
      decoyLane = (targetLane + 1) % GameConfig.lanes;
    }
    gates.add(
      GateEntity(
        x: spawnX,
        lane: decoyLane,
        colorIndex: (targetColor + 1) % AppGateColors.count,
      ),
    );

    _gateGroup++;
  }

  void _spawnMarkers(double dt) {
    if (width <= 0) {
      return;
    }
    _markerTimer += dt;
    if (_markerTimer < GameConfig.markerIntervalSec) {
      return;
    }
    _markerTimer = 0;
    final int markerLane = _markerLanes[_markerIndex % _markerLanes.length];
    _markerIndex++;
    markerItems.add(
      MarkerEntity(x: width + GameConfig.markerSize, lane: markerLane),
    );
  }

  void _spawnStorms(double travelled) {
    if (width <= 0) {
      return;
    }
    _stormAcc += travelled;
    final double interval = GameConfig.gateIntervalPx / options.stormDensity;
    if (_stormAcc < interval) {
      return;
    }
    _stormAcc = 0;

    int stormLane = _rng.nextInt(GameConfig.lanes);
    if (elapsed < GameConfig.idleLaneProtectSec &&
        stormLane == GameConfig.idleLane) {
      stormLane = (stormLane + 1) % GameConfig.lanes;
    }
    storms.add(
      StormEntity(x: width + GameConfig.stormSize, lane: stormLane),
    );
  }

  /// Places lane-[GameConfig.idleLane] storms so they reach the plane at exactly
  /// the scripted marks even though scroll speed depends on the route options.
  void _scheduleScriptedStorms(double speed) {
    if (_scriptedHits.isEmpty || width <= 0 || speed <= 0) {
      return;
    }
    final double leadSec = (width - planeX + 60) / speed;
    final double next = _scriptedHits.first;
    if (elapsed < next - leadSec) {
      return;
    }
    _scriptedHits.removeAt(0);
    final double travel = math.max(0.0, next - elapsed) * speed;
    storms.add(
      StormEntity(x: planeX + travel, lane: GameConfig.idleLane, scripted: true),
    );
  }

  void _driftClouds(double travelled) {
    for (final CloudEntity cloud in clouds) {
      cloud.x -= travelled * 0.7;
      if (cloud.x < -cloud.size) {
        cloud.x = width + cloud.size * 0.5;
      }
    }
  }

  void _moveAndResolve(double travelled) {
    final double planeLane = laneValue;

    for (int i = gates.length - 1; i >= 0; i--) {
      final GateEntity gate = gates[i];
      gate.x -= travelled;
      if (!gate.resolved && gate.x <= planeX) {
        gate.resolved = true;
        if (gate.colorIndex == targetColor) {
          if ((gate.lane - planeLane).abs() < 0.55) {
            gatesPassed++;
            effects.add(
              EffectEntity(
                x: planeX,
                y: laneCenterY(gate.lane),
                life: 0.42,
                isMarker: false,
              ),
            );
          } else {
            gatesMissed++;
          }
        }
      }
      if (gate.x < -GameConfig.gateWidth * 2) {
        gates.removeAt(i);
      }
    }

    for (int i = markerItems.length - 1; i >= 0; i--) {
      final MarkerEntity marker = markerItems[i];
      marker.x -= travelled;
      if (!marker.collected &&
          (marker.x - planeX).abs() < 32 &&
          (marker.lane - planeLane).abs() < 0.6) {
        marker.collected = true;
        markers++;
        effects.add(
          EffectEntity(
            x: planeX,
            y: laneCenterY(marker.lane),
            life: 0.5,
            isMarker: true,
          ),
        );
        markerItems.removeAt(i);
        continue;
      }
      if (marker.x < -GameConfig.markerSize * 2) {
        markerItems.removeAt(i);
      }
    }

    for (int i = storms.length - 1; i >= 0; i--) {
      final StormEntity storm = storms[i];
      storm.x -= travelled;
      if (!storm.consumed &&
          !invulnerable &&
          state != GameState.landing &&
          (storm.x - planeX).abs() < 40 &&
          (storm.lane - planeLane).abs() < 0.55) {
        storm.consumed = true;
        hits++;
        invulnerableLeft = GameConfig.invulnerableMs / 1000;
        hitFlash = 0.18;
        state = GameState.hit;
      }
      if (storm.x < -GameConfig.stormSize * 2) {
        storms.removeAt(i);
      }
    }

    if (!_landingSpawned && markers >= GameConfig.targetMarkers) {
      _landingSpawned = true;
      landingX = width + 200;
    }
    if (landingX != null && state != GameState.landing) {
      landingX = landingX! - travelled;
      if (landingX! <= planeX) {
        state = GameState.landing;
        landingProgress = 0;
      }
    }
  }

  double _easeOutCubic(double t) {
    final double inv = 1 - t;
    return 1 - inv * inv * inv;
  }
}

/// Number of distinct gate colours (kept here so the engine has no Flutter
/// import just to count palette entries).
class AppGateColors {
  const AppGateColors._();

  static const int count = 3;
}
