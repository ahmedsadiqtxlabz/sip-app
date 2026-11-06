import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  final int dailyGoal; // in ml, default 2500
  final String unit; // 'ml' or 'fl oz'
  final bool hasCompletedOnboarding;
  final String themeName; // 'Aqua', 'Lavender', 'Coral', 'Mint', 'Honey', 'Graphite'
  final bool isPro;
  final bool remindersEnabled;
  final String wakeTime; // '07:00 AM'
  final String bedTime; // '11:00 PM'
  final double reminderIntervalHours; // 1.0, 1.5, 2.0, 3.0
  final bool smartReminders;
  final bool quietHoursEnabled;
  final bool appleHealthSync;
  final String userName;
  final int currentStreak;
  final int bestStreak;
  final String? lastLoggedDate; // 'YYYY-MM-DD'
  final String? lastCelebratedGoalDate; // 'YYYY-MM-DD'
  final int weightKg;
  final String activityLevel; // 'light', 'moderate', 'active'
  final String climate; // 'cool', 'mild', 'hot'

  const UserSettings({
    this.dailyGoal = 2500,
    this.unit = 'ml',
    this.hasCompletedOnboarding = false,
    this.themeName = 'Aqua',
    this.isPro = false,
    this.remindersEnabled = true,
    this.wakeTime = '07:00 AM',
    this.bedTime = '11:00 PM',
    this.reminderIntervalHours = 2.0,
    this.smartReminders = false,
    this.quietHoursEnabled = true,
    this.appleHealthSync = false,
    this.userName = 'Maya',
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastLoggedDate,
    this.lastCelebratedGoalDate,
    this.weightKg = 72,
    this.activityLevel = 'moderate',
    this.climate = 'mild',
  });

  UserSettings copyWith({
    int? dailyGoal,
    String? unit,
    bool? hasCompletedOnboarding,
    String? themeName,
    bool? isPro,
    bool? remindersEnabled,
    String? wakeTime,
    String? bedTime,
    double? reminderIntervalHours,
    bool? smartReminders,
    bool? quietHoursEnabled,
    bool? appleHealthSync,
    String? userName,
    int? currentStreak,
    int? bestStreak,
    String? lastLoggedDate,
    String? lastCelebratedGoalDate,
    int? weightKg,
    String? activityLevel,
    String? climate,
  }) {
    return UserSettings(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      unit: unit ?? this.unit,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      themeName: themeName ?? this.themeName,
      isPro: isPro ?? this.isPro,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      wakeTime: wakeTime ?? this.wakeTime,
      bedTime: bedTime ?? this.bedTime,
      reminderIntervalHours:
          reminderIntervalHours ?? this.reminderIntervalHours,
      smartReminders: smartReminders ?? this.smartReminders,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      appleHealthSync: appleHealthSync ?? this.appleHealthSync,
      userName: userName ?? this.userName,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastLoggedDate: lastLoggedDate ?? this.lastLoggedDate,
      lastCelebratedGoalDate:
          lastCelebratedGoalDate ?? this.lastCelebratedGoalDate,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      climate: climate ?? this.climate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyGoal': dailyGoal,
      'unit': unit,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'themeName': themeName,
      'isPro': isPro,
      'remindersEnabled': remindersEnabled,
      'wakeTime': wakeTime,
      'bedTime': bedTime,
      'reminderIntervalHours': reminderIntervalHours,
      'smartReminders': smartReminders,
      'quietHoursEnabled': quietHoursEnabled,
      'appleHealthSync': appleHealthSync,
      'userName': userName,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastLoggedDate': lastLoggedDate,
      'lastCelebratedGoalDate': lastCelebratedGoalDate,
      'weightKg': weightKg,
      'activityLevel': activityLevel,
      'climate': climate,
    };
  }

  factory UserSettings.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const UserSettings();
    return UserSettings(
      dailyGoal: (map['dailyGoal'] as num?)?.toInt() ?? 2500,
      unit: (map['unit'] as String?) ?? 'ml',
      hasCompletedOnboarding:
          (map['hasCompletedOnboarding'] as bool?) ?? false,
      themeName: (map['themeName'] as String?) ?? 'Aqua',
      isPro: (map['isPro'] as bool?) ?? false,
      remindersEnabled: (map['remindersEnabled'] as bool?) ?? true,
      wakeTime: (map['wakeTime'] as String?) ?? '07:00 AM',
      bedTime: (map['bedTime'] as String?) ?? '11:00 PM',
      reminderIntervalHours:
          (map['reminderIntervalHours'] as num?)?.toDouble() ?? 2.0,
      smartReminders: (map['smartReminders'] as bool?) ?? false,
      quietHoursEnabled: (map['quietHoursEnabled'] as bool?) ?? true,
      appleHealthSync: (map['appleHealthSync'] as bool?) ?? false,
      userName: (map['userName'] as String?) ?? 'Maya',
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
      lastLoggedDate: map['lastLoggedDate'] as String?,
      lastCelebratedGoalDate: map['lastCelebratedGoalDate'] as String?,
      weightKg: (map['weightKg'] as num?)?.toInt() ?? 72,
      activityLevel: (map['activityLevel'] as String?) ?? 'moderate',
      climate: (map['climate'] as String?) ?? 'mild',
    );
  }

  @override
  List<Object?> get props => [
        dailyGoal,
        unit,
        hasCompletedOnboarding,
        themeName,
        isPro,
        remindersEnabled,
        wakeTime,
        bedTime,
        reminderIntervalHours,
        smartReminders,
        quietHoursEnabled,
        appleHealthSync,
        userName,
        currentStreak,
        bestStreak,
        lastLoggedDate,
        lastCelebratedGoalDate,
        weightKg,
        activityLevel,
        climate,
      ];
}

