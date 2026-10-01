import 'game_config.dart';

/// Lifecycle of a single flight.
enum GameState { idle, flying, hit, landing, over }

/// Route configuration picked on the menu sheet.
class RouteOptions {
  const RouteOptions({this.altitude = 1, this.speed = 0, this.weather = 1});

  /// 0 = LOW, 1 = MID, 2 = HIGH
  final int altitude;

  /// 0 = CRUISE, 1 = SPORT, 2 = AFTERBURNER
  final int speed;

  /// 0 = CLEAR, 1 = CLOUDY, 2 = STORM
  final int weather;

  static const List<String> altitudeLabels = <String>['LOW', 'MID', 'HIGH'];
  static const List<String> speedLabels = <String>[
    'CRUISE',
    'SPORT',
    'AFTERBURNER',
  ];
  static const List<String> weatherLabels = <String>[
    'CLEAR',
    'CLOUDY',
    'STORM',
  ];

  double get speedMultiplier =>
      const <double>[1.0, 1.18, 1.36][speed.clamp(0, 2)];

  double get scoreMultiplier =>
      const <double>[1.0, 1.15, 1.3][altitude.clamp(0, 2)];

  double get cloudDensity =>
      const <double>[1.3, 1.0, 0.7][altitude.clamp(0, 2)];

  /// Storm cells per [GameConfig.gateIntervalPx] of travelled distance.
  double get stormDensity =>
      const <double>[0.45, 0.7, 1.0][weather.clamp(0, 2)];

  double get scrollPxPerSec => GameConfig.baseScrollPxPerSec * speedMultiplier;

  RouteOptions copyWith({int? altitude, int? speed, int? weather}) {
    return RouteOptions(
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      weather: weather ?? this.weather,
    );
  }
}

/// Immutable summary handed to the result screen.
class FlightResult {
  const FlightResult({
    required this.success,
    required this.markers,
    required this.gatesPassed,
    required this.gatesMissed,
    required this.distanceKm,
    required this.score,
  });

  final bool success;
  final int markers;
  final int gatesPassed;
  final int gatesMissed;
  final int distanceKm;
  final int score;

  int get accuracyPercent {
    final int seen = gatesPassed + gatesMissed;
    if (seen == 0) {
      return 0;
    }
    return ((gatesPassed * 100) / seen).round();
  }
}

/// A colour gate. Only the gate whose [colorIndex] matches the HUD target
/// counts towards accuracy.
class GateEntity {
  GateEntity({required this.x, required this.lane, required this.colorIndex});

  double x;
  final int lane;
  final int colorIndex;
  bool resolved = false;
}

class MarkerEntity {
  MarkerEntity({required this.x, required this.lane});

  double x;
  final int lane;
  bool collected = false;
}

class StormEntity {
  StormEntity({required this.x, required this.lane, this.scripted = false});

  double x;
  final int lane;
  final bool scripted;
  bool consumed = false;
}

class CloudEntity {
  CloudEntity({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });

  double x;
  final double y;
  final double size;
  final double opacity;
}

/// Short-lived screen effect: gate ring burst or marker spark.
class EffectEntity {
  EffectEntity({
    required this.x,
    required this.y,
    required this.life,
    required this.isMarker,
  });

  double x;
  double y;
  double life;
  final bool isMarker;
}
