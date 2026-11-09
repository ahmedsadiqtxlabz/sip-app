import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Color, TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/user_settings.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('[NotificationService] Local timezone configured: $timeZoneName');
    } catch (e) {
      debugPrint('[NotificationService] Error initializing local timezone: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tapped or quick action "log_250"
      },
    );

    // Create Notification Channel for Android
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'sip_reminders',
          'Water Reminders',
          description: 'Gentle nudges to drink water throughout your day',
          importance: Importance.high,
        ),
      );
    } catch (_) {}
  }

  Future<bool> requestPermissions() async {
    debugPrint('[NotificationService] Requesting notification permissions...');
    // 1. Native Android request via flutter_local_notifications plugin
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted =
          await androidPlugin?.requestNotificationsPermission();
      debugPrint('[NotificationService] Native Android result: $androidGranted');

      // Request exact alarm permission on Android 12+ if not already granted
      try {
        final canExact = await androidPlugin?.canScheduleExactNotifications();
        debugPrint('[NotificationService] canScheduleExactNotifications: $canExact');
        if (canExact == false) {
          await androidPlugin?.requestExactAlarmsPermission();
        }
      } catch (e) {
        debugPrint('[NotificationService] Exact alarm check error: $e');
      }

      if (androidGranted == true) return true;
    } catch (e) {
      debugPrint('[NotificationService] Native Android error: $e');
    }

    // 2. Native iOS request via flutter_local_notifications plugin
    try {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[NotificationService] Native iOS result: $iosGranted');
      if (iosGranted == true) return true;
    } catch (e) {
      debugPrint('[NotificationService] Native iOS error: $e');
    }

    // 3. Fallback request via permission_handler
    try {
      final status = await Permission.notification.request();
      debugPrint('[NotificationService] permission_handler fallback status: $status');
      if (status.isGranted || status.isProvisional || status.isLimited) {
        return true;
      }
    } catch (e) {
      debugPrint('[NotificationService] permission_handler fallback error: $e');
    }

    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    // 1. Native iOS check via flutter_local_notifications (UNUserNotificationCenter)
    try {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final options = await iosPlugin?.checkPermissions();
      if (options != null) {
        final isEnabled = options.isEnabled || options.isAlertEnabled || options.isProvisionalEnabled;
        debugPrint('[NotificationService] iOS checkPermissions: isEnabled=${options.isEnabled}, alert=${options.isAlertEnabled}, sound=${options.isSoundEnabled} -> hasPermission=$isEnabled');
        return isEnabled;
      }
    } catch (e) {
      debugPrint('[NotificationService] iOS checkPermissions error: $e');
    }

    // 2. Native Android check via flutter_local_notifications (NotificationManagerCompat.areNotificationsEnabled)
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await androidPlugin?.areNotificationsEnabled();
      if (enabled != null) return enabled;
    } catch (_) {}

    // 3. Fallback check via permission_handler
    try {
      final status = await Permission.notification.status;
      return status.isGranted || status.isProvisional || status.isLimited;
    } catch (_) {}

    return false;
  }

  Future<PermissionStatus> checkPermissionStatus() async {
    return await Permission.notification.status;
  }

  Future<PermissionStatus> requestPermission() async {
    return await Permission.notification.request();
  }

  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> scheduleReminders(UserSettings settings) async {
    await _notificationsPlugin.cancelAll();

    if (!settings.remindersEnabled) {
      debugPrint('[NotificationService] Reminders are disabled. Cancelled all reminders.');
      return;
    }

    final hasPermission = await areNotificationsEnabled();
    if (!hasPermission) {
      debugPrint('[NotificationService] Notifications are NOT enabled on device.');
      return;
    }

    // Ensure local timezone is configured
    if (tz.local.name == 'UTC') {
      try {
        final String tzName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzName));
        debugPrint('[NotificationService] Synced local timezone: $tzName');
      } catch (_) {}
    }

    // Daily recurring reminder notification details
    const androidDetails = AndroidNotificationDetails(
      'sip_reminders',
      'Water Reminders',
      channelDescription: 'Gentle nudges to drink water throughout your day',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('app_icon'),
      color: Color(0xFF1FA2FF),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Determine Android schedule mode safely (check if exact alarms are allowed)
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await androidPlugin?.canScheduleExactNotifications();
      debugPrint('[NotificationService] canScheduleExactNotifications: $canExact');
      if (canExact == false) {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    } catch (_) {
      scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final times = _calculateReminderTimes(settings);

    for (int i = 0; i < times.length; i++) {
      final t = times[i];
      final scheduledDate = _nextInstanceOfTime(t.hour, t.minute);

      try {
        await _notificationsPlugin.zonedSchedule(
          i + 1,
          'Time for a sip! 💧',
          'Stay on track to hit your ${settings.dailyGoal} ${settings.unit} goal today.',
          scheduledDate,
          details,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('[NotificationService] Error scheduling recurring reminder #$i: $e');
      }
    }
  }

  List<TimeOfDay> _calculateReminderTimes(UserSettings settings) {
    try {
      final wake = _parseTimeOfDay(settings.wakeTime);
      final bed = _parseTimeOfDay(settings.bedTime);

      if (wake != null && bed != null) {
        int wakeMinutes = wake.hour * 60 + wake.minute;
        int bedMinutes = bed.hour * 60 + bed.minute;

        if (bedMinutes <= wakeMinutes) {
          bedMinutes += 24 * 60;
        }

        final intervalMinutes = (settings.reminderIntervalHours * 60).round();
        if (intervalMinutes > 0) {
          final List<TimeOfDay> calculated = [];
          for (int m = wakeMinutes + intervalMinutes;
              m < bedMinutes;
              m += intervalMinutes) {
            final normalized = m % (24 * 60);
            calculated.add(
              TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60),
            );
          }
          if (calculated.isNotEmpty) {
            return calculated;
          }
        }
      }
    } catch (_) {}

    return const [
      TimeOfDay(hour: 9, minute: 30),
      TimeOfDay(hour: 12, minute: 0),
      TimeOfDay(hour: 15, minute: 0),
      TimeOfDay(hour: 18, minute: 30),
    ];
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final trimmed = timeStr.trim();
      final spaceIndex = trimmed.lastIndexOf(' ');
      if (spaceIndex != -1) {
        final timePart = trimmed.substring(0, spaceIndex);
        final periodPart = trimmed.substring(spaceIndex + 1).toUpperCase();
        final parts = timePart.split(':');
        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          if (periodPart == 'PM' && hour < 12) hour += 12;
          if (periodPart == 'AM' && hour == 12) hour = 0;
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (_) {}
    return null;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
