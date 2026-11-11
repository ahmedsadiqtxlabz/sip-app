import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/services/ad_service.dart';
import 'core/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle uncaught Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  // Lock to portrait mode
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } catch (e) {
    debugPrint('[Main] Error setting orientation: $e');
  }

  // Initialize Storage (Hive) & Notifications safely
  try {
    await setupServiceLocator();
  } catch (e, stack) {
    debugPrint('[Main] Fatal error during setupServiceLocator: $e\n$stack');
  }

  // Initialize AdMob asynchronously without blocking app launch
  AdService.initialize().catchError((e) {
    debugPrint('[Main] Error initializing AdMob: $e');
  });

  // Always mount the app and start rendering the Splash screen
  runApp(const SipApp());
}
