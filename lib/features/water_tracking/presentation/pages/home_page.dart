import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/ad_banner_widget.dart';
import '../../../../core/widgets/sip_card.dart';
import '../../../../core/widgets/water_fill_ring.dart';
import '../bloc/water_tracking_bloc.dart';
import '../bloc/water_tracking_event.dart';
import '../bloc/water_tracking_state.dart';
import '../widgets/log_drink_sheet.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showUpsellCard = true;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _openLogSheet(BuildContext context, WaterTrackingState state, {int initialAmount = 250}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogDrinkSheet(
        isPro: state.settings.isPro,
        unit: state.settings.unit,
        initialAmount: initialAmount,
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

                        // --- 5 Quick-Add Presets Row (150, 250, 350, 500, +) ---
                        // Exactly matches HTML: display:grid; grid-template-columns:repeat(5, minmax(0, 1fr)); gap:8px
                        Row(
                          children: [
                            for (final cup in [150, 250, 350, 500]) ...[
                              Expanded(
                                child: InkWell(
                                  onTap: () => _openLogSheet(context, state, initialAmount: cup),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1C242F) : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: isDark ? Border.all(color: const Color(0xFF27313C)) : null,
                                      boxShadow: isDark
                                          ? null
                                          : const [
                                              BoxShadow(
                                                color: Color(0x0D0E1116),
                                                blurRadius: 2,
                                                offset: Offset(0, 1),
                                              ),
                                              BoxShadow(
                                                color: Color(0x0D0E1116),
                                                blurRadius: 12,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$cup',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Custom Add (+) Button: exact same size and shape as the pills
                            Expanded(
                              child: InkWell(
                                onTap: () => _openLogSheet(context, state, initialAmount: 250),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: state.activeTheme.gradient,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: isDark
                                        ? null
                                        : const [
                                            BoxShadow(
                                              color: Color(0x0D0E1116),
                                              blurRadius: 2,
                                              offset: Offset(0, 1),
                                            ),
                                            BoxShadow(
                                              color: Color(0x0D0E1116),
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Color(0xFF06283A),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- Next Reminder Card ---
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161C24) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1F2731) : const Color(0x0F0E1116),
                            ),
                            boxShadow: isDark
                                ? null
                                : const [
                                    BoxShadow(
                                      color: Color(0x0A0E1116),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                    BoxShadow(
                                      color: Color(0x0A0E1116),
                                      blurRadius: 18,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF11324A) : const Color(0xFFE6F4FF),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  size: 18,
                                  color: isDark ? const Color(0xFF7CC8FF) : const Color(0xFF0A6FB8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Next reminder at 3:00 PM',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Every 2 hours until 11:00 PM',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Reminders snoozed for 1 hour'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF27313C) : const Color(0xFFEEF3F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Snooze',
                                      style: TextStyle(
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
                        const SizedBox(height: 16),

                        // --- Remove Ads & Unlock Insights Upsell Card (If !isPro) ---
                        if (!settings.isPro && _showUpsellCard) ...[
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? const [Color(0xFF11324A), Color(0xFF0F3A38)]
                                    : const [Color(0xFFE6F4FF), Color(0xFFE3FBF8)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E4B63) : const Color(0xFFCFE9FA),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                // 40x40 gradient icon with sparkle star
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Color(0xFF06283A),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const PaywallPage()),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Remove ads and unlock insights',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          'Try Sip Pro free for 7 days',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? const Color(0xFFB9C3CF) : const Color(0xFF4F5B69),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Dismiss X button
                                InkWell(
                                  onTap: () => setState(() => _showUpsellCard = false),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0x14FFFFFF) // rgba(255, 255, 255, 0.08)
                                          : const Color(0x0F0E1116), // rgba(14, 17, 22, 0.06)
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: isDark ? const Color(0xFFB9C3CF) : const Color(0xFF4F5B69),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // --- Today's Log Section ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "Today's log",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                              ),
                            ),
                            Text(
                              '${todayDrinks.length} drinks · swipe to delete',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Today's log card
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161C24) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1F2731) : const Color(0xFFEEF3F7),
                            ),
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
                          clipBehavior: Clip.antiAlias,
                          child: todayDrinks.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No drinks logged yet today',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (int i = 0; i < todayDrinks.length; i++) ...[
                                      Dismissible(
                                        key: Key(todayDrinks[i].id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 20),
                                          color: const Color(0xFFFF5252),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        onDismissed: (_) {
                                          context.read<WaterTrackingBloc>().add(
                                                DeleteDrinkEvent(todayDrinks[i].id),
                                              );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: i < todayDrinks.length - 1
                                                ? Border(
                                                    bottom: BorderSide(
                                                      color: isDark
                                                          ? const Color(0xFF1F2731)
                                                          : const Color(0xFFEEF3F7),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              // 32x32 rounded square with 10px radius (NOT circle)
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF11324A)
                                                      : const Color(0xFFE6F4FF),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.water_drop_rounded,
                                                  size: 16,
                                                  color: isDark
                                                      ? const Color(0xFF7CC8FF)
                                                      : const Color(0xFF0A6FB8),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  todayDrinks[i].drinkType.substring(0, 1).toUpperCase() +
                                                      todayDrinks[i].drinkType.substring(1),
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? const Color(0xFFF3F6F9)
                                                        : const Color(0xFF0E1116),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${todayDrinks[i].amount} ${settings.unit}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? const Color(0xFFF3F6F9)
                                                      : const Color(0xFF0E1116),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 62,
                                                child: Text(
                                                  DateFormat('h:mm a').format(todayDrinks[i].timestamp),
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark
                                                        ? const Color(0xFF9AA4B2)
                                                        : const Color(0xFF6B7684),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
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
