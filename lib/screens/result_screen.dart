import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../game/models.dart';
import '../theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/stat_card.dart';

/// Post-flight debrief. Verdict, hero sprite, three telemetry pills and the
/// replay CTA.
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.onPlayAgain,
    required this.onMenu,
  });

  final FlightResult result;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _statsFade;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _statsFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
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
    final FlightResult result = widget.result;
    final bool won = result.success;
    final Color verdictColor = won ? AppColors.gold : AppColors.danger;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    final List<Widget> cards = <Widget>[
      if (result.accuracyPercent > 0)
        StatCard(
          value: '${result.accuracyPercent}%',
          label: 'ROUTE ACCURACY',
          valueColor: AppColors.accentSky,
        ),
      if (result.markers > 0)
        StatCard(
          value: '${result.markers}/${GameConfig.targetMarkers}',
          label: 'NAV MARKERS',
          valueColor: AppColors.gold,
        ),
      if (result.distanceKm > 0)
        StatCard(
          value: '${result.distanceKm} KM',
          label: 'DISTANCE',
          valueColor: AppColors.accentIndigo,
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.bgResult),
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
                  AppColors.bgDeep.withValues(alpha: 0.55),
                  AppColors.bgBase.withValues(alpha: 0.92),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 44, 20, 20 + bottomInset),
                  child: Column(
                    children: <Widget>[
                      Text(
                        won ? 'ROUTE COMPLETE' : 'FLIGHT ABORTED',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          height: 1.15,
                          color: verdictColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        won
                            ? 'LANDING ZONE REACHED'
                            : 'THREE HITS · ROUTE LOST',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          height: 1.3,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color:
                                      verdictColor.withValues(alpha: 0.35),
                                  blurRadius: 40,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                verdictColor.withValues(
                                  alpha: won ? 0.0 : 0.28,
                                ),
                                BlendMode.srcATop,
                              ),
                              child: Image.asset(
                                AppAssets.spritePlane,
                                height: 110,
                                fit: BoxFit.contain,
                                errorBuilder: _resultFallback,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (cards.length >= 2)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              for (int i = 0; i < cards.length; i++)
                                ...<Widget>[
                                  if (i > 0) const SizedBox(width: 10),
                                  Expanded(
                                    child: ScaleTransition(
                                      scale: _statsFade,
                                      child: cards[i],
                                    ),
                                  ),
                                ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accentSky.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'ROUTE SCORE  ${result.score}',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            height: 1.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'FLY AGAIN',
                        icon: Icons.refresh,
                        onTap: widget.onPlayAgain,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SecondaryButton(
                          label: 'NEXT ROUTE',
                          onTap: widget.onMenu,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _resultFallback(BuildContext context, Object error, StackTrace? stack) {
  return const SizedBox.shrink();
}
