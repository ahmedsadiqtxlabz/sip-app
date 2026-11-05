import 'package:flutter_test/flutter_test.dart';
import 'package:sip/core/constants/pro_themes.dart';
import 'package:sip/core/models/user_settings.dart';
import 'package:sip/features/water_tracking/domain/entities/drink_entry.dart';

void main() {
  group('Sip Models & Logic Unit Tests', () {
    test('DrinkEntry serialization and deserialization', () {
      final now = DateTime.now();
      final entry = DrinkEntry(
        id: '123',
        amount: 250,
        drinkType: 'water',
        timestamp: now,
      );

      final map = entry.toMap();
      final fromMap = DrinkEntry.fromMap(map);

      expect(fromMap.id, '123');
      expect(fromMap.amount, 250);
      expect(fromMap.drinkType, 'water');
      expect(fromMap.timestamp.toIso8601String(), now.toIso8601String());
    });

    test('UserSettings defaults and copyWith', () {
      const settings = UserSettings();
      expect(settings.dailyGoal, 2500);
      expect(settings.unit, 'ml');
      expect(settings.isPro, false);
      expect(settings.themeName, 'Aqua');

      final updated = settings.copyWith(
        dailyGoal: 3000,
        isPro: true,
        themeName: 'Lavender',
      );

      expect(updated.dailyGoal, 3000);
      expect(updated.isPro, true);
      expect(updated.themeName, 'Lavender');
    });

    test('ProThemes has 6 themes and finds by name', () {
      expect(ProThemes.allThemes.length, 6);
      expect(ProThemes.fromName('coral').name, 'Coral');
      expect(ProThemes.fromName('MINT').name, 'Mint');
      expect(ProThemes.fromName('non_existent').name, 'Aqua');
    });
  });
}
