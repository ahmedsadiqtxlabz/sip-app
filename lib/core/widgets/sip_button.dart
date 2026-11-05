import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum SipButtonType { primary, accent, secondary, tertiary }

class SipButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final SipButtonType type;
  final Widget? icon;
  final double? width;
  final double height;
  final LinearGradient? customGradient;

  const SipButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = SipButtonType.primary,
    this.icon,
    this.width,
    this.height = 56,
    this.customGradient,
  });

  @override
  State<SipButton> createState() => _SipButtonState();
}

class _SipButtonState extends State<SipButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isEnabled = widget.onPressed != null;

    BoxDecoration decoration;
    TextStyle textStyle;

    switch (widget.type) {
      case SipButtonType.primary:
        if (!isEnabled) {
          decoration = BoxDecoration(
            color: isDark ? const Color(0xFF1E2833) : const Color(0xFFDCE4EC),
            borderRadius: BorderRadius.circular(18),
          );
          textStyle = AppTypography.headline(
            color: isDark ? const Color(0xFF556575) : const Color(0xFF8A94A3),
          );
        } else {
          final gradient = widget.customGradient ??
              (_isPressed
                  ? AppColors.brandGradientPressed
                  : AppColors.brandGradient);
          decoration = BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isPressed ? null : AppColors.lightButtonShadow,
          );
          textStyle = AppTypography.headline(color: AppColors.lightOnGradient);
        }
        break;

      case SipButtonType.accent:
        if (!isEnabled) {
          decoration = BoxDecoration(
            color: isDark ? const Color(0xFF2C2220) : AppColors.coralAccentDisabled,
            borderRadius: BorderRadius.circular(18),
          );
          textStyle = AppTypography.headline(
            color: isDark ? const Color(0xFF6B5854) : const Color(0xFFA68A80),
          );
        } else {
          decoration = BoxDecoration(
            color: _isPressed
                ? AppColors.coralAccentPressed
                : AppColors.coralAccent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isPressed ? null : AppColors.accentButtonShadow,
          );
          textStyle = AppTypography.headline(
            color: const Color(0xFF2B1208),
          ).copyWith(fontWeight: FontWeight.w800);
        }
        break;

      case SipButtonType.secondary:
        if (!isEnabled) {
          decoration = BoxDecoration(
            color: isDark ? const Color(0xFF1E2833) : AppColors.lightSurface2,
            borderRadius: BorderRadius.circular(16),
          );
          textStyle = AppTypography.body(
            color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
          );
        } else {
          decoration = BoxDecoration(
            color: isDark
                ? (_isPressed ? const Color(0xFF183D59) : AppColors.darkTint)
                : (_isPressed ? const Color(0xFFD3EBFC) : AppColors.lightTint),
            borderRadius: BorderRadius.circular(16),
          );
          textStyle = AppTypography.body(
            color: isDark ? AppColors.darkLink : AppColors.lightLink,
          );
        }
        break;

      case SipButtonType.tertiary:
        decoration = BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: AppColors.darkBorder) : null,
          boxShadow: isDark ? null : AppColors.lightCardShadow,
        );
        textStyle = AppTypography.body(
          color: isDark ? AppColors.darkInk : AppColors.lightInk,
        );
        break;
    }

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: decoration,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Text(widget.text, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

