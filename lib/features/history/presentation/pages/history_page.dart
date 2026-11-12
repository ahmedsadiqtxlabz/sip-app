import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ad_banner_widget.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_bloc.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_event.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_state.dart';
import '../../../water_tracking/presentation/widgets/log_drink_sheet.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedRange = 'Week';

  String _formatNumber(int val, [String unit = 'ml']) {
    final displayVal = UnitConverter.toDisplayAmount(val, unit);
    return NumberFormat('#,###').format(displayVal);
  }

  void _openLogSheet(BuildContext context, WaterTrackingState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogDrinkSheet(
        isPro: state.settings.isPro,
        unit: state.settings.unit,
        initialAmount: 250,
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
        final allDrinks = state.allDrinks;
        final bool hasData = allDrinks.isNotEmpty;

        final now = DateTime.now();
        final todayMidnight = DateTime(now.year, now.month, now.day);

        // --- Calculate Last 7 Days (Thu, Fri, Sat, Sun, Mon, Tue, Today) ---
        final List<Map<String, dynamic>> last7Days = [];
        int totalWeekIntake = 0;
        int bestDayIntake = 0;
        int daysGoalMet = 0;

        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final dayLabel = i == 0 ? 'Today' : DateFormat('E').format(date);

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
        final currentStreak = state.streak > 0 ? state.streak : settings.currentStreak;
        final bestStreak = math.max(settings.bestStreak, currentStreak);

        // --- Calculate 35 Calendar Heatmap Cells (5 Weeks x 7 Days) ---
        // Aligning calendar so that current week is on Row 5
        // Row 5 ends at the end of the current week (Sunday)
        final int daysUntilSunday = DateTime.sunday - now.weekday;
        final DateTime endOfCurrentWeek = todayMidnight.add(Duration(days: daysUntilSunday));
        final DateTime startOfHeatmap = endOfCurrentWeek.subtract(const Duration(days: 34)); // 35 days total

        final String startMonth = DateFormat('MMMM').format(startOfHeatmap);
        final String endMonth = DateFormat('MMMM').format(now);
        final String monthRangeStr =
            startMonth == endMonth ? startMonth : '$startMonth – $endMonth';

        final List<Map<String, dynamic>> heatmapDays = [];
        for (int i = 0; i < 35; i++) {
          final cellDate = startOfHeatmap.add(Duration(days: i));
          final isFuture = cellDate.isAfter(todayMidnight);
          final cellDateStr = DateFormat('yyyy-MM-dd').format(cellDate);

          int cellTotal = 0;
          if (!isFuture) {
            cellTotal = allDrinks.where((d) {
              return DateFormat('yyyy-MM-dd').format(d.timestamp) == cellDateStr;
            }).fold<int>(0, (sum, d) => sum + d.amount);
          }

          final bool isMet = !isFuture &&
              cellTotal >= settings.dailyGoal &&
              settings.dailyGoal > 0;
          final bool isOverHalf = !isFuture &&
              cellTotal >= (settings.dailyGoal / 2) &&
              cellTotal < settings.dailyGoal &&
              settings.dailyGoal > 0;

          heatmapDays.add({
            'date': cellDate,
            'isFuture': isFuture,
            'amount': cellTotal,
            'isMet': isMet,
            'isOverHalf': isOverHalf,
          });
        }

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
                        // --- Header Row with Range Switcher ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'History',
                              style: TextStyle(
                                fontFamily: '-apple-system',
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.56,
                                color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: hasData
                                    ? (isDark ? const Color(0xFF1F2731) : const Color(0xFFE6EDF3))
                                    : (isDark
                                        ? const Color(0xFF1F2731).withValues(alpha: 0.6)
                                        : const Color(0xFFE6EDF3).withValues(alpha: 0.6)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: ['Week', 'Month', 'Year'].map((range) {
                                  final isSelected = _selectedRange == range;
                                  return GestureDetector(
                                    onTap: hasData
                                        ? () {
                                            setState(() => _selectedRange = range);
                                            if (range != 'Week' && !settings.isPro) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(builder: (_) => const PaywallPage()),
                                              );
                                            }
                                          }
                                        : null,
                                    child: Container(
                                      height: 30,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isDark ? const Color(0xFF27313C) : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(9),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        range,
                                        style: TextStyle(
                                          fontFamily: '-apple-system',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? (isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116))
                                              : (isDark ? const Color(0xFF9AA4B2) : const Color(0xFF4F5B69)),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // --- Last 7 Days Chart Card ---
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Chart Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'Last 7 days',
                                    style: TextStyle(
                                      fontFamily: '-apple-system',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      CustomPaint(
                                        size: const Size(14, 2),
                                        painter: _DashedLinePainter(color: const Color(0xFFFF7A59)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Goal ${_formatNumber(settings.dailyGoal, settings.unit)} ${settings.unit}',
                                        style: TextStyle(
                                          fontFamily: '-apple-system',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Bar Chart Canvas (Height 118px)
                              SizedBox(
                                height: 118,
                                child: Stack(
                                  children: [
                                    // Dashed Target Line at bottom 23px
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 23,
                                      child: CustomPaint(
                                        size: const Size(double.infinity, 2),
                                        painter: _DashedLinePainter(
                                          color: const Color(0xFFFF7A59).withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),

                                    // 7 Columns
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: last7Days.map((day) {
                                        final int amount = day['amount'] as int;
                                        final bool isToday = day['isToday'] as bool;
                                        final double maxVal = settings.dailyGoal > 0
                                            ? settings.dailyGoal * 1.25
                                            : 2500;
                                        final double fillHeight = hasData && amount > 0
                                            ? (amount / maxVal * 86).clamp(10.0, 88.0)
                                            : 6.0;

                                        Color barColor;
                                        if (!hasData || amount == 0) {
                                          barColor = isToday
                                              ? const Color(0xFFB9E2FF)
                                              : (isDark ? const Color(0xFF1F2731) : const Color(0xFFE6EDF3));
                                        } else if (amount >= settings.dailyGoal) {
                                          barColor = const Color(0xFF1FA2FF);
                                        } else {
                                          barColor = const Color(0xFF60C3FF);
                                        }

                                        return Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                height: fillHeight,
                                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                                decoration: BoxDecoration(
                                                  color: barColor,
                                                  borderRadius: const BorderRadius.vertical(
                                                    top: Radius.circular(8),
                                                    bottom: Radius.circular(4),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                day['label'] as String,
                                                style: TextStyle(
                                                  fontFamily: '-apple-system',
                                                  fontSize: 11,
                                                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                                  color: isToday
                                                      ? (isDark ? const Color(0xFF7CC8FF) : const Color(0xFF0A6FB8))
                                                      : (isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // --- EMPTY STATE: Nothing to chart yet (If no logs) ---
                        if (!hasData) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 84x84 rounded icon container
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF11324A) : const Color(0xFFE6F4FF),
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    child: Center(
                                      child: CustomPaint(
                                        size: const Size(40, 40),
                                        painter: _NothingToChartIconPainter(
                                          color: isDark ? const Color(0xFF7CC8FF) : const Color(0xFF0A6FB8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nothing to chart yet',
                                    style: TextStyle(
                                      fontFamily: '-apple-system',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.44,
                                      color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 280),
                                    child: Text(
                                      'Log your first drink and your week will start filling in here. Stats and streaks appear after your first full day.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: '-apple-system',
                                        fontSize: 15,
                                        height: 1.45,
                                        color: isDark ? const Color(0xFFB9C3CF) : const Color(0xFF4F5B69),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  GestureDetector(
                                    onTap: () => _openLogSheet(context, state),
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 22),
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
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_rounded, size: 18, color: Color(0xFF06283A)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Log a drink',
                                            style: TextStyle(
                                              fontFamily: '-apple-system',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF06283A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // --- POPULATED STATE: 3 Stat Cards Row ---
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  isDark: isDark,
                                  value: _formatNumber(dailyAvg, settings.unit),
                                  unit: ' ${settings.unit}',
                                  label: 'Average',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  isDark: isDark,
                                  value: _formatNumber(bestDayIntake, settings.unit),
                                  unit: ' ${settings.unit}',
                                  label: 'Best day',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  isDark: isDark,
                                  value: '$goalHitPercent%',
                                  unit: '',
                                  label: 'Goal hit rate',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // --- 2 Streak Cards Row ---
                          Row(
                            children: [
                              Expanded(
                                child: _buildStreakCard(
                                  isDark: isDark,
                                  icon: CustomPaint(
                                    size: const Size(22, 22),
                                    painter: _FlameIconPainter(color: const Color(0xFFFF7A59)),
                                  ),
                                  count: '$currentStreak ${currentStreak == 1 ? "day" : "days"}',
                                  label: 'Current streak',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStreakCard(
                                  isDark: isDark,
                                  icon: CustomPaint(
                                    size: const Size(22, 22),
                                    painter: _TrophyIconPainter(color: const Color(0xFFC2451F)),
                                  ),
                                  count: '$bestStreak ${bestStreak == 1 ? "day" : "days"}',
                                  label: 'Longest streak',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // --- DAYS YOU HIT YOUR GOAL Heatmap Card ---
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Days you hit your goal',
                                      style: TextStyle(
                                        fontFamily: '-apple-system',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                      ),
                                    ),
                                    Text(
                                      monthRangeStr,
                                      style: TextStyle(
                                        fontFamily: '-apple-system',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // 5 Weeks x 7 Days Grid (35 cells)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    mainAxisSpacing: 5,
                                    crossAxisSpacing: 5,
                                    mainAxisExtent: 14, // Exact height: 14px per spec
                                  ),
                                  itemCount: 35,
                                  itemBuilder: (context, index) {
                                    final item = heatmapDays[index];
                                    final bool isFuture = item['isFuture'] as bool;
                                    final bool isMet = item['isMet'] as bool;
                                    final bool isOverHalf = item['isOverHalf'] as bool;

                                    Color cellBg;
                                    Color cellBorder;

                                    if (isFuture) {
                                      cellBg = Colors.transparent;
                                      cellBorder = isDark
                                          ? const Color(0xFF27313C)
                                          : const Color(0xFFE1E8EF);
                                    } else if (isMet) {
                                      cellBg = const Color(0xFF1FA2FF);
                                      cellBorder = Colors.transparent;
                                    } else if (isOverHalf) {
                                      cellBg = isDark
                                          ? const Color(0xFF0F496B)
                                          : const Color(0xFFB9E2FF);
                                      cellBorder = Colors.transparent;
                                    } else {
                                      // Missed or 0 logs
                                      cellBg = isDark
                                          ? const Color(0xFF1A222C)
                                          : const Color(0xFFE6EDF3);
                                      cellBorder = Colors.transparent;
                                    }

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: cellBg,
                                        borderRadius: BorderRadius.circular(4),
                                        border: cellBorder != Colors.transparent
                                            ? Border.all(color: cellBorder, width: 1)
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Heatmap Legend
                                Row(
                                  children: [
                                    _buildLegendItem('Goal met', const Color(0xFF1FA2FF), isDark),
                                    const SizedBox(width: 14),
                                    _buildLegendItem(
                                      'Over half',
                                      isDark ? const Color(0xFF0F496B) : const Color(0xFFB9E2FF),
                                      isDark,
                                    ),
                                    const SizedBox(width: 14),
                                    _buildLegendItem(
                                      'Missed',
                                      isDark ? const Color(0xFF1A222C) : const Color(0xFFE6EDF3),
                                      isDark,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // --- INSIGHTS CARD (Blurred Upsell if !isPro) ---
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                // Blurred Content Card
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF161C24) : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Insights',
                                          style: TextStyle(
                                            fontFamily: '-apple-system',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'You drink 40% less on weekends. A morning reminder on Saturday could help.',
                                          style: TextStyle(
                                            fontFamily: '-apple-system',
                                            fontSize: 14,
                                            height: 1.4,
                                            color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Your best logging window is 9–11 AM. Afternoons are where goals slip.',
                                          style: TextStyle(
                                            fontFamily: '-apple-system',
                                            fontSize: 14,
                                            height: 1.4,
                                            color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Unlock Insights with Pro Overlay
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const PaywallPage()),
                                      );
                                    },
                                    child: Container(
                                      color: isDark
                                          ? const Color(0x800E1116)
                                          : const Color(0x8CF7FAFC),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            height: 40,
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x4D1FA2FF),
                                                  blurRadius: 16,
                                                  offset: Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.lock_rounded,
                                                  size: 14,
                                                  color: Color(0xFF06283A),
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Unlock insights with Pro',
                                                  style: TextStyle(
                                                    fontFamily: '-apple-system',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF06283A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Weekly patterns, best times, trends',
                                            style: TextStyle(
                                              fontFamily: '-apple-system',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? const Color(0xFFB9C3CF) : const Color(0xFF4F5B69),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),

                // AdMob Banner Slot (only shown on free tier)
                AdBannerWidget(isPro: settings.isPro),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required String value,
    required String unit,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: '-apple-system',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
              ),
              children: [
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontFamily: '-apple-system',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard({
    required bool isDark,
    required Widget icon,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          icon,
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontFamily: '-apple-system',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.34,
                  color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: '-apple-system',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: '-apple-system',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Dashed Goal Line
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4;
    const double dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(math.min(startX + dashWidth, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

// Custom Painter for Nothing To Chart Icon
class _NothingToChartIconPainter extends CustomPainter {
  final Color color;

  _NothingToChartIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;

    // Top subtle bar
    canvas.drawLine(Offset(w * 0.15, h * 0.2), Offset(w * 0.85, h * 0.2), paint..color = color.withValues(alpha: 0.4));

    // Three vertical bars
    paint.color = color;
    canvas.drawLine(Offset(w * 0.25, h * 0.85), Offset(w * 0.25, h * 0.55), paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.85), Offset(w * 0.5, h * 0.35), paint);
    canvas.drawLine(Offset(w * 0.75, h * 0.85), Offset(w * 0.75, h * 0.45), paint);
  }

  @override
  bool shouldRepaint(covariant _NothingToChartIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

// Custom Painter for Flame Icon
class _FlameIconPainter extends CustomPainter {
  final Color color;

  _FlameIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // SVG path d="M12 2c1 4 5 5.5 5 11a5 5 0 0 1-10 0c0-2 1-3.5 2-4.5 0 2 1 3 2 3 1.5 0 2-1.5 1-3.5 2 1.5 3 3 3 5a2.5 2.5 0 0 1-5 0c0-1 .5-2 1-2.5C8 8 10 5 12 2z"
    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    path.moveTo(12, 2);
    path.cubicTo(13, 6, 17, 7.5, 17, 13);
    path.cubicTo(17, 16.5, 14, 18, 12, 18);
    path.cubicTo(9.2, 18, 7, 15.8, 7, 13);
    path.cubicTo(7, 11, 8, 9.5, 9, 8.5);
    path.cubicTo(9, 10.5, 10, 11.5, 11, 11.5);
    path.cubicTo(12.5, 11.5, 13, 10, 12, 8);
    path.cubicTo(14, 9.5, 15, 11, 15, 13);
    path.cubicTo(15, 14.5, 13.5, 15.5, 12.5, 15.5);
    path.cubicTo(11.5, 15.5, 10, 14.5, 10, 13);
    path.cubicTo(10, 12, 10.5, 11, 11, 10.5);
    path.cubicTo(8, 8, 10, 5, 12, 2);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlameIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

// Custom Painter for Trophy Icon
class _TrophyIconPainter extends CustomPainter {
  final Color color;

  _TrophyIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // SVG path: M8 21h8M12 17v4M5 4h14v4a7 7 0 0 1-14 0zM5 6H3v2a3 3 0 0 0 3 3M19 6h2v2a3 3 0 0 1-3 3
    canvas.drawLine(const Offset(8, 21), const Offset(16, 21), paint);
    canvas.drawLine(const Offset(12, 17), const Offset(12, 21), paint);

    final cupPath = Path();
    cupPath.moveTo(5, 4);
    cupPath.lineTo(19, 4);
    cupPath.lineTo(19, 8);
    cupPath.arcToPoint(const Offset(5, 8), radius: const Radius.circular(7), clockwise: true);
    cupPath.close();
    canvas.drawPath(cupPath, paint);

    // Left handle
    final leftHandle = Path();
    leftHandle.moveTo(5, 6);
    leftHandle.lineTo(3, 6);
    leftHandle.arcToPoint(const Offset(6, 11), radius: const Radius.circular(3), clockwise: false);
    canvas.drawPath(leftHandle, paint);

    // Right handle
    final rightHandle = Path();
    rightHandle.moveTo(19, 6);
    rightHandle.lineTo(21, 6);
    rightHandle.arcToPoint(const Offset(18, 11), radius: const Radius.circular(3), clockwise: true);
    canvas.drawPath(rightHandle, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrophyIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
