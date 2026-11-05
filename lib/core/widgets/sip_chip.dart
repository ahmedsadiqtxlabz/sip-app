import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum SipChipState { defaultState, selected, locked, disabled }

class SipChip extends StatelessWidget {
  final String label;
  final Widget? icon;
  final SipChipState state;
  final VoidCallback? onTap;
  final bool showProBadge;

  const SipChip({
    super.key,
    required this.label,
    this.icon,
    this.state = SipChipState.defaultState,
    this.onTap,
    this.showProBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    BoxDecoration decoration;
    TextStyle textStyle;

    switch (state) {
      case SipChipState.selected:
        decoration = BoxDecoration(
          color: isDark ? AppColors.darkTint : AppColors.lightTint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.aquaPrimary, width: 1.5),
        );
        textStyle = AppTypography.body(
          color: isDark ? AppColors.darkLink : AppColors.lightLink,
        );
        break;

      case SipChipState.disabled:
        decoration = BoxDecoration(
          color: isDark ? const Color(0xFF161E26) : AppColors.lightSurface2,
          borderRadius: BorderRadius.circular(14),
        );
        textStyle = AppTypography.body(
          color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
        );
        break;

      case SipChipState.locked:
      case SipChipState.defaultState:
        decoration = BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: isDark ? null : AppColors.lightCardShadow,
        );
        textStyle = AppTypography.body(
          color: isDark ? AppColors.darkInk : AppColors.lightInk,
        );
        break;
    }

    return GestureDetector(
      onTap: state == SipChipState.disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: decoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 6),
            ],
            Text(label, style: textStyle),
            if (showProBadge || state == SipChipState.locked) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF26323F) : AppColors.lightSurface2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PRO',
                  style: AppTypography.badge(
                    color: isDark ? AppColors.darkLink : AppColors.lightInkSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

