import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/ad_banner_widget.dart';
import '../../../../core/widgets/sip_card.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_bloc.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_state.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<WaterTrackingBloc, WaterTrackingState>(
      builder: (context, state) {
        final settings = state.settings;
        final allDrinks = state.allDrinks;

        // Calculate 7-day totals
        final now = DateTime.now();
        final List<Map<String, dynamic>> last7Days = [];
        int totalWeekIntake = 0;
        int bestDayIntake = 0;
        int daysGoalMet = 0;

        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final dayLabel = DateFormat('E').format(date).substring(0, 1);

          final dayTotal = allDrinks.where((d) {
            return DateFormat('yyyy-MM-dd').format(d.timestamp) == dateStr;
          }).fold<int>(0, (sum, d) => sum + d.amount);

          if (dayTotal > bestDayIntake) bestDayIntake = dayTotal;
          if (dayTotal >= settings.dailyGoal && settings.dailyGoal > 0) {
            daysGoalMet++;
          }
          totalWeekIntake += dayTotal;

          last7Days.add({
            'date': date,
            'label': dayLabel,
            'amount': dayTotal,
            'isToday': i == 0,
          });
        }

        final int dailyAvg = (totalWeekIntake / 7).round();
        final int goalHitPercent = ((daysGoalMet / 7) * 100).round();

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            title: Text(
              'History',
              style: AppTypography.title2(
                color: isDark ? AppColors.darkInk : AppColors.lightInk,
              ),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 7-Day Chart Card ---
                        SipCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Last 7 days',
                                    style: AppTypography.headline(
                                      color: isDark ? AppColors.darkInk : AppColors.lightInk,
                                    ),
                                  ),
                                  Text(
                                    'Goal: ${settings.dailyGoal} ${settings.unit}',
                                    style: AppTypography.caption(
                                      color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Bar Chart
                              SizedBox(
                                height: 140,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: last7Days.map((day) {
                                    final double maxVal = (settings.dailyGoal * 1.25);
                                    final double heightRatio =
                                        ((day['amount'] as int) / maxVal).clamp(0.08, 1.0);
                                    final bool isMet = (day['amount'] as int) >= settings.dailyGoal;

                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 110 * heightRatio,
                                          decoration: BoxDecoration(
                                            gradient: isMet
                                                ? state.activeTheme.gradient
                                                : null,
                                            color: isMet
                                                ? null
                                                : (isDark
                                                    ? AppColors.darkTint
                                                    : AppColors.lightTint),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          day['label'],
                                          style: AppTypography.caption(
                                            color: day['isToday']
                                                ? AppColors.aquaPrimary
                                                : (isDark
                                                    ? AppColors.darkInkMuted
                                                    : AppColors.lightInkMuted),
                                          ).copyWith(
                                            fontWeight: day['isToday']
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Aggregates Stats Row ---
                        Row(
                          children: [
                            Expanded(
                              child: SipCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('DAILY AVG', style: AppTypography.badge(color: AppColors.lightInkMuted)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$dailyAvg ${settings.unit}',
                                      style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SipCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('BEST DAY', style: AppTypography.badge(color: AppColors.lightInkMuted)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$bestDayIntake ${settings.unit}',
                                      style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SipCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('GOAL HIT', style: AppTypography.badge(color: AppColors.lightInkMuted)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$goalHitPercent%',
                                      style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // --- Streak Information Card ---
                        SipCard(
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C1914) : AppColors.lightCoralTint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text('🔥', style: TextStyle(fontSize: 22)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${settings.currentStreak} days streak',
                                      style: AppTypography.headline(color: isDark ? AppColors.darkInk : AppColors.lightInk),
                                    ),
                                    Text(
                                      'Best streak: ${settings.bestStreak} days',
                                      style: AppTypography.caption(color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Consistency Grid (Days you hit your goal) ---
                        SipCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Days you hit your goal',
                                style: AppTypography.headline(color: isDark ? AppColors.darkInk : AppColors.lightInk),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: List.generate(28, (index) {
                                  final isMet = index % 3 != 0; // sample pattern
                                  return Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: isMet
                                          ? AppColors.aquaPrimary
                                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Weekly Insights Card (Pro Feature) ---
                        if (settings.isPro) ...[
                          SipCard(
                            type: SipCardType.upsell,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Weekly insight',
                                        style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'You drink 40% less on weekends. Shift your reminders earlier on Saturdays to stay hydrated.',
                                        style: AppTypography.caption(
                                          color: isDark ? AppColors.darkInkSecondary : AppColors.lightInkSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          SipCard(
                            type: SipCardType.upsell,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PaywallPage()),
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.insights_rounded, color: AppColors.aquaPrimary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Unlock weekly insights with Pro',
                                        style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk),
                                      ),
                                      Text(
                                        'Learn your peak hydration hours',
                                        style: AppTypography.caption(color: isDark ? AppColors.darkLink : AppColors.lightLink),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.lightInkMuted),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // AdMob Banner Slot
                AdBannerWidget(isPro: settings.isPro),
              ],
            ),
          ),
        );
      },
    );
  }
}
