import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class AdService {
  static bool isInitialized = false;

  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      isInitialized = true;
      debugPrint('[AdService] MobileAds initialized successfully');
    } catch (e) {
      debugPrint('[AdService] Error initializing MobileAds: $e');
    }
  }

  // Real AdMob unit IDs from Ahmed Sadiq
  static const String _realIosBannerId = 'ca-app-pub-9873700043748462/3525594186';
  static const String _realAndroidBannerId = 'ca-app-pub-9873700043748462/6666140726';

  // Standard Google Test Ad Unit IDs
  static const String _testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS ? _testIosBannerId : _testAndroidBannerId;
    }
    return Platform.isIOS ? _realIosBannerId : _realAndroidBannerId;
  }
}

