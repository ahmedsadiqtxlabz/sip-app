import 'package:flutter/material.dart';

class SipProTheme {
  final String name;
  final Color primary;
  final Color secondary;
  final LinearGradient gradient;

  const SipProTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.gradient,
  });
}

abstract class ProThemes {
  static const SipProTheme aqua = SipProTheme(
    name: 'Aqua',
    primary: Color(0xFF1FA2FF),
    secondary: Color(0xFF12D8C8),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
    ),
  );

  static const SipProTheme lavender = SipProTheme(
    name: 'Lavender',
    primary: Color(0xFF6C5CE7),
    secondary: Color(0xFFA29BFE),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    ),
  );

  static const SipProTheme coral = SipProTheme(
    name: 'Coral',
    primary: Color(0xFFFF7A59),
    secondary: Color(0xFFFFB199),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF7A59), Color(0xFFFFB199)],
    ),
  );

  static const SipProTheme mint = SipProTheme(
    name: 'Mint',
    primary: Color(0xFF0FA38F),
    secondary: Color(0xFF7BE3C5),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0FA38F), Color(0xFF7BE3C5)],
    ),
  );

  static const SipProTheme honey = SipProTheme(
    name: 'Honey',
    primary: Color(0xFFF4B400),
    secondary: Color(0xFFFFD866),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF4B400), Color(0xFFFFD866)],
    ),
  );

  static const SipProTheme graphite = SipProTheme(
    name: 'Graphite',
    primary: Color(0xFF2B3A4A),
    secondary: Color(0xFF5B6C7E),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2B3A4A), Color(0xFF5B6C7E)],
    ),
  );

  static const List<SipProTheme> allThemes = [
    aqua,
    lavender,
    coral,
    mint,
    honey,
    graphite,
  ];

  static SipProTheme fromName(String name) {
    return allThemes.firstWhere(
      (t) => t.name.toLowerCase() == name.toLowerCase(),
      orElse: () => aqua,
    );
  }
}

