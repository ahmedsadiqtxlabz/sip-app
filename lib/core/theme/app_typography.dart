import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTypography {
  // Hero number (Inside Ring) - 60pt w800
  static TextStyle heroNumber({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 54,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
      height: 1.0,
      color: color,
    );
  }

  // Title 1 - 30pt w800
  static TextStyle title1({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.15,
      color: color,
    );
  }

  // Title 2 - 22pt w800
  static TextStyle title2({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      height: 1.2,
      color: color,
    );
  }

  // Headline - 17pt w700
  static TextStyle headline({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.3,
      color: color,
    );
  }

  // Body - 15pt w600 (rows, chips, cup buttons)
  static TextStyle body({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: color,
    );
  }

  // Body Secondary - 15pt w400
  static TextStyle bodySecondary({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: color,
    );
  }

  // Caption - 13pt w600
  static TextStyle caption({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: color,
    );
  }

  // Section Label - 12pt w700 uppercase +6% tracking
  static TextStyle sectionLabel({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.72, // +6%
      color: color,
    );
  }

  // Badge (PRO) - 10pt w800
  static TextStyle badge({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: color,
    );
  }
}

