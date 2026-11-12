import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sip/core/constants/app_constants.dart';
import 'package:sip/core/constants/pro_themes.dart';
import 'package:sip/core/models/user_settings.dart';
import 'package:sip/core/services/notification_service.dart';
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
      expect(settings.hasCompletedOnboarding, false);
      expect(settings.themeName, 'Aqua');
      expect(settings.currentStreak, 0);
      expect(settings.bestStreak, 0);
      expect(settings.lastLoggedDate, null);
      expect(settings.lastCelebratedGoalDate, null);
      expect(settings.remindersEnabled, true);
      expect(settings.wakeTime, '07:00 AM');
      expect(settings.bedTime, '11:00 PM');
      expect(settings.reminderIntervalHours, 2.0);

      final updated = settings.copyWith(
        dailyGoal: 3000,
        isPro: true,
        hasCompletedOnboarding: true,
        themeName: 'Lavender',
        lastCelebratedGoalDate: '2026-11-06',
        remindersEnabled: false,
        wakeTime: '06:30 AM',
        bedTime: '10:30 PM',
        reminderIntervalHours: 1.5,
      );

      expect(updated.dailyGoal, 3000);
      expect(updated.isPro, true);
      expect(updated.hasCompletedOnboarding, true);
      expect(updated.themeName, 'Lavender');
      expect(updated.lastCelebratedGoalDate, '2026-11-06');
      expect(updated.remindersEnabled, false);
      expect(updated.wakeTime, '06:30 AM');
      expect(updated.bedTime, '10:30 PM');
      expect(updated.reminderIntervalHours, 1.5);
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

      // 2. Partial drink (250 ml out of 2500 ml goal) does NOT count towards streak -> streak = 0
      final partialDrink = DrinkEntry(
          id: '0', amount: 250, drinkType: 'water', timestamp: today);
      final statePartial = stateEmpty.copyWith(
        todayDrinks: [partialDrink],
        allDrinks: [partialDrink],
      );
      expect(statePartial.streak, 0);
      expect(statePartial.hasLoggedToday, true);

      // 3. Goal reached (2500 ml logged today) -> streak = 1
      final goalDrinkToday = DrinkEntry(
          id: '1', amount: 2500, drinkType: 'water', timestamp: today);
      final state1 = stateEmpty.copyWith(
        todayDrinks: [goalDrinkToday],
        allDrinks: [goalDrinkToday],
      );
      expect(state1.streak, 1);
      expect(state1.hasLoggedToday, true);

      // 4. Delete drink today -> streak resets to 0
      final stateDeleted = state1.copyWith(
        todayDrinks: [],
        allDrinks: [],
      );
      expect(stateDeleted.streak, 0);
      expect(stateDeleted.hasLoggedToday, false);

      // 5. Consecutive days: today goal met + yesterday goal met -> streak = 2
      final goalDrinkYesterday = DrinkEntry(
          id: '2', amount: 2500, drinkType: 'water', timestamp: yesterday);
      final state2Days = state1.copyWith(
        allDrinks: [goalDrinkToday, goalDrinkYesterday],
      );
      expect(state2Days.streak, 2);

      // 6. 3-day streak: today + yesterday + 2 days ago all met goal -> streak = 3
      final goalDrink2DaysAgo = DrinkEntry(
          id: '3', amount: 2500, drinkType: 'water', timestamp: twoDaysAgo);
      final state3Days = state2Days.copyWith(
        allDrinks: [goalDrinkToday, goalDrinkYesterday, goalDrink2DaysAgo],
      );
      expect(state3Days.streak, 3);

      // 7. Broken streak: logged today, but previous was 4 days ago -> streak = 1
      final goalDrink4DaysAgo = DrinkEntry(
          id: '4', amount: 2500, drinkType: 'water', timestamp: fourDaysAgo);
      final stateBrokenReset = stateEmpty.copyWith(
        todayDrinks: [goalDrinkToday],
        allDrinks: [goalDrinkToday, goalDrink4DaysAgo],
      );
      expect(stateBrokenReset.streak, 1);

      // 8. Morning empty state: yesterday goal was met, today not yet logged -> streak = 1 (alive), hasLoggedToday = false
      final stateMorning = stateEmpty.copyWith(
        todayDrinks: [],
        allDrinks: [goalDrinkYesterday],
      );
      expect(stateMorning.streak, 1);
      expect(stateMorning.hasLoggedToday, false);
    });

    test('NotificationService dynamic reminder calculation and formatting', () {
      const settings = UserSettings(
        wakeTime: '07:00 AM',
        bedTime: '11:00 PM',
        reminderIntervalHours: 2.0,
        remindersEnabled: true,
      );

      final times = NotificationService.calculateReminderTimes(settings);
      expect(times.length, 7);
      expect(times.first, const TimeOfDay(hour: 9, minute: 0));
      expect(times.last, const TimeOfDay(hour: 21, minute: 0));

      final at1015 = DateTime(2026, 11, 9, 10, 15);
      expect(
        NotificationService.getNextReminderLabel(settings, at1015),
        'Next at 11:00 AM',
      );

      final at2200 = DateTime(2026, 11, 9, 22, 0);
      expect(
        NotificationService.getNextReminderLabel(settings, at2200),
        'Tomorrow at 9:00 AM',
      );

      final disabled = settings.copyWith(remindersEnabled: false);
      expect(NotificationService.getNextReminderLabel(disabled), 'Off');

      expect(NotificationService.getIntervalLabel(1.0), 'Every 1 hour');
      expect(NotificationService.getIntervalLabel(2.0), 'Every 2 hours');
      expect(NotificationService.getIntervalLabel(1.5), 'Every 1.5 hours');
    });

    testWidgets(
        'WaterFillRing displays formatted amount, goal, and status percentage',
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

    test('UnitConverter converts correctly between ml and fl oz', () {
      expect(UnitConverter.mlToFlOz(29.5735).round(), 1);
      expect(UnitConverter.mlToFlOz(296).round(), 10);
      expect(UnitConverter.mlToFlOz(3450).round(), 117);
      expect(UnitConverter.flOzToMl(10).round(), 296);

      expect(UnitConverter.formatVolume(2500, 'ml'), '2,500 ml');
      expect(UnitConverter.formatVolume(2500, 'fl oz'), '85 fl oz');
      expect(UnitConverter.formatVolume(3450, 'fl oz'), '117 fl oz');
    });

    test('UserSettings cupPresets serialization, defaults, and copyWith', () {
      const settings = UserSettings();
      expect(settings.cupPresets, [150, 250, 350, 500]);
      expect(settings.userName, '');

      final updated = settings.copyWith(
        cupPresets: [200, 300, 400, 600],
        userName: 'Alex Johnson',
      );
      expect(updated.cupPresets, [200, 300, 400, 600]);
      expect(updated.userName, 'Alex Johnson');

      final map = updated.toMap();
      final fromMap = UserSettings.fromMap(map);
      expect(fromMap.cupPresets, [200, 300, 400, 600]);
      expect(fromMap.userName, 'Alex Johnson');
    });

    test('Dynamic Reminders preview calculates exact remaining goal volume',
        () {
      int calculatePreviewVolume(int goal, int todayTotal) {
        final remaining = (goal - todayTotal).clamp(0, goal);
        return (todayTotal > 0 && remaining == 0)
            ? 0
            : (remaining > 0 ? remaining : goal);
      }

      // Initial state: goal 3450, 0 logged -> 3450 ml remaining
      expect(calculatePreviewVolume(3450, 0), 3450);
      expect(UnitConverter.formatVolume(calculatePreviewVolume(3450, 0), 'ml'),
          '3,450 ml');

      // User drinks 500 ml -> 2950 ml remaining
      expect(calculatePreviewVolume(3450, 500), 2950);
      expect(
          UnitConverter.formatVolume(calculatePreviewVolume(3450, 500), 'ml'),
          '2,950 ml');

      // User changes goal to 2000 ml with 500 logged -> 1500 ml remaining
      expect(calculatePreviewVolume(2000, 500), 1500);

      // User with 2500 ml goal and fl oz unit -> 85 fl oz
      expect(
          UnitConverter.formatVolume(calculatePreviewVolume(2500, 0), 'fl oz'),
          '85 fl oz');
    });
  });
}
