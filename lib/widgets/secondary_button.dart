import 'package:flutter/material.dart';

import '../theme.dart';

/// Outline button used for the quieter action on a screen.
class SecondaryButton extends StatefulWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (bool value) => setState(() => _pressed = value),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accentSky.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                height: 24 / 14,
                color: AppColors.accentSky,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
