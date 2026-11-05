import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sip_card.dart';
import '../../../../core/widgets/sip_chip.dart';
import '../../../../core/widgets/sip_toggle.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_bloc.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_state.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  bool _remindersEnabled = true;
  String _wakeTime = '07:00 AM';
  String _bedTime = '11:00 PM';
  double _intervalHours = 1.5;
  bool _smartReminders = false;
  bool _quietHours = true;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<WaterTrackingBloc, WaterTrackingState>(
      builder: (context, state) {
        final isPro = state.settings.isPro;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            title: Text(
              'Reminders',
              style: AppTypography.title2(
                color: isDark ? AppColors.darkInk : AppColors.lightInk,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Master Toggle Card
                SipCard(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkTint : AppColors.lightTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: AppColors.aquaPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reminders',
                          style: AppTypography.headline(color: isDark ? AppColors.darkInk : AppColors.lightInk),
                        ),
                      ),
                      SipToggle(
                        value: _remindersEnabled,
                        onChanged: (val) => setState(() => _remindersEnabled = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Next Reminder countdown card
                SipCard(
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: AppColors.aquaPrimary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Next reminder in 42m',
                        style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk),
                      ),
                      const Spacer(),
                      Text(
                        '03:00 PM',
                        style: AppTypography.caption(color: isDark ? AppColors.darkLink : AppColors.lightLink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Schedule Section
                Text('SCHEDULE', style: AppTypography.sectionLabel(color: AppColors.lightInkMuted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SipCard(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 7, minute: 0),
                          );
                          if (picked != null) {
                            setState(() {
                              _wakeTime = picked.format(context);
                            });
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WAKE UP', style: AppTypography.sectionLabel(color: AppColors.lightInkMuted)),
                            const SizedBox(height: 6),
                            Text(_wakeTime, style: AppTypography.headline(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SipCard(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 23, minute: 0),
                          );
                          if (picked != null) {
                            setState(() {
                              _bedTime = picked.format(context);
                            });
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BEDTIME', style: AppTypography.sectionLabel(color: AppColors.lightInkMuted)),
                            const SizedBox(height: 6),
                            Text(_bedTime, style: AppTypography.headline(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Remind Me Every
                Text('REMIND ME EVERY', style: AppTypography.sectionLabel(color: AppColors.lightInkMuted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final interval in [1.0, 1.5, 2.0, 3.0]) ...[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SipChip(
                            label: '${interval == 1.0 ? "1" : (interval == 2.0 ? "2" : (interval == 3.0 ? "3" : "1.5"))} h',
                            state: _intervalHours == interval ? SipChipState.selected : SipChipState.defaultState,
                            onTap: () => setState(() => _intervalHours = interval),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Smart Reminders Card (Pro)
                SipCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Smart reminders', style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.brandGradient,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text('PRO', style: AppTypography.badge(color: AppColors.lightOnGradient)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Learns when you usually drink to avoid spamming',
                              style: AppTypography.caption(color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted),
                            ),
                          ],
                        ),
                      ),
                      SipToggle(
                        value: _smartReminders,
                        isLockedPro: !isPro,
                        onChanged: (val) {
                          if (!isPro) {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
                          } else {
                            setState(() => _smartReminders = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quiet Hours Card
                SipCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quiet hours', style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                            const SizedBox(height: 4),
                            Text('11:00 PM – 7:00 AM', style: AppTypography.caption(color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted)),
                          ],
                        ),
                      ),
                      SipToggle(
                        value: _quietHours,
                        onChanged: (val) => setState(() => _quietHours = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
