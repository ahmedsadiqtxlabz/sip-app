import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand Tokens
  static const Color aquaPrimary = Color(0xFF1FA2FF);
  static const Color tealSecondary = Color(0xFF12D8C8);
  static const Color coralAccent = Color(0xFFFF7A59);
  static const Color coralAccentPressed = Color(0xFFE8623F);
  static const Color coralAccentDisabled = Color(0xFFF3D9D1);

  // Brand Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [aquaPrimary, tealSecondary],
  );

  static const LinearGradient brandGradientPressed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1786D6), Color(0xFF0FB5A8)],
  );

  static const LinearGradient brandGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [aquaPrimary, tealSecondary],
  );

  // Light Mode Tokens
  static const Color lightBackground = Color(0xFFF7FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFEEF3F7);
  static const Color lightInk = Color(0xFF0E1116);
  static const Color lightInkSecondary = Color(0xFF4F5B69);
  static const Color lightInkMuted = Color(0xFF6B7684);
  static const Color lightTint = Color(0xFFE6F4FF);
  static const Color lightLink = Color(0xFF0A6FB8);
  static const Color lightOnGradient = Color(0xFF06283A);
  static const Color lightBorder = Color(0xFFE6EDF3);
  static const Color lightCoralTint = Color(0xFFFFF1EC);
  static const Color lightCoralText = Color(0xFFC2451F);

  // Dark Mode Tokens
  static const Color darkBackground = Color(0xFF0E1116);
  static const Color darkSurface = Color(0xFF161C24);
  static const Color darkSurface2 = Color(0xFF1F2731);
  static const Color darkBorder = Color(0xFF27313C);
  static const Color darkInk = Color(0xFFF3F6F9);
  static const Color darkInkSecondary = Color(0xFF9AA4B2);
  static const Color darkInkMuted = Color(0xFF6B7684);
  static const Color darkTint = Color(0xFF11324A);
  static const Color darkLink = Color(0xFF7CC8FF);

  // Card Shadows
  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: Color(0x0A0E1116), // 4%
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0D0E1116), // 5%
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> lightButtonShadow = [
    BoxShadow(
      color: Color(0x401FA2FF), // 25%
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> accentButtonShadow = [
    BoxShadow(
      color: Color(0x4DFF7A59), // 30%
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}

