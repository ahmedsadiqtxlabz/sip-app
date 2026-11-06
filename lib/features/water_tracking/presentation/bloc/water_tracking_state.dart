import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
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

  bool get hasLoggedToday => todayDrinks.isNotEmpty;

  /// Dynamic streak calculated from actual drink history
  int get streak {
    if (allDrinks.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1)));

    final Set<String> loggedDates = {};
    for (final d in allDrinks) {
      loggedDates.add(DateFormat('yyyy-MM-dd').format(d.timestamp));
    }

    if (!loggedDates.contains(todayStr) && !loggedDates.contains(yesterdayStr)) {
      return 0;
    }

    DateTime checkDate = loggedDates.contains(todayStr)
        ? today
        : today.subtract(const Duration(days: 1));

    int count = 0;
    while (loggedDates.contains(DateFormat('yyyy-MM-dd').format(checkDate))) {
      count++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return count;
  }

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
