import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sip/core/constants/pro_themes.dart';
import 'package:sip/core/models/user_settings.dart';
import 'package:sip/core/widgets/water_fill_ring.dart';
import 'package:sip/features/water_tracking/domain/entities/drink_entry.dart';
import 'package:sip/features/water_tracking/presentation/bloc/water_tracking_state.dart';

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
      expect(settings.currentStreak, 0);
      expect(settings.bestStreak, 0);
      expect(settings.lastLoggedDate, null);

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

    test('WaterTrackingState streak calculation and lifecycle', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      final fourDaysAgo = today.subtract(const Duration(days: 4));

      // 1. Initial State: No drinks
      const stateEmpty = WaterTrackingState();
      expect(stateEmpty.streak, 0);
      expect(stateEmpty.hasLoggedToday, false);

      // 2. Add 1 drink today -> streak = 1
      final drinkToday = DrinkEntry(id: '1', amount: 250, drinkType: 'water', timestamp: today);
      final state1 = stateEmpty.copyWith(
        todayDrinks: [drinkToday],
        allDrinks: [drinkToday],
      );
      expect(state1.streak, 1);
      expect(state1.hasLoggedToday, true);

      // 3. Delete drink today -> streak resets to 0
      final stateDeleted = state1.copyWith(
        todayDrinks: [],
        allDrinks: [],
      );
      expect(stateDeleted.streak, 0);
      expect(stateDeleted.hasLoggedToday, false);

      // 4. Re-add drink today -> streak restores to 1
      final stateReadded = stateDeleted.copyWith(
        todayDrinks: [drinkToday],
        allDrinks: [drinkToday],
      );
      expect(stateReadded.streak, 1);
      expect(stateReadded.hasLoggedToday, true);

      // 5. Consecutive days: today + yesterday -> streak = 2
      final drinkYesterday = DrinkEntry(id: '2', amount: 500, drinkType: 'water', timestamp: yesterday);
      final state2Days = stateReadded.copyWith(
        allDrinks: [drinkToday, drinkYesterday],
      );
      expect(state2Days.streak, 2);

      // 6. 3-day streak: today + yesterday + 2 days ago -> streak = 3
      final drink2DaysAgo = DrinkEntry(id: '3', amount: 500, drinkType: 'water', timestamp: twoDaysAgo);
      final state3Days = state2Days.copyWith(
        allDrinks: [drinkToday, drinkYesterday, drink2DaysAgo],
      );
      expect(state3Days.streak, 3);

      // 7. Broken streak: logged today, but previous was 4 days ago -> streak = 1
      final drink4DaysAgo = DrinkEntry(id: '4', amount: 500, drinkType: 'water', timestamp: fourDaysAgo);
      final stateBrokenReset = stateEmpty.copyWith(
        todayDrinks: [drinkToday],
        allDrinks: [drinkToday, drink4DaysAgo],
      );
      expect(stateBrokenReset.streak, 1);

      // 8. Morning empty state: yesterday logged, today not yet logged -> streak = 1 (alive), hasLoggedToday = false
      final stateMorning = stateEmpty.copyWith(
        todayDrinks: [],
        allDrinks: [drinkYesterday],
      );
      expect(stateMorning.streak, 1);
      expect(stateMorning.hasLoggedToday, false);
    });

    testWidgets('WaterFillRing displays formatted amount, goal, and status percentage',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WaterFillRing(
                progress: 0.5,
                currentAmount: 1250,
                goalAmount: 2500,
                unit: 'ml',
                size: 220,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // Verifies hero number with comma
      expect(find.text('1,250'), findsOneWidget);
      // Verifies goal subtitle
      expect(find.text('of 2,500 ml'), findsOneWidget);
      // Verifies percentage and halfway status
      expect(find.text('50% · halfway there'), findsOneWidget);
    });
  });
}
