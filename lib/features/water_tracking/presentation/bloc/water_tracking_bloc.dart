import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/pro_themes.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/drink_entry.dart';
import 'water_tracking_event.dart';
import 'water_tracking_state.dart';

class WaterTrackingBloc extends Bloc<WaterTrackingEvent, WaterTrackingState> {
  final StorageService storageService;

  WaterTrackingBloc({required this.storageService})
      : super(const WaterTrackingState()) {
    on<LoadWaterTracking>(_onLoadWaterTracking);
    on<AddDrinkEvent>(_onAddDrink);
    on<DeleteDrinkEvent>(_onDeleteDrink);
    on<UpdateDailyGoalEvent>(_onUpdateDailyGoal);
    on<UpdateUnitEvent>(_onUpdateUnit);
    on<ChangeThemeEvent>(_onChangeTheme);
    on<SetProStatusEvent>(_onSetProStatus);
    on<CompleteOnboardingEvent>(_onCompleteOnboarding);
    on<UpdateReminderSettingsEvent>(_onUpdateReminderSettings);
    on<ResetDataEvent>(_onResetData);
    on<DismissGoalCelebrationEvent>(_onDismissGoalCelebration);
  }

  void _onLoadWaterTracking(
    LoadWaterTracking event,
    Emitter<WaterTrackingState> emit,
  ) {
    emit(state.copyWith(isLoading: true));
    final settings = storageService.getUserSettings();
    final todayDrinks = storageService.getTodayDrinks();
    final allDrinks = storageService.getAllDrinks();
    final todayTotal = storageService.getTodayTotalAmount();
    final theme = ProThemes.fromName(settings.themeName);

    emit(state.copyWith(
      isLoading: false,
      settings: settings,
      todayDrinks: todayDrinks,
      allDrinks: allDrinks,
      todayTotal: todayTotal,
      activeTheme: theme,
    ));
  }

  Future<void> _onAddDrink(
    AddDrinkEvent event,
    Emitter<WaterTrackingState> emit,
  ) async {
    final newEntry = DrinkEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: event.amount,
      drinkType: event.drinkType,
      timestamp: DateTime.now(),
    );

    await storageService.addDrink(newEntry);
    add(const LoadWaterTracking());
  }

  Future<void> _onDeleteDrink(
    DeleteDrinkEvent event,
    Emitter<WaterTrackingState> emit,
  ) async {
    await storageService.deleteDrink(event.id);
    final todayTotal = storageService.getTodayTotalAmount();
    if (todayTotal < state.settings.dailyGoal &&
        state.settings.lastCelebratedGoalDate != null) {
      final updated = state.settings.copyWith(lastCelebratedGoalDate: null);
      await storageService.saveUserSettings(updated);
    }
    add(const LoadWaterTracking());
  }

  Future<void> _onUpdateDailyGoal(
    UpdateDailyGoalEvent event,
    Emitter<WaterTrackingState> emit,
  ) async {
    final updated = state.settings.copyWith(dailyGoal: event.newGoal);
    await storageService.saveUserSettings(updated);
    emit(state.copyWith(settings: updated));
  }

  Future<void> _onUpdateUnit(
    UpdateUnitEvent event,
    Emitter<WaterTrackingState> emit,
  ) async {
    final updated = state.settings.copyWith(unit: event.unit);
    await storageService.saveUserSettings(updated);
    emit(state.copyWith(settings: updated));
  }

  Future<void> _onChangeTheme(
    ChangeThemeEvent event,
    Emitter<WaterTrackingState> emit,
  ) async {
    final updated = state.settings.copyWith(themeName: event.themeName);
    await storageService.saveUserSettings(updated);
    final theme = ProThemes.fromName(event.themeName);
    emit(state.copyWith(settings: updated, activeTheme: theme));
  }

  Future<void> _onSetProStatus(
    SetProStatusEvent event,
    Emitter<WaterTrackingState> emit,
  ) async {
    final updated = state.settings.copyWith(isPro: event.isPro);
    await storageService.saveUserSettings(updated);
    emit(state.copyWith(settings: updated));
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboardingEvent event,
    Emitter<WaterTrackingState> emit,
  ) async {
    final updated = state.settings.copyWith(
      dailyGoal: event.goal,
      weightKg: event.weight,
      activityLevel: event.activity,
      climate: event.climate,
      remindersEnabled: event.remindersEnabled,
      wakeTime: event.wakeTime ?? state.settings.wakeTime,
      bedTime: event.bedTime ?? state.settings.bedTime,
      reminderIntervalHours:
          event.reminderIntervalHours ?? state.settings.reminderIntervalHours,
      hasCompletedOnboarding: true,
    );
    await storageService.saveUserSettings(updated);
    await storageService.setOnboardingCompleted(true);
    emit(state.copyWith(settings: updated));

    if (updated.remindersEnabled) {
      await NotificationService().scheduleReminders(updated);
    } else {
      await NotificationService().cancelAllReminders();
    }
  }

  Future<void> _onUpdateReminderSettings(
    UpdateReminderSettingsEvent event,
    Emitter<WaterTrackingState> emit,
  ) async {
    final updated = state.settings.copyWith(
      remindersEnabled:
          event.remindersEnabled ?? state.settings.remindersEnabled,
      wakeTime: event.wakeTime ?? state.settings.wakeTime,
      bedTime: event.bedTime ?? state.settings.bedTime,
      reminderIntervalHours:
          event.reminderIntervalHours ?? state.settings.reminderIntervalHours,
      quietHoursEnabled:
          event.quietHoursEnabled ?? state.settings.quietHoursEnabled,
    );
    await storageService.saveUserSettings(updated);
    emit(state.copyWith(settings: updated));

    if (updated.remindersEnabled) {
      await NotificationService().scheduleReminders(updated);
    } else {
      await NotificationService().cancelAllReminders();
    }
  }

  Future<void> _onResetData(
    ResetDataEvent event,
    Emitter<WaterTrackingState> emit,
  ) async {
    await storageService.resetAllData();
    add(const LoadWaterTracking());
  }

  Future<void> _onDismissGoalCelebration(
    DismissGoalCelebrationEvent event,
    Emitter<WaterTrackingState> emit,
  ) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final updated = state.settings.copyWith(lastCelebratedGoalDate: todayStr);
    await storageService.saveUserSettings(updated);
    await storageService.setOnboardingCompleted(true);
    emit(state.copyWith(settings: updated));
  }
}

