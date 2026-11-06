import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/splash_droplet_widget.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_bloc.dart';
import 'onboarding_page.dart';
import '../../../../main_navigation_shell.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      _navigateNext();
    });
  }

  void _navigateNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final state = context.read<WaterTrackingBloc>().state;
    if (state.settings.hasCompletedOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _navigateNext,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1FA2FF),
                Color(0xFF12D8C8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Top-left translucent background circle
              Positioned(
                left: -80,
                top: -120,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x1AFFFFFF), // rgba(255,255,255,0.10)
                  ),
                ),
              ),

              // Bottom-right translucent background circle
              Positioned(
                right: -120,
                bottom: 60,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x14FFFFFF), // rgba(255,255,255,0.08)
                  ),
                ),
              ),

              // Center content: Droplet + Sip + Subtitle
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Droplet with live liquid waves from design spec
                    const SplashDropletWidget(size: 132),
                    const SizedBox(height: 28),
                    Text(
                      'Sip',
                      style: AppTypography.title1(color: Colors.white).copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.32,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Drink well, every day',
                      style: AppTypography.headline(
                        color: const Color(0xEBFFFFFF), // 0.92 opacity
                      ).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom: Tap to continue
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: Text(
                      'Tap to continue',
                      style: AppTypography.caption(
                        color: const Color(0xBFFFFFFF), // 0.75 opacity
                      ).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
