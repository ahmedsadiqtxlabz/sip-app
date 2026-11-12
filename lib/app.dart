import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/pages/splash_page.dart';
import 'features/water_tracking/presentation/bloc/water_tracking_bloc.dart';
import 'features/water_tracking/presentation/bloc/water_tracking_event.dart';

class SipApp extends StatelessWidget {
  const SipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WaterTrackingBloc>()..add(const LoadWaterTracking()),
      child: MaterialApp(
        title: 'Sip: Water Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              final currentFocus = FocusManager.instance.primaryFocus;
              if (currentFocus != null && currentFocus.hasFocus) {
                final renderObject = currentFocus.context?.findRenderObject();
                if (renderObject is RenderBox) {
                  final position = renderObject.localToGlobal(Offset.zero);
                  final size = renderObject.size;
                  final rect = position & size;
                  if (!rect.contains(event.position)) {
                    currentFocus.unfocus();
                  }
                } else {
                  currentFocus.unfocus();
                }
              }
            },
            child: child,
          );
        },
        home: const SplashPage(),
      ),
    );
  }
}

