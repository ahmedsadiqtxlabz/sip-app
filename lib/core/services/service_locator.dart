import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'purchase_service.dart';
import '../../features/water_tracking/presentation/bloc/water_tracking_bloc.dart';
import '../../features/water_tracking/presentation/bloc/water_tracking_event.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services
  final storageService = StorageService();
  await storageService.init();
  sl.registerSingleton<StorageService>(storageService);

  final notificationService = NotificationService();
  await notificationService.init();
  sl.registerSingleton<NotificationService>(notificationService);

  // BLoCs (Lazy Singleton so app & background services share the exact state instance)
  sl.registerLazySingleton<WaterTrackingBloc>(
    () => WaterTrackingBloc(storageService: sl<StorageService>()),
  );

  // Initialize RevenueCat In-App Purchases with automatic entitlement sync
  await PurchaseService.init(
    onProStatusChanged: (isPro) {
      if (sl.isRegistered<WaterTrackingBloc>()) {
        sl<WaterTrackingBloc>().add(SetProStatusEvent(isPro));
      }
    },
  );

  // Check initial entitlement status on launch
  PurchaseService.isProUser().then((isPro) {
    debugPrint('[ServiceLocator] Initial entitlement status on launch -> isPro: $isPro');
    if (sl.isRegistered<WaterTrackingBloc>()) {
      sl<WaterTrackingBloc>().add(SetProStatusEvent(isPro));
    }
  });
}
