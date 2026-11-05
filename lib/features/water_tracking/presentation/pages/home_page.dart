import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/ad_banner_widget.dart';
import '../../../../core/widgets/sip_card.dart';
import '../../../../core/widgets/sip_chip.dart';
import '../../../../core/widgets/water_fill_ring.dart';
import '../bloc/water_tracking_bloc.dart';
import '../bloc/water_tracking_event.dart';
import '../bloc/water_tracking_state.dart';
import '../widgets/log_drink_sheet.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _openLogSheet(BuildContext context, WaterTrackingState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogDrinkSheet(
        isPro: state.settings.isPro,
        unit: state.settings.unit,
        onAddDrink: (amount, type) {
          context.read<WaterTrackingBloc>().add(
                AddDrinkEvent(amount: amount, drinkType: type),
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<WaterTrackingBloc, WaterTrackingState>(
      builder: (context, state) {
        final settings = state.settings;
        final isGoalReached = state.isGoalReached;
        final todayDrinks = state.todayDrinks;
        final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());

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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // --- Header Row ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()}, ${settings.userName}',
                                  style: AppTypography.title2(
                                    color: isDark ? AppColors.darkInk : AppColors.lightInk,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: AppTypography.caption(
                                    color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
                                  ),
                                ),
                              ],
                            ),
                            // Streak Flame Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C1914) : AppColors.lightCoralTint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${settings.currentStreak} days',
                                    style: AppTypography.caption(
                                      color: isDark ? const Color(0xFFFF8B6B) : AppColors.lightCoralText,
                                    ).copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- Central Water Ring ---
                        WaterFillRing(
                          progress: state.progress,
                          currentAmount: state.todayTotal,
                          goalAmount: settings.dailyGoal,
                          unit: settings.unit,
                          customGradient: state.activeTheme.gradient,
                          isGoalReached: isGoalReached,
                        ),
                        const SizedBox(height: 24),

                        // --- Empty State Note (If 0 ml) ---
                        if (state.todayTotal == 0) ...[
                          Text(
                            'First sip of the day?',
                            style: AppTypography.headline(
                              color: isDark ? AppColors.darkInk : AppColors.lightInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Log a drink below to start your streak.',
                            style: AppTypography.caption(
                              color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // --- Goal Reached Celebration Banner ---
                        if (isGoalReached) ...[
                          SipCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Text('🎉', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "That's ${settings.currentStreak} days in a row!",
                                        style: AppTypography.headline(
                                          color: isDark ? AppColors.darkInk : AppColors.lightInk,
                                        ),
                                      ),
                                      Text(
                                        'See you tomorrow morning.',
                                        style: AppTypography.caption(
                                          color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_rounded, color: AppColors.aquaPrimary),
                                  onPressed: () {
                                    Share.share(
                                      'I hit my daily water goal of ${settings.dailyGoal} ${settings.unit} on Sip! 🔥 ${settings.currentStreak} days streak.',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // --- 4 Quick-Add Cups Row ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final cup in [150, 250, 350, 500]) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: SipChip(
                                  label: '$cup',
                                  onTap: () {
                                    context.read<WaterTrackingBloc>().add(
                                          AddDrinkEvent(amount: cup),
                                        );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            // Custom Add Button
                            GestureDetector(
                              onTap: () => _openLogSheet(context, state),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: state.activeTheme.gradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- Reminder Status Pill ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alarm_rounded, size: 15, color: AppColors.aquaPrimary),
                              const SizedBox(width: 6),
                              Text(
                                'Next reminder at 3:00 PM · Every 2 hours',
                                style: AppTypography.caption(
                                  color: isDark ? AppColors.darkInkSecondary : AppColors.lightInkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Pro Upsell Card (If !isPro) ---
                        if (!settings.isPro) ...[
                          SipCard(
                            type: SipCardType.upsell,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PaywallPage()),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.brandGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Remove ads and unlock smart reminders',
                                        style: AppTypography.body(
                                          color: isDark ? AppColors.darkInk : AppColors.lightInk,
                                        ),
                                      ),
                                      Text(
                                        'Tap to explore Sip Pro',
                                        style: AppTypography.caption(
                                          color: isDark ? AppColors.darkLink : AppColors.lightLink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.lightInkMuted),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // --- Today's Log Section ---
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "TODAY'S LOG",
                            style: AppTypography.sectionLabel(color: AppColors.lightInkMuted),
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (todayDrinks.isEmpty)
                          SipCard(
                            type: SipCardType.empty,
                            child: Center(
                              child: Text(
                                'No drinks logged yet today',
                                style: AppTypography.bodySecondary(
                                  color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
                                ),
                              ),
                            ),
                          )
                        else
                          SipCard(
                            padding: EdgeInsets.zero,
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: todayDrinks.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final entry = todayDrinks[index];
                                return ListTile(
                                  leading: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkTint : AppColors.lightTint,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.water_drop_rounded,
                                      size: 16,
                                      color: AppColors.aquaPrimary,
                                    ),
                                  ),
                                  title: Text(
                                    entry.drinkType.toUpperCase(),
                                    style: AppTypography.body(
                                      color: isDark ? AppColors.darkInk : AppColors.lightInk,
                                    ),
                                  ),
                                  subtitle: Text(
                                    DateFormat('h:mm a').format(entry.timestamp),
                                    style: AppTypography.caption(
                                      color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '+${entry.amount} ${settings.unit}',
                                        style: AppTypography.body(
                                          color: isDark ? AppColors.darkLink : AppColors.lightLink,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        color: AppColors.lightInkMuted,
                                        onPressed: () {
                                          context.read<WaterTrackingBloc>().add(
                                                DeleteDrinkEvent(entry.id),
                                              );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // --- 320x50 AdMob Banner (Free tier only) ---
                AdBannerWidget(isPro: settings.isPro),
              ],
            ),
          ),
        );
      },
    );
  }
}
