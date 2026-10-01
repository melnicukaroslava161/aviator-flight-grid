import 'package:flutter/material.dart';

import '../theme.dart';

/// A caps label plus three equal-width choice chips. Used three times on the
/// menu sheet to build the route (altitude / speed / weather).
class RouteSegment extends StatelessWidget {
  const RouteSegment({
    super.key,
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String label;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            height: 1.2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            for (int i = 0; i < options.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _chip(options[i], i == selectedIndex, i)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _chip(String text, bool active, int index) {
    return InkWell(
      onTap: () => onSelect(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentSky.withValues(alpha: 0.18)
              : AppColors.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.accentSky
                : AppColors.textPrimary.withValues(alpha: 0.10),
            width: active ? 1.5 : 1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.6,
              height: 1.2,
              color: active ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
