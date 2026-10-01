/// Tunables for the flight route. Everything the engine reads lives here so a
/// balance pass never has to touch widget code.
class GameConfig {
  const GameConfig._();

  /// Splash duration. Must stay exactly 8000 — the capture harness needs the
  /// loader to still be on screen after its cold-start overhead.
  static const int loaderDurationMs = 8000;

  static const int lanes = 5;
  static const int idleLane = 2;

  static const int targetMarkers = 25;
  static const int maxHits = 3;

  /// Missing this many target-coloured gates aborts the route. Sized so the
  /// no-input backstop below always decides the round first.
  static const int maxGateMisses = 14;

  static const double baseScrollPxPerSec = 190;
  static const double gateIntervalPx = 540;
  static const double markerIntervalSec = 2.2;

  static const int laneSwitchMs = 220;
  static const int invulnerableMs = 900;

  /// No-input backstop: a bot that never swipes sits in [idleLane] and takes
  /// three scripted storm hits at these marks, so a result frame always exists.
  static const int idleFirstHitSec = 14;
  static const int idleSecondHitSec = 24;
  static const int idleThirdHitSec = 34;

  /// Hard failsafe measured from the first painted game frame. Never re-armed.
  static const int hardAbortSec = 42;

  /// Seconds during which random storms avoid [idleLane] so the scripted
  /// schedule above stays the only thing that can end an untouched run.
  static const double idleLaneProtectSec = 36;

  /// How long the plane flies in before the player takes over.
  static const double introSec = 1.2;
  static const double hintSec = 2.5;

  /// Layout reservations used by the corridor geometry formula.
  static const double headerHeight = 72;
  static const double controlsReserve = 108;
  static const double gridFrame = 10;

  static const double planeXFraction = 0.26;
  static const double planeWidth = 92;
  static const double gateWidth = 82;
  static const double gateHeight = 110;
  static const double markerSize = 34;
  static const double stormSize = 76;
}
