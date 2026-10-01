import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/models.dart';
import '../theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/route_segment.dart';
import '../widgets/tutorial_overlay.dart';

/// Bottom-sheet archetype: full-bleed sky art up top, frosted route panel below.
class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.options,
    required this.bestScore,
    required this.onOptionsChanged,
    required this.onStart,
  });

  final RouteOptions options;
  final int bestScore;
  final ValueChanged<RouteOptions> onOptionsChanged;
  final VoidCallback onStart;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _artFade;
  late final Animation<double> _artScale;
  late final Animation<double> _sheetFade;
  late final Animation<Offset> _sheetSlide;

  bool _tutorialOpen = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _artFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _artScale = Tween<double>(begin: 0.94, end: 1.0).animate(_artFade);
    _sheetFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _enter.forward();
      }
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.bgMenu),
                fit: BoxFit.cover,
              ),
            ),
            child: SizedBox.expand(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AppColors.bgBase.withValues(alpha: 0.30),
                  AppColors.bgBase.withValues(alpha: 0.72),
                  AppColors.bgDeep.withValues(alpha: 0.90),
                ],
                stops: const <double>[0.0, 0.45, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Column(
            children: <Widget>[
              Expanded(child: _buildArt(context)),
              FadeTransition(
                opacity: _sheetFade,
                child: SlideTransition(
                  position: _sheetSlide,
                  child: _buildSheet(context, bottomInset),
                ),
              ),
            ],
          ),
          if (_tutorialOpen)
            TutorialOverlay(
              onClose: () => setState(() => _tutorialOpen = false),
            ),
        ],
      ),
    );
  }

  Widget _buildArt(BuildContext context) {
    return FadeTransition(
      opacity: _artFade,
      child: ScaleTransition(
        scale: _artScale,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 44, 16, 8),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.military_tech,
                          size: 18,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'BEST  ${widget.bestScore}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            height: 1.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Material(
                      color: AppColors.textPrimary.withValues(alpha: 0.10),
                      shape: CircleBorder(
                        side: BorderSide(
                          color: AppColors.accentSky.withValues(alpha: 0.45),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() => _tutorialOpen = true),
                        child: const Icon(
                          Icons.help_outline,
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double planeHeight = constraints.maxHeight.isFinite
                        ? math.min(
                            150.0,
                            math.max(64.0, constraints.maxHeight - 12),
                          )
                        : 150.0;
                    return Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: double.infinity,
                            height: 2,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      AppColors.accentSky
                                          .withValues(alpha: 0.0),
                                      AppColors.accentSky
                                          .withValues(alpha: 0.65),
                                      AppColors.accentSky
                                          .withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.accentSky
                                      .withValues(alpha: 0.35),
                                  blurRadius: 38,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              AppAssets.spritePlane,
                              height: planeHeight,
                              fit: BoxFit.contain,
                              errorBuilder: _artFallback,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheet(BuildContext context, double bottomInset) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          border: Border(
            top: BorderSide(
              color: AppColors.accentSky.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.bgDeep.withValues(alpha: 0.7),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.accentSky.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    AppAssets.icon,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: _artFallback,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AVIATOR FLIGHT GRID',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'SWIPE LANES · HIT COLOUR GATES · LAND CLEAN',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                height: 1.3,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            RouteSegment(
              label: 'ALTITUDE',
              options: RouteOptions.altitudeLabels,
              selectedIndex: widget.options.altitude,
              onSelect: (int i) =>
                  widget.onOptionsChanged(widget.options.copyWith(altitude: i)),
            ),
            const SizedBox(height: 12),
            RouteSegment(
              label: 'SPEED',
              options: RouteOptions.speedLabels,
              selectedIndex: widget.options.speed,
              onSelect: (int i) =>
                  widget.onOptionsChanged(widget.options.copyWith(speed: i)),
            ),
            const SizedBox(height: 12),
            RouteSegment(
              label: 'WEATHER',
              options: RouteOptions.weatherLabels,
              selectedIndex: widget.options.weather,
              onSelect: (int i) =>
                  widget.onOptionsChanged(widget.options.copyWith(weather: i)),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'START FLIGHT',
              icon: Icons.flight_takeoff,
              onTap: widget.onStart,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _artFallback(BuildContext context, Object error, StackTrace? stack) {
  return const SizedBox.shrink();
}
