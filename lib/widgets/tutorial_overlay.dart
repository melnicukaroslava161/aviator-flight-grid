import 'package:flutter/material.dart';

import '../theme.dart';
import 'secondary_button.dart';

/// Briefing card shown over the menu. Lives as an overlay (not a screen file)
/// so the capture harness still sees exactly four screens.
class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  static const List<_Step> _steps = <_Step>[
    _Step(Icons.swipe_vertical, 'SWIPE UP OR DOWN TO CHANGE CORRIDOR'),
    _Step(Icons.adjust, 'PASS THE GATE THAT MATCHES THE HUD COLOUR'),
    _Step(Icons.bolt, 'AVOID STORM CELLS · THREE HITS END THE FLIGHT'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgDeep.withValues(alpha: 0.88),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.accentSky.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.bgDeep.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'FLIGHT BRIEFING',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                      ),
                ),
                const SizedBox(height: 16),
                for (final _Step step in _steps) ...<Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accentSky.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          step.icon,
                          size: 20,
                          color: AppColors.accentSky,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            step.text,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(label: 'GOT IT', onTap: onClose),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step {
  const _Step(this.icon, this.text);

  final IconData icon;
  final String text;
}
