import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  // RevenueCat Identifiers from App Store & RevenueCat Dashboard
  static const String _iosApiKey = 'appl_tVECmOlUTVfNVFYYDPVkdAVbQHo';
  static const String _androidApiKey = 'goog_sip_placeholder_key';

  static const String entitlementId = 'pro';
  static const String defaultOfferingId = 'default';
  static const String yearlyPackageId = '\$rc_annual';
  static const String monthlyPackageId = '\$rc_monthly';
  static const String yearlyProductId = 'sip_pro_yearly';
  static const String monthlyProductId = 'sip_pro_monthly';

  static bool _isConfigured = false;

  /// Initializes RevenueCat with the public SDK key and listens for entitlement changes.
  static Future<void> init({ValueChanged<bool>? onProStatusChanged}) async {
    if (_isConfigured) return;

    // The key provided by Sajid (appl_tVECmOlUTVfNVFYYDPVkdAVbQHo) is for iOS (App Store).
    // If running on Android and a real Google Play key (goog_...) hasn't been added yet,
    // skip network calls to prevent 401 InvalidCredentialsError.
    if (!Platform.isIOS && _androidApiKey.startsWith('goog_sip_placeholder')) {
      debugPrint(
        '[PurchaseService] Running on Android. The RevenueCat key provided is for iOS (appl_...). '
        'Skipping RevenueCat initialization until Android key (goog_...) is provided.',
      );
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      _isConfigured = true;

      // Listen for background subscription updates, renewals, and cancellations
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        final isPro = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
        onProStatusChanged?.call(isPro);
      });
    } catch (e) {
      debugPrint('[PurchaseService] Error initializing RevenueCat: $e');
    }
  }

  /// Checks if the current user has an active Pro entitlement
  static Future<bool> isProUser() async {
    try {
      if (!_isConfigured) return false;
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('[PurchaseService] Error checking customer info: $e');
      return false;
    }
  }

  /// Fetches live offerings from RevenueCat
  static Future<Offerings?> fetchOfferings() async {
    try {
      if (!_isConfigured) return null;
      final offerings = await Purchases.getOfferings();
      return offerings;
    } catch (e) {
      debugPrint('[PurchaseService] Error fetching offerings: $e');
      return null;
    }
  }

  /// Helper to extract the Annual package from offerings
  static Package? getYearlyPackage(Offerings? offerings) {
    if (offerings == null) return null;
    final current = offerings.current ?? offerings.all[defaultOfferingId];
    if (current == null) return null;

    if (current.annual != null) return current.annual;

    for (final p in current.availablePackages) {
      if (p.packageType == PackageType.annual ||
          p.identifier == yearlyPackageId ||
          p.storeProduct.identifier == yearlyProductId) {
        return p;
      }
    }
    return null;
  }

  /// Helper to extract the Monthly package from offerings
  static Package? getMonthlyPackage(Offerings? offerings) {
    if (offerings == null) return null;
    final current = offerings.current ?? offerings.all[defaultOfferingId];
    if (current == null) return null;

    if (current.monthly != null) return current.monthly;

    for (final p in current.availablePackages) {
      if (p.packageType == PackageType.monthly ||
          p.identifier == monthlyPackageId ||
          p.storeProduct.identifier == monthlyProductId) {
        return p;
      }
    }
    return null;
  }

  /// Purchases a selected package via StoreKit
  /// Returns `true` if purchase succeeded and user has active Pro entitlement.
  /// Returns `false` on user cancellation or failure.
  static Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[PurchaseService] User cancelled the purchase flow');
      } else {
        debugPrint('[PurchaseService] PlatformException during purchase: ${e.message}');
      }
      return false;
    } catch (e) {
      debugPrint('[PurchaseService] Unexpected purchase error: $e');
      return false;
    }
  }

  /// Restores previous purchases for the current Apple ID
  static Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      debugPrint('[PurchaseService] PlatformException during restore: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[PurchaseService] Unexpected restore error: $e');
      return false;
    }
  }
}
