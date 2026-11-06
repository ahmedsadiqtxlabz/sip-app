import 'dart:math' as math;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/user_settings.dart';
import '../../features/water_tracking/domain/entities/drink_entry.dart';

class StorageService {
  static const String _drinksBoxName = 'sip_drinks_box';
  static const String _settingsBoxName = 'sip_settings_box';
  static const String _settingsKey = 'user_settings';

  late Box _drinksBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _drinksBox = await Hive.openBox(_drinksBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // --- Dynamic Streak Calculation ---
  /// Calculates the consecutive days streak directly from actual drink logs.
  /// If neither today nor yesterday has a drink logged, streak is broken and returns 0.
  int getStreak() {
    final all = getAllDrinks();
    if (all.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1)));

    final Set<String> loggedDates = {};
    for (final d in all) {
      loggedDates.add(DateFormat('yyyy-MM-dd').format(d.timestamp));
    }

    final hasToday = loggedDates.contains(todayStr);
    final hasYesterday = loggedDates.contains(yesterdayStr);

    if (!hasToday && !hasYesterday) {
      return 0;
    }

    DateTime checkDate = hasToday ? today : today.subtract(const Duration(days: 1));
    int streak = 0;

    while (loggedDates.contains(DateFormat('yyyy-MM-dd').format(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // --- Settings ---
  UserSettings getUserSettings() {
    final raw = _settingsBox.get(_settingsKey);
    final currentStreak = getStreak();

    if (raw is Map) {
      final settings = UserSettings.fromMap(raw);
      final best = math.max(settings.bestStreak, currentStreak);
      final synced = settings.copyWith(
        currentStreak: currentStreak,
        bestStreak: best,
      );
      if (synced != settings) {
        _settingsBox.put(_settingsKey, synced.toMap());
      }
      return synced;
    }

    return UserSettings(
      currentStreak: currentStreak,
      bestStreak: currentStreak,
    );
  }

  Future<void> saveUserSettings(UserSettings settings) async {
    await _settingsBox.put(_settingsKey, settings.toMap());
  }

  // --- Drinks ---
  List<DrinkEntry> getAllDrinks() {
    final List<DrinkEntry> list = [];
    for (var i = 0; i < _drinksBox.length; i++) {
      final raw = _drinksBox.getAt(i);
      if (raw is Map) {
        list.add(DrinkEntry.fromMap(raw));
      }
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  List<DrinkEntry> getTodayDrinks() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    return getAllDrinks().where((d) {
      return DateFormat('yyyy-MM-dd').format(d.timestamp) == todayStr;
    }).toList();
  }

  int getTodayTotalAmount() {
    return getTodayDrinks().fold<int>(0, (sum, d) => sum + d.amount);
  }

  Future<void> addDrink(DrinkEntry entry) async {
    await _drinksBox.add(entry.toMap());
    await _syncStreakSettings();
  }

  Future<void> deleteDrink(String id) async {
    for (var i = 0; i < _drinksBox.length; i++) {
      final raw = _drinksBox.getAt(i);
      if (raw is Map && raw['id'] == id) {
        await _drinksBox.deleteAt(i);
        break;
      }
    }
    await _syncStreakSettings();
  }

  Future<void> _syncStreakSettings() async {
    final currentStreak = getStreak();
    final raw = _settingsBox.get(_settingsKey);
    if (raw is Map) {
      final settings = UserSettings.fromMap(raw);
      final best = math.max(settings.bestStreak, currentStreak);
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await saveUserSettings(
        settings.copyWith(
          currentStreak: currentStreak,
          bestStreak: best,
          lastLoggedDate: currentStreak > 0 ? todayStr : null,
        ),
      );
    }
  }

  // --- Reset All Data ---
  Future<void> resetAllData() async {
    await _drinksBox.clear();
    await _settingsBox.clear();
  }
}
