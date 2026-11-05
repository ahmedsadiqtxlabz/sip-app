import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/services/ad_service.dart';
import 'core/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode per Ahmed's iPhone-only instruction
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Storage (Hive) & Notifications
  await setupServiceLocator();

  // Initialize AdMob
  await AdService.initialize();

  runApp(const SipApp());
}
