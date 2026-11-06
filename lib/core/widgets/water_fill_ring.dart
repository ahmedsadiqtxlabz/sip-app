import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class WaterFillRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0 (or greater)
  final int currentAmount;
  final int goalAmount;
  final String unit;
  final double size;
  final LinearGradient? customGradient;
  final bool isGoalReached;

  const WaterFillRing({
    super.key,
    required this.progress,
    required this.currentAmount,
    required this.goalAmount,
    this.unit = 'ml',
    this.size = 220,
    this.customGradient,
    this.isGoalReached = false,
  });

  @override
  State<WaterFillRing> createState() => _WaterFillRingState();
}

class _WaterFillRingState extends State<WaterFillRing>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // 52 seconds is the LCM of 4.0s (13 cycles) and 6.5s (8 cycles), guaranteeing seamless loop
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 52),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _progressController.forward();
    _lastProgress = widget.progress;
  }

  @override
  void didUpdateWidget(covariant WaterFillRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _lastProgress.clamp(0.0, 1.0),
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
      );
      _progressController.forward(from: 0.0);
      _lastProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _formatNumber(int val) {
    return NumberFormat('#,###').format(val);
  }

  String _getStatusPhrase(int percent) {
    if (percent <= 0) return '';
    if (percent < 25) return 'great start';
    if (percent < 45) return 'on track';
    if (percent <= 55) return 'halfway there';
    if (percent < 75) return 'nice one';
    if (percent < 100) return 'almost there';
    return 'goal reached';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? const Color(0xFF27313C) : const Color(0xFFE1ECF4);
    final innerCircleColor = isDark ? const Color(0xFF10202C) : const Color(0xFFEAF6FF);
    final gradient = widget.customGradient ?? AppColors.brandGradient;

    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _progressController]),
      builder: (context, child) {
        final progressVal = _progressAnimation.value;
        final reached = widget.isGoalReached || progressVal >= 1.0;
        final percent = (progressVal * 100).round();
        final scale = widget.size / 240.0;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Liquid Waves & Ring Painter
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _WaterRingPainter(
                  progress: progressVal,
                  wavePhase: _waveController.value,
                  trackColor: trackColor,
                  innerCircleColor: innerCircleColor,
                  gradient: gradient,
                  isGoalReached: reached,
                  isDark: isDark,
                ),
              ),

              // Centered Text Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (reached) ...[
                      // Goal reached checkmark
                      CustomPaint(
                        size: Size(58 * scale, 42 * scale),
                        painter: _CheckmarkPainter(isDark: isDark),
                      ),
                      SizedBox(height: 10 * scale),
                      Text(
                        '${_formatNumber(widget.currentAmount)} / ${_formatNumber(widget.goalAmount)} ${widget.unit}',
                        style: TextStyle(
                          fontFamily: '-apple-system',
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF06283A),
                        ),
                      ),
                    ] else ...[
                      // Hero Amount Number (e.g. 1,250 or 0)
                      Text(
                        _formatNumber(widget.currentAmount),
                        style: TextStyle(
                          fontFamily: '-apple-system',
                          fontSize: (widget.currentAmount >= 10000 ? 44 : 52) * scale,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2.0 * scale,
                          height: 1.0,
                          color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      // Goal Subtitle (e.g. of 2,500 ml)
                      Text(
                        'of ${_formatNumber(widget.goalAmount)} ${widget.unit}',
                        style: TextStyle(
                          fontFamily: '-apple-system',
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                        ),
                      ),
                      // Percentage & Status Phrase (e.g. 50% · halfway there)
                      // Only displayed when at least 1 drink has been logged
                      if (widget.currentAmount > 0) ...[
                        SizedBox(height: 5 * scale),
                        Text(
                          '$percent% · ${_getStatusPhrase(percent)}',
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2 * scale,
                            color: const Color(0xFF06283A), // Exact spec contrast color on turquoise
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaterRingPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color trackColor;
  final Color innerCircleColor;
  final LinearGradient gradient;
  final bool isGoalReached;
  final bool isDark;

  const _WaterRingPainter({
    required this.progress,
    required this.wavePhase,
    required this.trackColor,
    required this.innerCircleColor,
    required this.gradient,
    required this.isGoalReached,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 240.0;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // 1. Outer Background Track (radius: 108, strokeWidth: 14)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, 108 * scale, trackPaint);

    // 2. Outer Progress Arc
    if (progress > 0) {
      final arcRect = Rect.fromCircle(center: center, radius: 108 * scale);
      final arcPaint = Paint()
        ..shader = gradient.createShader(arcRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14 * scale
        ..strokeCap = StrokeCap.round;

      const double startAngle = -math.pi / 2; // 12 o'clock
      final double sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);
    }

    // 3. Inner Background Circle (radius: 96)
    final innerBgPaint = Paint()
      ..color = innerCircleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 96 * scale, innerBgPaint);

    // 4. Dual Animated Liquid Waves (clipped to circle radius 96)
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 96 * scale));
    canvas.clipPath(clipPath);

    // Baseline calculation:
    // Empty state (0%): translate(0 208) per HTML spec
    // 50% state: translate(0 120) per HTML spec (208 - 0.5 * 176 = 120)
    // 100% state: translate(0 32)
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final double base1Y = (208.0 - (clampedProgress * 176.0)) * scale;
    final double base2Y = base1Y + 10.0 * scale; // Exactly 10px below per HTML spec

    // Wave 1: Primary gradient with 0.85-0.90 opacity
    final wave1Shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final wave1Paint = Paint()
      ..shader = wave1Shader
      ..color = Colors.white.withValues(alpha: isDark ? 0.85 : 0.90)
      ..style = PaintingStyle.fill;

    // 4.0s forward wave animation (13 full cycles in 52s duration)
    final double wave1Phase = (wavePhase * 13) * 2 * math.pi;
    final wave1Path = Path();
    final double amp1 = 6.0 * scale;
    final double waveLen1 = 120.0 * scale;

    wave1Path.moveTo(0, size.height);
    wave1Path.lineTo(0, base1Y);
    for (double x = 0; x <= size.width; x += 1.5) {
      final double y = base1Y + amp1 * math.sin((x / waveLen1) * 2 * math.pi - wave1Phase);
      wave1Path.lineTo(x, y);
    }
    wave1Path.lineTo(size.width, size.height);
    wave1Path.close();
    canvas.drawPath(wave1Path, wave1Paint);

    // Wave 2: Turquoise foreground with 0.40-0.45 opacity
    final wave2Paint = Paint()
      ..color = const Color(0xFF12D8C8).withValues(alpha: isDark ? 0.40 : 0.45)
      ..style = PaintingStyle.fill;

    // 6.5s reverse wave animation (8 full cycles in 52s duration)
    final double wave2Phase = -(wavePhase * 8) * 2 * math.pi;
    final wave2Path = Path();
    final double amp2 = 5.0 * scale;
    final double waveLen2 = 120.0 * scale;

    wave2Path.moveTo(0, size.height);
    wave2Path.lineTo(0, base2Y);
    for (double x = 0; x <= size.width; x += 1.5) {
      final double y = base2Y + amp2 * math.sin((x / waveLen2) * 2 * math.pi - wave2Phase);
      wave2Path.lineTo(x, y);
    }
    wave2Path.lineTo(size.width, size.height);
    wave2Path.close();
    canvas.drawPath(wave2Path, wave2Paint);

    canvas.restore();

    // 5. Goal reached outer halo ring
    if (isGoalReached) {
      final haloPaint = Paint()
        ..color = const Color(0xFF12D8C8).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale;
      canvas.drawCircle(center, (108 + 10) * scale, haloPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.innerCircleColor != innerCircleColor ||
        oldDelegate.gradient != gradient ||
        oldDelegate.isGoalReached != isGoalReached ||
        oldDelegate.isDark != isDark;
  }
}

class _CheckmarkPainter extends CustomPainter {
  final bool isDark;

  _CheckmarkPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 58.0;

    // Exact path: from (2, 22) -> (18, 38) -> (56, 2)
    final path = Path()
      ..moveTo(2 * scale, 22 * scale)
      ..lineTo(18 * scale, 38 * scale)
      ..lineTo(56 * scale, 2 * scale);

    // Outer glow / contrast stroke
    final bgPaint = Paint()
      ..color = isDark ? const Color(0x66000000) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Inner crisp stroke
    final fgPaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF06283A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, bgPaint);
    canvas.drawPath(path, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
