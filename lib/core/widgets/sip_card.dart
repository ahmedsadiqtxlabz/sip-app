import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SipCardType { surface, upsell, empty }

class SipCard extends StatelessWidget {
  final Widget child;
  final SipCardType type;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  const SipCard({
    super.key,
    required this.child,
    this.type = SipCardType.surface,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    BoxDecoration decoration;

    switch (type) {
      case SipCardType.surface:
        decoration = BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(radius),
          border: isDark ? Border.all(color: AppColors.darkBorder, width: 1) : null,
          boxShadow: isDark ? null : AppColors.lightCardShadow,
        );
        break;

      case SipCardType.upsell:
        decoration = BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF142E42), Color(0xFF113B38)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE6F4FF), Color(0xFFE3FBF8)],
                ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark ? const Color(0xFF1E4B66) : const Color(0xFFCFE9FA),
            width: 1,
          ),
        );
        break;

      case SipCardType.empty:
        decoration = BoxDecoration(
          color: isDark ? const Color(0xFF11171E) : const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark ? const Color(0xFF27313C) : const Color(0xFFCBD8E2),
            width: 1.5,
          ),
        );
        break;
    }

    Widget content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

