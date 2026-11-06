import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/ad_banner_widget.dart';
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
  final bool _showUpsellCard = true;
  bool _dismissGoalCelebration = false;

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
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final hasAlreadyCelebratedToday = settings.lastCelebratedGoalDate == todayStr;
        final currentStreak = state.streak > 0 ? state.streak : settings.currentStreak;

        // --- FULL GOAL REACHED CELEBRATION VIEW (Matches HTML Spec & Screenshot 4) ---
        // Only shown when goal is reached AND user has not already celebrated/dismissed today
        if (isGoalReached && !hasAlreadyCelebratedToday && !_dismissGoalCelebration) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            body: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Animated Falling Confetti
                  const Positioned.fill(
                    child: IgnorePointer(child: _ConfettiOverlay()),
                  ),

                  // Celebration Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Header
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
                            // Celebration Coral Streak Badge
                            if (currentStreak > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7A59),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🔥', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$currentStreak ${currentStreak == 1 ? "day" : "days"}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2B1208),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const Spacer(flex: 1),

                        // Goal Reached Ring with checkmark
                        WaterFillRing(
                          progress: 1.0,
                          currentAmount: state.todayTotal,
                          goalAmount: settings.dailyGoal,
                          unit: settings.unit,
                          size: 240,
                          isGoalReached: true,
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          'Goal reached',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            height: 1.1,
                            color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Streak pill
                        if (currentStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C1914) : const Color(0xFFFFF1EC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 15)),
                                const SizedBox(width: 6),
                                Text(
                                  'Streak: $currentStreak ${currentStreak == 1 ? "day" : "days"}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFFFF8B6B) : const Color(0xFFC2451F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          currentStreak > 0
                              ? "That's $currentStreak ${currentStreak == 1 ? "day" : "days"} in a row. See you tomorrow morning."
                              : "You reached your daily goal! See you tomorrow morning.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: isDark ? const Color(0xFFB9C3CF) : const Color(0xFF4F5B69),
                          ),
                        ),
                        const Spacer(flex: 2),

                        // Action Buttons: Share & Done
                        Row(
                          children: [
                            // Share button
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Share.share(
                                    'I hit my daily water goal of ${settings.dailyGoal} ${settings.unit} on Sip! 🔥 $currentStreak days streak.',
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1C242F) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF27313C) : const Color(0xFFE1ECF4),
                                    ),
                                    boxShadow: isDark
                                        ? null
                                        : const [
                                            BoxShadow(
                                              color: Color(0x0F0E1116),
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.share_rounded,
                                        size: 18,
                                        color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Share',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Done button
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() => _dismissGoalCelebration = true);
                                  context.read<WaterTrackingBloc>().add(
                                        const DismissGoalCelebrationEvent(),
                                      );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x401FA2FF),
                                        blurRadius: 20,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Done',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF06283A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // --- STANDARD HOME VIEW (Supports Empty, Partial, and Dismissed Goal states) ---
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
                            // Streak Flame Badge (ONLY shown when streak > 0)
                            if (currentStreak > 0)
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
                                      '$currentStreak ${currentStreak == 1 ? "day" : "days"}',
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
                        const SizedBox(height: 20),

                        // --- Empty State Note (If 0 ml logged today) ---
                        if (state.todayTotal == 0) ...[
                          Column(
                            children: [
                              Text(
                                'First sip of the day?',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                  color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentStreak > 0
                                    ? 'Log a drink below to keep your $currentStreak-day streak going.'
                                    : 'Log a drink below to start your streak.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: isDark ? const Color(0xFFB9C3CF) : const Color(0xFF4F5B69),
                                ),
                              ),
                            ],
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
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PaywallPage()),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
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
                                    // 40x40 gradient icon with exact 4-pointed sparkle star
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
                                      child: const Center(
                                        child: CustomPaint(
                                          size: Size(20, 20),
                                          painter: _SparkleStarPainter(color: Color(0xFF06283A)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Remove ads and unlock insights',
                                            style: TextStyle(
                                              fontFamily: '-apple-system',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.2,
                                              color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            'Try Sip Pro free for 7 days',
                                            style: TextStyle(
                                              fontFamily: '-apple-system',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? const Color(0xFFB9C3CF) : const Color(0xFF4F5B69),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Action X button: tapping opens Paywall as expected
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const PaywallPage()),
                                        );
                                      },
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
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // --- TODAY'S LOG SECTION ---
                        if (todayDrinks.isEmpty) ...[
                          // Empty state: exact dashed card matching design spec
                          CustomPaint(
                            painter: _DashedBorderPainter(
                              color: isDark ? const Color(0xFF2E3846) : const Color(0xFFCBD8E2),
                              radius: 20,
                              strokeWidth: 1.5,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.water_drop_outlined,
                                    size: 28,
                                    color: isDark ? const Color(0xFF6B7684) : const Color(0xFF9AA4B2),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your drinks will show up here',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // Header
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

                          // Populated drinks card
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
                            child: Column(
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
                        ],
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

// --- Dashed Border Painter for Empty State ---
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double dashLength = 6.0;
    const double gapLength = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}

// --- Confetti Particles Data & Overlay ---
class _ConfettiFlake {
  final double leftFraction;
  final Color color;
  final double width;
  final double height;
  final double delay;

  const _ConfettiFlake({
    required this.leftFraction,
    required this.color,
    this.width = 8,
    this.height = 14,
    required this.delay,
  });
}

const List<_ConfettiFlake> _confettiFlakes = [
  _ConfettiFlake(leftFraction: 0.06, color: Color(0xFFFF7A59), delay: 0.0),
  _ConfettiFlake(leftFraction: 0.14, color: Color(0xFF1FA2FF), height: 10, delay: 0.4),
  _ConfettiFlake(leftFraction: 0.22, color: Color(0xFF12D8C8), delay: 1.1),
  _ConfettiFlake(leftFraction: 0.31, color: Color(0xFFFFC857), width: 6, delay: 0.7),
  _ConfettiFlake(leftFraction: 0.39, color: Color(0xFFFF7A59), delay: 1.6),
  _ConfettiFlake(leftFraction: 0.47, color: Color(0xFF1FA2FF), height: 9, delay: 0.2),
  _ConfettiFlake(leftFraction: 0.55, color: Color(0xFFFFC857), delay: 1.3),
  _ConfettiFlake(leftFraction: 0.63, color: Color(0xFF12D8C8), width: 6, delay: 0.9),
  _ConfettiFlake(leftFraction: 0.71, color: Color(0xFFFF7A59), delay: 2.0),
  _ConfettiFlake(leftFraction: 0.79, color: Color(0xFF1FA2FF), delay: 0.5),
  _ConfettiFlake(leftFraction: 0.87, color: Color(0xFFFFC857), height: 10, delay: 1.8),
  _ConfettiFlake(leftFraction: 0.94, color: Color(0xFF12D8C8), delay: 1.0),
  _ConfettiFlake(leftFraction: 0.27, color: Color(0xFF1FA2FF), width: 5, delay: 2.4),
  _ConfettiFlake(leftFraction: 0.58, color: Color(0xFFFF7A59), height: 9, delay: 2.7),
  _ConfettiFlake(leftFraction: 0.83, color: Color(0xFF12D8C8), width: 6, delay: 2.2),
];

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay();

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const totalDuration = 3.2;
    const totalFallDistance = 580.0;

    for (final flake in _confettiFlakes) {
      final flakeTime = ((progress * totalDuration) - flake.delay) % totalDuration;
      final t = flakeTime / totalDuration;
      if (t < 0) continue;

      final y = -40.0 + t * totalFallDistance;
      final x = size.width * flake.leftFraction;

      double opacity = 1.0;
      if (t < 0.1) {
        opacity = t / 0.1;
      } else if (t > 0.85) {
        opacity = (1.0 - t) / 0.15;
      }

      final angle = t * 3.0 * math.pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      final paint = Paint()
        ..color = flake.color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: flake.width,
            height: flake.height,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 4-pointed Sparkle Star CustomPainter matching HTML spec:
/// path d="M12 3l1.8 4.6L18 9l-4.2 1.4L12 15l-1.8-4.6L6 9l4.2-1.4z"
class _SparkleStarPainter extends CustomPainter {
  final Color color;
  const _SparkleStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final path = Path()
      ..moveTo(12 * scale, 3 * scale)
      ..lineTo(13.8 * scale, 7.6 * scale)
      ..lineTo(18 * scale, 9 * scale)
      ..lineTo(13.8 * scale, 10.4 * scale)
      ..lineTo(12 * scale, 15 * scale)
      ..lineTo(10.2 * scale, 10.4 * scale)
      ..lineTo(6 * scale, 9 * scale)
      ..lineTo(10.2 * scale, 7.6 * scale)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkleStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
