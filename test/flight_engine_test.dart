// Contract tests for the no-input backstop. A run that never receives a swipe
// must still be airborne when the capture agent takes its gameplay frame, and
// must still reach a result with enough telemetry to fill the stat row.

import 'package:aviator_flight_grid/game/flight_engine.dart';
import 'package:aviator_flight_grid/game/game_config.dart';
import 'package:aviator_flight_grid/game/models.dart';
import 'package:flutter_test/flutter_test.dart';

FlightEngine _buildEngine() {
  final FlightEngine engine = FlightEngine(options: const RouteOptions());
  engine.setLayout(width: 360, gameTop: 116, laneHeight: 111);
  return engine;
}

/// Advances the simulation to [seconds] at a fixed 60 Hz step.
void _run(FlightEngine engine, double seconds) {
  const double dt = 1 / 60;
  final int steps = (seconds / dt).round();
  for (int i = 0; i < steps && !engine.isOver; i++) {
    engine.update(dt);
  }
}

void main() {
  test('an untouched run is still flying when the game frame is captured', () {
    final FlightEngine engine = _buildEngine();
    _run(engine, 22);

    expect(engine.isOver, isFalse);
    expect(engine.state, GameState.flying);
    expect(engine.hits, lessThan(GameConfig.maxHits));
  });

  test('an untouched run reaches a result on the scripted third hit', () {
    final FlightEngine engine = _buildEngine();
    _run(engine, GameConfig.idleThirdHitSec + 2);

    expect(engine.isOver, isTrue);
    expect(engine.hits, GameConfig.maxHits);
    expect(engine.elapsed, greaterThan(GameConfig.idleSecondHitSec.toDouble()));
    expect(
      engine.elapsed,
      lessThan(GameConfig.hardAbortSec.toDouble()),
    );
  });

  test('an untouched run fills at least two stat cards', () {
    final FlightEngine engine = _buildEngine();
    _run(engine, GameConfig.idleThirdHitSec + 2);
    final FlightResult result = engine.buildResult();

    final int visibleCards = <bool>[
      result.accuracyPercent > 0,
      result.markers > 0,
      result.distanceKm > 0,
    ].where((bool shown) => shown).length;

    expect(visibleCards, greaterThanOrEqualTo(2));
    expect(result.score, greaterThan(0));
    expect(result.success, isFalse);
  });

  test('gate misses alone cannot end the round before the backstop', () {
    final FlightEngine engine = _buildEngine();
    _run(engine, GameConfig.idleFirstHitSec.toDouble());

    expect(engine.gatesMissed, lessThan(GameConfig.maxGateMisses));
  });

  test('lane changes stay inside the corridor grid', () {
    final FlightEngine engine = _buildEngine();
    _run(engine, 2);

    for (int i = 0; i < 10; i++) {
      engine.changeLane(-1);
      _run(engine, 0.3);
    }
    expect(engine.lane, 0);

    for (int i = 0; i < 10; i++) {
      engine.changeLane(1);
      _run(engine, 0.3);
    }
    expect(engine.lane, GameConfig.lanes - 1);
  });
}
