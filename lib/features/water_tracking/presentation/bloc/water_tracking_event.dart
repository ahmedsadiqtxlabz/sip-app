import 'package:equatable/equatable.dart';

abstract class WaterTrackingEvent extends Equatable {
  const WaterTrackingEvent();

  @override
  List<Object?> get props => [];
}

class LoadWaterTracking extends WaterTrackingEvent {
  const LoadWaterTracking();
}

class AddDrinkEvent extends WaterTrackingEvent {
  final int amount; // in ml
  final String drinkType; // 'water', 'coffee', 'tea', etc.

  const AddDrinkEvent({
    required this.amount,
    this.drinkType = 'water',
  });

  @override
  List<Object?> get props => [amount, drinkType];
}

class DeleteDrinkEvent extends WaterTrackingEvent {
  final String id;

  const DeleteDrinkEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateDailyGoalEvent extends WaterTrackingEvent {
  final int newGoal;

  const UpdateDailyGoalEvent(this.newGoal);

  @override
  List<Object?> get props => [newGoal];
}

class UpdateUnitEvent extends WaterTrackingEvent {
  final String unit; // 'ml' or 'fl oz'

  const UpdateUnitEvent(this.unit);

  @override
  List<Object?> get props => [unit];
}

class ChangeThemeEvent extends WaterTrackingEvent {
  final String themeName;

  const ChangeThemeEvent(this.themeName);

  @override
  List<Object?> get props => [themeName];
}

class SetProStatusEvent extends WaterTrackingEvent {
  final bool isPro;

  const SetProStatusEvent(this.isPro);

  @override
  List<Object?> get props => [isPro];
}

class CompleteOnboardingEvent extends WaterTrackingEvent {
  final int goal;
  final int weight;
  final String activity;
  final String climate;
  final bool remindersEnabled;
  final String? wakeTime;
  final String? bedTime;
  final double? reminderIntervalHours;

  const CompleteOnboardingEvent({
    required this.goal,
    required this.weight,
    required this.activity,
    required this.climate,
    this.remindersEnabled = true,
    this.wakeTime,
    this.bedTime,
    this.reminderIntervalHours,
  });

  @override
  List<Object?> get props => [
        goal,
        weight,
        activity,
        climate,
        remindersEnabled,
        wakeTime,
        bedTime,
        reminderIntervalHours,
      ];
}

class UpdateReminderSettingsEvent extends WaterTrackingEvent {
  final bool? remindersEnabled;
  final String? wakeTime;
  final String? bedTime;
  final double? reminderIntervalHours;
  final bool? quietHoursEnabled;

  const UpdateReminderSettingsEvent({
    this.remindersEnabled,
    this.wakeTime,
    this.bedTime,
    this.reminderIntervalHours,
    this.quietHoursEnabled,
  });

  @override
  List<Object?> get props => [
        remindersEnabled,
        wakeTime,
        bedTime,
        reminderIntervalHours,
        quietHoursEnabled,
      ];
}

class ResetDataEvent extends WaterTrackingEvent {
  const ResetDataEvent();
}

class DismissGoalCelebrationEvent extends WaterTrackingEvent {
  const DismissGoalCelebrationEvent();
}
