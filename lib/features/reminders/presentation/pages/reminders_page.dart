import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_bloc.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_event.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_state.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> with WidgetsBindingObserver {
  bool _remindersEnabled = false;
  bool _waitingForSettingsReturn = false;
  String _wakeTime = '7:00 AM';
  String _bedTime = '11:00 PM';
  String _interval = 'Every 2 hours';
  String _sound = 'Droplet';
  bool _vibration = true;
  final String _quietHours = '11:00 PM – 7:00 AM';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromSettingsAndPermission(isAppResume: false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncFromSettingsAndPermission(isAppResume: true);
    }
  }

  Future<void> _syncFromSettingsAndPermission({required bool isAppResume}) async {
    final bloc = context.read<WaterTrackingBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final bool hasPermission = await NotificationService().areNotificationsEnabled();
    if (!mounted) return;

    final settings = bloc.state.settings;

    if (isAppResume && _waitingForSettingsReturn) {
      _waitingForSettingsReturn = false;
      if (hasPermission) {
        setState(() {
          _remindersEnabled = true;
        });
        bloc.add(const UpdateReminderSettingsEvent(remindersEnabled: true));
        messenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Notification permissions enabled! Reminders are active.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      } else {
        setState(() {
          _remindersEnabled = false;
        });
        bloc.add(const UpdateReminderSettingsEvent(remindersEnabled: false));
        return;
      }
    }

    if (!hasPermission && settings.remindersEnabled) {
      setState(() => _remindersEnabled = false);
      bloc.add(const UpdateReminderSettingsEvent(remindersEnabled: false));
    } else if (hasPermission && settings.remindersEnabled) {
      setState(() => _remindersEnabled = true);
    } else {
      setState(() => _remindersEnabled = false);
    }

    setState(() {
      _wakeTime = settings.wakeTime;
      _bedTime = settings.bedTime;
      _interval = NotificationService.getIntervalLabel(settings.reminderIntervalHours);
    });
  }

  Future<void> _handleToggleReminders(bool value) async {
    final bloc = context.read<WaterTrackingBloc>();
    if (!value) {
      setState(() => _remindersEnabled = false);
      bloc.add(const UpdateReminderSettingsEvent(remindersEnabled: false));
      return;
    }

    // 1. Check if notifications are currently enabled
    bool hasPermission = await NotificationService().areNotificationsEnabled();
    if (!mounted) return;

    if (hasPermission) {
      setState(() => _remindersEnabled = true);
      bloc.add(const UpdateReminderSettingsEvent(remindersEnabled: true));
      return;
    }

    // 2. Notifications are NOT enabled. Attempt to request permission.
    final granted = await NotificationService().requestPermissions();
    if (!mounted) return;

    hasPermission = granted || await NotificationService().areNotificationsEnabled();
    if (!mounted) return;

    if (hasPermission) {
      setState(() => _remindersEnabled = true);
      bloc.add(const UpdateReminderSettingsEvent(remindersEnabled: true));
      return;
    }

    // 3. Permission was NOT granted (turned off in Settings, denied by user, etc.)
    // Revert switch to OFF and show the Settings Dialog!
    setState(() => _remindersEnabled = false);
    _showSettingsDialog();
  }

  Future<void> _showSettingsDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2630) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.aquaPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_off_rounded,
                  color: AppColors.aquaPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enable Notifications',
                  style: TextStyle(
                    fontFamily: '-apple-system',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Notifications are currently disabled for Sip in your device settings. To receive hydration reminders throughout the day, please enable notifications.',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 14,
              height: 1.4,
              color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF4A5568),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Not Now',
                style: TextStyle(
                  fontFamily: '-apple-system',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1FA2FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                _waitingForSettingsReturn = true;
                await openAppSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  fontFamily: '-apple-system',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
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

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<WaterTrackingBloc, WaterTrackingState>(
      builder: (context, state) {
        final isPro = state.settings.isPro;
        final currentSettings = state.settings.copyWith(
          remindersEnabled: _remindersEnabled,
          wakeTime: _wakeTime,
          bedTime: _bedTime,
        );
        final nextReminderLabel = NotificationService.getNextReminderLabel(currentSettings);
        final nextDt = NotificationService.getNextReminderDateTime(currentSettings);
        final previewTimeStr = nextDt != null
            ? NotificationService.formatTimeOfDay(TimeOfDay(hour: nextDt.hour, minute: nextDt.minute))
            : '3:00 PM';

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Header ---
                        Text(
                          'Reminders',
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.56,
                            color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- Master Toggle Card ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161C24) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isDark
                                ? null
                                : const [
                                    BoxShadow(
                                      color: Color(0x0A0E1116),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                    BoxShadow(
                                      color: Color(0x0D0E1116),
                                      blurRadius: 24,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: Color(0xFF06283A),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reminders',
                                      style: TextStyle(
                                        fontFamily: '-apple-system',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                      ),
                                    ),
                                    Text(
                                      nextReminderLabel,
                                      style: TextStyle(
                                        fontFamily: '-apple-system',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildIosSwitch(
                                value: _remindersEnabled,
                                onChanged: (val) => _handleToggleReminders(val),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // --- Notification Preview Section ---
                        _buildSectionLabel('PREVIEW', isDark),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF161C24)
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF27313C)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 38x38 App droplet icon
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.water_drop_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Sip',
                                              style: TextStyle(
                                                fontFamily: '-apple-system',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                              ),
                                            ),
                                            Text(
                                              previewTimeStr,
                                              style: TextStyle(
                                                fontFamily: '-apple-system',
                                                fontSize: 12,
                                                color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          () {
                                            final remaining = (state.settings.dailyGoal - state.todayTotal).clamp(0, state.settings.dailyGoal);
                                            final remainingStr = remaining > 0 ? '$remaining ${state.settings.unit}' : '0 ${state.settings.unit}';
                                            return remaining > 0
                                                ? "Time for a sip? You're $remainingStr from your goal."
                                                : "You've met your daily goal! Keep hydrated.";
                                          }(),
                                          style: TextStyle(
                                            fontFamily: '-apple-system',
                                            fontSize: 14,
                                            height: 1.3,
                                            color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(left: 50),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          context.read<WaterTrackingBloc>().add(
                                                const AddDrinkEvent(amount: 250, drinkType: 'water'),
                                              );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Logged 250 ml from notification!')),
                                          );
                                        },
                                        child: Container(
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF11324A) : const Color(0xFFE6F4FF),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Log 250 ml',
                                            style: TextStyle(
                                              fontFamily: '-apple-system',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? const Color(0xFF7CC8FF) : const Color(0xFF0A6FB8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Snoozed for 30 minutes')),
                                          );
                                        },
                                        child: Container(
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF27313C) : const Color(0xFFEEF3F7),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Snooze 30 min',
                                            style: TextStyle(
                                              fontFamily: '-apple-system',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // --- SCHEDULE Section ---
                        _buildSectionLabel('SCHEDULE', isDark),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161C24) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isDark
                                ? null
                                : const [
                                    BoxShadow(
                                      color: Color(0x0A0E1116),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                    BoxShadow(
                                      color: Color(0x0D0E1116),
                                      blurRadius: 24,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Column(
                            children: [
                              _buildRow(
                                title: 'Wake time',
                                value: _wakeTime,
                                isDark: isDark,
                                onTap: () async {
                                  final bloc = context.read<WaterTrackingBloc>();
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: _parseTimeOfDay(_wakeTime) ?? const TimeOfDay(hour: 7, minute: 0),
                                  );
                                  if (t == null) return;
                                  if (!mounted) return;
                                  final formatted = _formatTimeOfDay(t);
                                  setState(() => _wakeTime = formatted);
                                  bloc.add(
                                    UpdateReminderSettingsEvent(wakeTime: formatted),
                                  );
                                },
                              ),
                              _buildDivider(isDark),
                              _buildRow(
                                title: 'Bedtime',
                                value: _bedTime,
                                isDark: isDark,
                                onTap: () async {
                                  final bloc = context.read<WaterTrackingBloc>();
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: _parseTimeOfDay(_bedTime) ?? const TimeOfDay(hour: 23, minute: 0),
                                  );
                                  if (t == null) return;
                                  if (!mounted) return;
                                  final formatted = _formatTimeOfDay(t);
                                  setState(() => _bedTime = formatted);
                                  bloc.add(
                                    UpdateReminderSettingsEvent(bedTime: formatted),
                                  );
                                },
                              ),
                              _buildDivider(isDark),
                              _buildRow(
                                title: 'Interval',
                                value: _interval,
                                isDark: isDark,
                                onTap: () {
                                  _showIntervalPicker(context);
                                },
                              ),
                              _buildDivider(isDark),
                              // Smart Reminders Pro Row
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Smart reminders',
                                                style: TextStyle(
                                                  fontFamily: '-apple-system',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(999),
                                                ),
                                                child: const Text(
                                                  'PRO',
                                                  style: TextStyle(
                                                    fontFamily: '-apple-system',
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.4,
                                                    color: Color(0xFF06283A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            'Learns when you usually drink',
                                            style: TextStyle(
                                              fontFamily: '-apple-system',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isPro)
                                      _buildIosSwitch(
                                        value: true,
                                        onChanged: (_) {},
                                        isDark: isDark,
                                      )
                                    else
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const PaywallPage()),
                                          );
                                        },
                                        child: Container(
                                          width: 51,
                                          height: 31,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF27313C) : const Color(0xFFD5DEE6),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              width: 27,
                                              height: 27,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(999),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.2),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.lock_rounded,
                                                  size: 12,
                                                  color: Color(0xFF6B7684),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // --- SOUND & QUIET HOURS Section ---
                        _buildSectionLabel('SOUND & QUIET HOURS', isDark),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161C24) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isDark
                                ? null
                                : const [
                                    BoxShadow(
                                      color: Color(0x0A0E1116),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                    BoxShadow(
                                      color: Color(0x0D0E1116),
                                      blurRadius: 24,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Column(
                            children: [
                              _buildRow(
                                title: 'Sound',
                                value: _sound,
                                isDark: isDark,
                                onTap: () {
                                  _showSoundPicker(context);
                                },
                              ),
                              _buildDivider(isDark),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Vibration',
                                      style: TextStyle(
                                        fontFamily: '-apple-system',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                      ),
                                    ),
                                    _buildIosSwitch(
                                      value: _vibration,
                                      onChanged: (val) => setState(() => _vibration = val),
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ),
                              _buildDivider(isDark),
                              _buildRow(
                                title: 'Quiet hours',
                                value: _quietHours,
                                isDark: isDark,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Quiet hours: 11:00 PM – 7:00 AM')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: '-apple-system',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.72,
          color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String title,
    required String value,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: '-apple-system',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontFamily: '-apple-system',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? const Color(0xFF5B6C7E) : const Color(0xFF9AA4B2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? const Color(0xFF27313C) : const Color(0xFFEEF3F7),
    );
  }

  Widget _buildIosSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF1FA2FF)
              : (isDark ? const Color(0xFF27313C) : const Color(0xFFD5DEE6)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIntervalPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF161C24)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reminder Interval',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            for (final hours in [1.0, 1.5, 2.0, 2.5, 3.0])
              () {
                final label = NotificationService.getIntervalLabel(hours);
                return ListTile(
                  title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: _interval == label
                      ? const Icon(Icons.check_rounded, color: Color(0xFF1FA2FF))
                      : null,
                  onTap: () {
                    setState(() => _interval = label);
                    context.read<WaterTrackingBloc>().add(
                          UpdateReminderSettingsEvent(reminderIntervalHours: hours),
                        );
                    Navigator.pop(context);
                  },
                );
              }(),
          ],
        ),
      ),
    );
  }

  void _showSoundPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF161C24)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Sound',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            for (final s in ['Droplet', 'Ripple', 'Chime', 'Gentle Wave'])
              ListTile(
                title: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: _sound == s
                    ? const Icon(Icons.check_rounded, color: Color(0xFF1FA2FF))
                    : null,
                onTap: () {
                  setState(() => _sound = s);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
