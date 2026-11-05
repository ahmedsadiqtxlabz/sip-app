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

  // --- Settings ---
  UserSettings getUserSettings() {
    final raw = _settingsBox.get(_settingsKey);
    if (raw is Map) {
      return UserSettings.fromMap(raw);
    }
    return const UserSettings();
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
    await _updateStreakOnDrinkLogged();
  }

  Future<void> deleteDrink(String id) async {
    for (var i = 0; i < _drinksBox.length; i++) {
      final raw = _drinksBox.getAt(i);
      if (raw is Map && raw['id'] == id) {
        await _drinksBox.deleteAt(i);
        break;
      }
    }
  }

  // --- Streak Calculation ---
  Future<void> _updateStreakOnDrinkLogged() async {
    final settings = getUserSettings();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (settings.lastLoggedDate == todayStr) {
      // Already logged today
      return;
    }

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

    int newStreak;
    if (settings.lastLoggedDate == yesterdayStr) {
      newStreak = settings.currentStreak + 1;
    } else {
      newStreak = 1;
    }

    final newBest = newStreak > settings.bestStreak ? newStreak : settings.bestStreak;

    await saveUserSettings(
      settings.copyWith(
        currentStreak: newStreak,
        bestStreak: newBest,
        lastLoggedDate: todayStr,
      ),
    );
  }

  // --- Reset All Data ---
  Future<void> resetAllData() async {
    await _drinksBox.clear();
    await _settingsBox.clear();
  }
}
