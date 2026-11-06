import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated liquid droplet widget matching the SVG wave animation in design spec:
/// - 4s linear forward wave (front wave, #FFFFFF 95% opacity, Y=74)
/// - 6.5s linear reverse wave (back wave, #E6FBFF 55% opacity, Y=82)
/// - Droplet contour with rounded bottom and top apex
class SplashDropletWidget extends StatefulWidget {
  final double size;

  const SplashDropletWidget({
    super.key,
    this.size = 132.0,
  });

  @override
  State<SplashDropletWidget> createState() => _SplashDropletWidgetState();
}

class _SplashDropletWidgetState extends State<SplashDropletWidget>
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
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController1, _waveController2]),
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _DropletPainter(
            wave1Progress: _waveController1.value,
            wave2Progress: _waveController2.value,
          ),
        );
      },
    );
  }
}

class _DropletPainter extends CustomPainter {
  final double wave1Progress;
  final double wave2Progress;

  _DropletPainter({
    required this.wave1Progress,
    required this.wave2Progress,
  });

  Path _createDropletPath(Size size) {
    final double scale = size.width / 132.0;
    final path = Path();
    path.moveTo(66 * scale, 10 * scale);
    path.cubicTo(
      66 * scale,
      10 * scale,
      22 * scale,
      58 * scale,
      22 * scale,
      84 * scale,
    );
    // Arc from (22, 84) to (110, 84) with radius 44 (center at 66, 84)
    path.arcTo(
      Rect.fromCircle(
        center: Offset(66 * scale, 84 * scale),
        radius: 44 * scale,
      ),
      math.pi,
      -math.pi,
      false,
    );
    path.cubicTo(
      110 * scale,
      58 * scale,
      66 * scale,
      10 * scale,
      66 * scale,
      10 * scale,
    );
    path.close();
    return path;
  }

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
    final double scale = size.width / 132.0;
    final dropletPath = _createDropletPath(size);

    // 1. Droplet Background Fill (rgba(255, 255, 255, 0.22))
    final bgPaint = Paint()
      ..color = const Color(0x38FFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dropletPath, bgPaint);

    // 2. Clipped Water Waves inside droplet
    canvas.save();
    canvas.clipPath(dropletPath);

    // Wave 2 (Back wave): translates in reverse over 6.5s, base Y = 82, amplitude = 8
    final wave2Shift = (1.0 - wave2Progress) * 120.0 * scale;
    final wave2Path = _buildWavePath(
      width: size.width,
      height: size.height,
      baseLevel: 82.0 * scale,
      amplitude: 8.0 * scale,
      shiftX: wave2Shift,
      wavelength: 120.0 * scale,
    );
    final wave2Paint = Paint()
      ..color = const Color(0x8CE6FBFF) // #E6FBFF at 0.55 opacity
      ..style = PaintingStyle.fill;
    canvas.drawPath(wave2Path, wave2Paint);

    // Wave 1 (Front wave): translates forward over 4s, base Y = 74, amplitude = 10
    final wave1Shift = wave1Progress * 120.0 * scale;
    final wave1Path = _buildWavePath(
      width: size.width,
      height: size.height,
      baseLevel: 74.0 * scale,
      amplitude: 10.0 * scale,
      shiftX: wave1Shift,
      wavelength: 120.0 * scale,
    );
    final wave1Paint = Paint()
      ..color = const Color(0xF2FFFFFF) // #FFFFFF at 0.95 opacity
      ..style = PaintingStyle.fill;
    canvas.drawPath(wave1Path, wave1Paint);

    canvas.restore();

    // 3. Droplet Outline Stroke: 5px solid white, round join
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0 * scale
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dropletPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _DropletPainter oldDelegate) {
    return oldDelegate.wave1Progress != wave1Progress ||
        oldDelegate.wave2Progress != wave2Progress;
  }
}
