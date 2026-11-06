import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated liquid water ring widget matching the design spec:
/// - Outer circular progress track (14px) with rounded caps and gradient
/// - Inner circular reservoir with 2 layered animated liquid waves:
///   - Wave 1 (front): 4s linear forward wave with brand gradient (90% opacity)
///   - Wave 2 (back): 6.5s linear reverse wave (#12D8C8 with 45% opacity)
/// - Center typography for percentage and volume
class LiquidWaterRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final String? percentText;
  final String? subText;
  final LinearGradient? customGradient;

  const LiquidWaterRing({
    super.key,
    this.progress = 0.65,
    this.size = 260.0,
    this.percentText,
    this.subText,
    this.customGradient,
  });

  @override
  State<LiquidWaterRing> createState() => _LiquidWaterRingState();
}

class _LiquidWaterRingState extends State<LiquidWaterRing>
    with TickerProviderStateMixin {
  late final AnimationController _waveController1;
  late final AnimationController _waveController2;

  @override
  void initState() {
    super.initState();
    _waveController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _waveController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController1.dispose();
    _waveController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? const Color(0xFF222F3D) : const Color(0xFFE1ECF4);
    final reservoirBgColor =
        isDark ? const Color(0xFF14202B) : const Color(0xFFEAF6FF);
    final gradient = widget.customGradient ??
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
        );

    final double displayPercent = (widget.progress * 100).clamp(0, 100);
    final String mainLabel =
        widget.percentText ?? '${displayPercent.round()}%';
    final String subLabel = widget.subText ?? '1,625 of 2,500 ml';

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Live Animated CustomPainter for Ring & Liquid Waves
          AnimatedBuilder(
            animation: Listenable.merge([_waveController1, _waveController2]),
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _LiquidRingPainter(
                  progress: widget.progress.clamp(0.0, 1.0),
                  wave1Progress: _waveController1.value,
                  wave2Progress: _waveController2.value,
                  trackColor: trackColor,
                  reservoirBgColor: reservoirBgColor,
                  gradient: gradient,
                ),
              );
            },
          ),

          // 2. Center Text Overlay
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mainLabel,
                style: TextStyle(
                  fontFamily: '-apple-system',
                  fontSize: widget.size * (52.0 / 240.0), // ~56 at 260
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2.0,
                  height: 1.0,
                  color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
                ),
              ),
              SizedBox(height: widget.size * (6.0 / 240.0)),
              Text(
                subLabel,
                style: TextStyle(
                  fontFamily: '-apple-system',
                  fontSize: widget.size * (15.0 / 240.0), // ~16 at 260
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkInkSecondary
                      : const Color(0xFF0E1116),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiquidRingPainter extends CustomPainter {
  final double progress;
  final double wave1Progress;
  final double wave2Progress;
  final Color trackColor;
  final Color reservoirBgColor;
  final LinearGradient gradient;

  _LiquidRingPainter({
    required this.progress,
    required this.wave1Progress,
    required this.wave2Progress,
    required this.trackColor,
    required this.reservoirBgColor,
    required this.gradient,
  });

  Path _buildWavePath({
    required double width,
    required double height,
    required double baseLevel,
    required double amplitude,
    required double shiftX,
    double wavelength = 120.0,
  }) {
    final path = Path();
    final double normalizedShift = shiftX % wavelength;
    double startX = -wavelength - normalizedShift;

    path.moveTo(startX, baseLevel);

    while (startX < width + wavelength * 2) {
      path.quadraticBezierTo(
        startX + wavelength * 0.25,
        baseLevel - amplitude,
        startX + wavelength * 0.5,
        baseLevel,
      );
      path.quadraticBezierTo(
        startX + wavelength * 0.75,
        baseLevel + amplitude,
        startX + wavelength,
        baseLevel,
      );
      startX += wavelength;
    }

    path.lineTo(startX, height + 100);
    path.lineTo(-wavelength * 2, height + 100);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 240.0;
    final center = Offset(size.width / 2, size.height / 2);

    final double outerRadius = 108.0 * scale;
    final double strokeWidth = 14.0 * scale;
    final double innerRadius = 96.0 * scale;

    // 1. Draw Outer Track Circle (stroke 14)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, outerRadius, trackPaint);

    // 2. Draw Outer Progress Arc with gradient
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: outerRadius);
      final arcPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2; // 12 o'clock
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }

    // 3. Draw Reservoir Background (Inner Circle radius 96)
    final innerBgPaint = Paint()
      ..color = reservoirBgColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerBgPaint);

    // 4. Clip to Inner Circle and draw Animated Liquid Waves
    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: innerRadius));

    canvas.save();
    canvas.clipPath(innerPath);

    // Liquid fill level calculation:
    // In design spec (Screenshot 1), at 65% progress, the water baseline sits at Y ≈ 115 * scale
    // (in 240 design space, center is 120), so the wave cuts across the lower half of "65%"
    // while "1,625 of 2,500 ml" is submerged and the top of "65%" is clear above the water.
    final double emptyY = center.dy + innerRadius; // 216 * scale
    final double fullY = center.dy - innerRadius;  // 24 * scale
    final double baseWaterY;
    if (progress <= 0.0) {
      baseWaterY = emptyY;
    } else if (progress >= 1.0) {
      baseWaterY = fullY;
    } else if (progress <= 0.5) {
      baseWaterY = emptyY - (progress / 0.5) * (emptyY - center.dy);
    } else {
      // Calibrated circular progression: 0.5 -> center (120), 0.65 -> 115, 1.0 -> 24
      final t = (progress - 0.5) / 0.5;
      baseWaterY = center.dy - math.pow(t, 2.5) * (center.dy - fullY) - (t * 5.0 * scale);
    }

    // Wave 2 (Back Wave): translates in reverse over 6.5s, base Y = baseWaterY + 8, amplitude = 5
    final wave2Shift = (1.0 - wave2Progress) * 120.0 * scale;
    final wave2Path = _buildWavePath(
      width: size.width,
      height: size.height,
      baseLevel: baseWaterY + (8.0 * scale),
      amplitude: 5.0 * scale,
      shiftX: wave2Shift,
      wavelength: 120.0 * scale,
    );
    final wave2Paint = Paint()
      ..color = const Color(0x7312D8C8) // #12D8C8 at 0.45 opacity
      ..style = PaintingStyle.fill;
    canvas.drawPath(wave2Path, wave2Paint);

    // Wave 1 (Front Wave): translates forward over 4s, base Y = baseWaterY, amplitude = 6.5
    final wave1Shift = wave1Progress * 120.0 * scale;
    final wave1Path = _buildWavePath(
      width: size.width,
      height: size.height,
      baseLevel: baseWaterY,
      amplitude: 6.5 * scale,
      shiftX: wave1Shift,
      wavelength: 120.0 * scale,
    );

    final rect = Rect.fromCircle(center: center, radius: innerRadius);
    final wave1Gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1FA2FF).withValues(alpha: 0.90),
        const Color(0xFF12D8C8).withValues(alpha: 0.90),
      ],
    );
    final wave1Paint = Paint()
      ..shader = wave1Gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(wave1Path, wave1Paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wave1Progress != wave1Progress ||
        oldDelegate.wave2Progress != wave2Progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.reservoirBgColor != reservoirBgColor ||
        oldDelegate.gradient != gradient;
  }
}
