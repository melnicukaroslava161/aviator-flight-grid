import 'package:flutter/material.dart';

import '../theme.dart';

/// Full-width gradient CTA. Icon is locked to 24px and the label's line height
/// is matched to it so the row never drifts off the optical baseline.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (bool value) => setState(() => _pressed = value),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: <Color>[AppColors.accentSky, AppColors.accentIndigo],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.accentSky.withValues(alpha: 0.45),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(widget.icon, size: 24, color: AppColors.onAccent),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    height: 24 / 17,
                    color: AppColors.onAccent,
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
