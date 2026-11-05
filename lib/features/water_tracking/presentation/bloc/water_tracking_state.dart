import 'package:equatable/equatable.dart';
import '../../domain/entities/drink_entry.dart';
import '../../../../core/models/user_settings.dart';
import '../../../../core/constants/pro_themes.dart';

class WaterTrackingState extends Equatable {
  final bool isLoading;
  final int todayTotal; // in ml
  final List<DrinkEntry> todayDrinks;
  final List<DrinkEntry> allDrinks;
  final UserSettings settings;
  final SipProTheme activeTheme;

  const WaterTrackingState({
    this.isLoading = false,
    this.todayTotal = 0,
    this.todayDrinks = const [],
    this.allDrinks = const [],
    this.settings = const UserSettings(),
    this.activeTheme = ProThemes.aqua,
  });

  double get progress {
    if (settings.dailyGoal <= 0) return 0.0;
    return todayTotal / settings.dailyGoal;
  }

  bool get isGoalReached => todayTotal >= settings.dailyGoal && settings.dailyGoal > 0;

  WaterTrackingState copyWith({
    bool? isLoading,
    int? todayTotal,
    List<DrinkEntry>? todayDrinks,
    List<DrinkEntry>? allDrinks,
    UserSettings? settings,
    SipProTheme? activeTheme,
  }) {
    return WaterTrackingState(
      isLoading: isLoading ?? this.isLoading,
      todayTotal: todayTotal ?? this.todayTotal,
      todayDrinks: todayDrinks ?? this.todayDrinks,
      allDrinks: allDrinks ?? this.allDrinks,
      settings: settings ?? this.settings,
      activeTheme: activeTheme ?? this.activeTheme,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        todayTotal,
        todayDrinks,
        allDrinks,
        settings,
        activeTheme,
      ];
}

