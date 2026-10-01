import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'game/models.dart';
import 'screens/game_screen.dart';
import 'screens/loader_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/result_screen.dart';
import 'theme.dart';

/// Screen state machine. `result` is mandatory — it is the only frame that
/// proves a round actually ended.
enum Screen { loader, menu, game, result }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Flutter only publishes an accessibility tree while a client holds a
  // handle; the CI emulator binds no service, so force it on.
  SemanticsBinding.instance.ensureSemantics();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const AviatorFlightGridApp());
}

class AviatorFlightGridApp extends StatelessWidget {
  const AviatorFlightGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aviator Flight Grid',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Screen _screen = Screen.loader;
  RouteOptions _options = const RouteOptions();
  FlightResult? _lastResult;
  int _bestScore = 0;

  void _goMenu() => setState(() => _screen = Screen.menu);

  void _startFlight() => setState(() => _screen = Screen.game);

  void _onGameOver(FlightResult result) {
    setState(() {
      _lastResult = result;
      if (result.score > _bestScore) {
        _bestScore = result.score;
      }
      _screen = Screen.result;
    });
  }

  /// System back never leaves the app from a gameplay screen — a launcher frame
  /// in the capture set reads as a crash.
  void _handleBack() {
    switch (_screen) {
      case Screen.game:
      case Screen.result:
        _goMenu();
      case Screen.loader:
      case Screen.menu:
        break;
    }
  }

  Widget _buildScreen() {
    switch (_screen) {
      case Screen.loader:
        return LoaderScreen(key: const ValueKey<String>('loader'), onDone: _goMenu);
      case Screen.menu:
        return MenuScreen(
          key: const ValueKey<String>('menu'),
          options: _options,
          bestScore: _bestScore,
          onOptionsChanged: (RouteOptions next) =>
              setState(() => _options = next),
          onStart: _startFlight,
        );
      case Screen.game:
        return GameScreen(
          key: const ValueKey<String>('game'),
          options: _options,
          onGameOver: _onGameOver,
          onExit: _goMenu,
        );
      case Screen.result:
        return ResultScreen(
          key: const ValueKey<String>('result'),
          result: _lastResult ??
              const FlightResult(
                success: false,
                markers: 0,
                gatesPassed: 0,
                gatesMissed: 0,
                distanceKm: 0,
                score: 0,
              ),
          onPlayAgain: _startFlight,
          onMenu: _goMenu,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _buildScreen(),
      ),
    );
  }
}
