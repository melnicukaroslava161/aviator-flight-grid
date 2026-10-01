import 'package:flutter/material.dart';

import '../game/game_config.dart';
import '../theme.dart';

/// Telemetry strip pinned to the top of the game screen: exit, the colour the
/// next gate must match, marker progress and remaining airframes.
class HudBar extends StatelessWidget {
  const HudBar({
    super.key,
    required this.targetColor,
    required this.markers,
    required this.hits,
    required this.onBack,
  });

  final Color targetColor;
  final int markers;
  final int hits;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GameConfig.headerHeight + 44,
      padding: const EdgeInsets.only(top: 44, left: 8, right: 12),
      decoration: BoxDecoration(
        color: AppColors.bgDeep.withValues(alpha: 0.55),
        border: Border(
          bottom: BorderSide(
            color: AppColors.accentSky.withValues(alpha: 0.28),
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: AppColors.textPrimary,
              ),
              tooltip: 'MENU',
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: targetColor,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: targetColor.withValues(alpha: 0.6),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'GATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    height: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$markers/${GameConfig.targetMarkers}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1.2,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < GameConfig.maxHits; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Icon(
                    Icons.flight,
                    size: 16,
                    color: i < GameConfig.maxHits - hits
                        ? AppColors.textPrimary
                        : AppColors.danger.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
