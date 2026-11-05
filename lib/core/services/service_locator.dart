import 'package:get_it/get_it.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import '../../features/water_tracking/presentation/bloc/water_tracking_bloc.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services
  final storageService = StorageService();
  await storageService.init();
  sl.registerSingleton<StorageService>(storageService);

  final notificationService = NotificationService();
  await notificationService.init();
  sl.registerSingleton<NotificationService>(notificationService);

  // BLoCs
  sl.registerFactory<WaterTrackingBloc>(
    () => WaterTrackingBloc(storageService: sl<StorageService>()),
  );
}

