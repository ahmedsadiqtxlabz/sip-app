import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  static const String entitlementId = 'pro';
  static const String monthlyProductId = 'sip_pro_monthly';
  static const String yearlyProductId = 'sip_pro_yearly';

  // Placeholder RevenueCat API Keys (Updated in production with real keys)
  static const String _iosApiKey = 'appl_sip_placeholder_key';
  static const String _androidApiKey = 'goog_sip_placeholder_key';

  static Future<void> init() async {
    final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
    final configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);
  }

  static Future<bool> isProUser() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Error checking customer info: $e');
      return false;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Error purchasing package: $e');
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }
}

