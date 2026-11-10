import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/pro_themes.dart';
import '../../../../core/services/purchase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ad_banner_widget.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_bloc.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_event.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_state.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _formatNumber(int val) {
    return NumberFormat('#,###').format(val);
  }

  void _showGoalDialog(BuildContext context, int currentGoal, String unit) {
    int tempGoal = currentGoal;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Edit Daily Goal',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 32),
                onPressed: () {
                  if (tempGoal > 500) setState(() => tempGoal -= 100);
                },
              ),
              const SizedBox(width: 16),
              Text(
                '$tempGoal $unit',
                style: const TextStyle(
                  fontFamily: '-apple-system',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 32),
                onPressed: () => setState(() => tempGoal += 100),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<WaterTrackingBloc>().add(UpdateDailyGoalEvent(tempGoal));
                Navigator.of(dialogCtx).pop();
              },
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCupPresetsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cup Presets',
          style: TextStyle(
            fontFamily: '-apple-system',
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Your quick-log presets are 150 ml, 250 ml, 350 ml, and 500 ml. You can quickly select any amount from the Log Drink sheet.',
          style: TextStyle(fontFamily: '-apple-system', fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset All Data?',
          style: TextStyle(
            fontFamily: '-apple-system',
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'This will permanently delete all your drink logs, streaks, and reset your hydration progress. This action cannot be undone.',
          style: TextStyle(fontFamily: '-apple-system', fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<WaterTrackingBloc>().add(const ResetDataEvent());
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data reset successfully.')),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Color(0xFFC2451F), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<WaterTrackingBloc, WaterTrackingState>(
      builder: (context, state) {
        final settings = state.settings;
        final isPro = settings.isPro;

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
                        // --- Title ---
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.56,
                            color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- Upgrade Card (Free) or Sip Pro Active Card (Pro) ---
                        if (!isPro)
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PaywallPage()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x401FA2FF),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: CustomPaint(
                                        size: const Size(20, 20),
                                        painter: _SparkleIconPainter(color: const Color(0xFF06283A)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Upgrade to Pro',
                                          style: TextStyle(
                                            fontFamily: '-apple-system',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF06283A),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          'No ads, insights, themes, widgets · 7 days free',
                                          style: TextStyle(
                                            fontFamily: '-apple-system',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF06283A).withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: Color(0xFF06283A),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF102636), const Color(0xFF0D2622)]
                                    : [const Color(0xFFF2FAFF), const Color(0xFFEEFCFA)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1C445E) : const Color(0xFFCFE9FA),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: CustomPaint(
                                      size: const Size(20, 20),
                                      painter: _CheckmarkIconPainter(color: const Color(0xFF06283A)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sip Pro — Active',
                                        style: TextStyle(
                                          fontFamily: '-apple-system',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Yearly · renews 4 Nov 2027 · \$19.99/yr',
                                        style: TextStyle(
                                          fontFamily: '-apple-system',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF4F5B69),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Subscription active via App Store.')),
                                    );
                                  },
                                  child: Text(
                                    'Manage',
                                    style: TextStyle(
                                      fontFamily: '-apple-system',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF7CC8FF) : const Color(0xFF0A6FB8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),

                        // --- GOAL & UNITS Section ---
                        _buildSectionLabel('GOAL & UNITS', isDark),
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
                                title: 'Daily goal',
                                isDark: isDark,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_formatNumber(settings.dailyGoal)} ${settings.unit}',
                                      style: TextStyle(
                                        fontFamily: '-apple-system',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildChevron(isDark),
                                  ],
                                ),
                                onTap: () => _showGoalDialog(context, settings.dailyGoal, settings.unit),
                              ),
                              _buildDivider(isDark),
                              // Units Row with Segmented Control
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Units',
                                      style: TextStyle(
                                        fontFamily: '-apple-system',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1F2731) : const Color(0xFFEEF3F7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          _buildUnitButton('ml', settings.unit == 'ml', isDark, () {
                                            context.read<WaterTrackingBloc>().add(const UpdateUnitEvent('ml'));
                                          }),
                                          _buildUnitButton('fl oz', settings.unit == 'fl oz', isDark, () {
                                            context.read<WaterTrackingBloc>().add(const UpdateUnitEvent('fl oz'));
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildDivider(isDark),
                              _buildRow(
                                title: 'Cup presets',
                                isDark: isDark,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '150 · 250 · 350 · 500',
                                      style: TextStyle(
                                        fontFamily: '-apple-system',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildChevron(isDark),
                                  ],
                                ),
                                onTap: () => _showCupPresetsDialog(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- PERSONALIZE Section ---
                        _buildSectionLabel('PERSONALIZE', isDark),
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
                              // Themes Row + Swatches
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Themes',
                                          style: TextStyle(
                                            fontFamily: '-apple-system',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                          ),
                                        ),
                                        if (!isPro) ...[
                                          const SizedBox(width: 8),
                                          _buildProBadge(),
                                          const Spacer(),
                                          _buildLockCircle(isDark),
                                        ] else ...[
                                          const Spacer(),
                                          Text(
                                            state.activeTheme.name,
                                            style: TextStyle(
                                              fontFamily: '-apple-system',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // 6 Swatches
                                    Row(
                                      children: ProThemes.allThemes.map((theme) {
                                        final bool isSelected = state.activeTheme.name == theme.name;
                                        final bool isLocked = !isPro && theme.name != 'Aqua';

                                        return Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              if (isLocked) {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(builder: (_) => const PaywallPage()),
                                                );
                                              } else {
                                                context.read<WaterTrackingBloc>().add(ChangeThemeEvent(theme.name));
                                              }
                                            },
                                            child: Opacity(
                                              opacity: isLocked ? 0.55 : 1.0,
                                              child: Container(
                                                height: 28,
                                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                                decoration: BoxDecoration(
                                                  gradient: theme.gradient,
                                                  borderRadius: BorderRadius.circular(9),
                                                  border: isSelected
                                                      ? Border.all(color: Colors.white, width: 2)
                                                      : null,
                                                  boxShadow: isSelected
                                                      ? [
                                                          BoxShadow(
                                                            color: isDark ? Colors.white : theme.primary,
                                                            spreadRadius: 2,
                                                            blurRadius: 1,
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              _buildDivider(isDark),

                              // Widgets Row
                              if (!isPro)
                                _buildRow(
                                  title: 'Widgets',
                                  badge: _buildProBadge(),
                                  isDark: isDark,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Home & Lock Screen',
                                        style: TextStyle(
                                          fontFamily: '-apple-system',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildLockCircle(isDark),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const PaywallPage()),
                                    );
                                  },
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Widgets',
                                            style: TextStyle(
                                              fontFamily: '-apple-system',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                'Added',
                                                style: TextStyle(
                                                  fontFamily: '-apple-system',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              _buildChevron(isDark),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      // Pro Widget Previews Row
                                      Row(
                                        children: [
                                          // Small preview
                                          Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1F2731) : const Color(0xFFF7FAFC),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isDark ? const Color(0xFF27313C) : const Color(0xFFE6EDF3),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '50%',
                                              style: TextStyle(
                                                fontFamily: '-apple-system',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Medium preview
                                          Expanded(
                                            child: Container(
                                              height: 72,
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1F2731) : const Color(0xFFF7FAFC),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isDark ? const Color(0xFF27313C) : const Color(0xFFE6EDF3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '50%',
                                                    style: TextStyle(
                                                      fontFamily: '-apple-system',
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w800,
                                                      color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '1,250 ml',
                                                        style: TextStyle(
                                                          fontFamily: '-apple-system',
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w800,
                                                          color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                                                        ),
                                                      ),
                                                      Text(
                                                        '12-day streak',
                                                        style: TextStyle(
                                                          fontFamily: '-apple-system',
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF4F5B69),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Lock screen preview
                                          Container(
                                            width: 52,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0E1116),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.water_drop_outlined,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              _buildDivider(isDark),

                              // Apple Health Sync Row
                              _buildRow(
                                title: 'Apple Health sync',
                                badge: isPro ? null : _buildProBadge(),
                                isDark: isDark,
                                trailing: isPro
                                    ? _buildIosSwitch(
                                        value: settings.appleHealthSync,
                                        onChanged: (_) {},
                                        isDark: isDark,
                                      )
                                    : GestureDetector(
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
                                onTap: isPro
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const PaywallPage()),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- DATA Section ---
                        _buildSectionLabel('DATA', isDark),
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
                                title: 'Export CSV',
                                badge: isPro ? null : _buildProBadge(),
                                isDark: isDark,
                                trailing: isPro
                                    ? CustomPaint(
                                        size: const Size(16, 16),
                                        painter: _ExportIconPainter(color: const Color(0xFF0A6FB8)),
                                      )
                                    : _buildLockCircle(isDark),
                                onTap: () {
                                  if (!isPro) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const PaywallPage()),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Exporting CSV data...')),
                                    );
                                  }
                                },
                              ),
                              _buildDivider(isDark),
                              _buildRow(
                                title: 'Reset all data',
                                titleColor: const Color(0xFFC2451F),
                                isDark: isDark,
                                onTap: () => _showResetConfirmDialog(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- ABOUT Section ---
                        _buildSectionLabel('ABOUT', isDark),
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
                                title: 'Privacy policy',
                                isDark: isDark,
                                trailing: _buildChevron(isDark),
                                onTap: () => launchUrl(
                                  Uri.parse(AppConstants.privacyPolicyUrl),
                                  mode: LaunchMode.externalApplication,
                                ),
                              ),
                              _buildDivider(isDark),
                              _buildRow(
                                title: 'Terms of use',
                                isDark: isDark,
                                trailing: _buildChevron(isDark),
                                onTap: () => launchUrl(
                                  Uri.parse(AppConstants.termsOfUseUrl),
                                  mode: LaunchMode.externalApplication,
                                ),
                              ),
                              _buildDivider(isDark),
                              _buildRow(
                                title: 'Restore purchases',
                                isDark: isDark,
                                trailing: _buildChevron(isDark),
                                onTap: () async {
                                  final restored = await PurchaseService.restorePurchases();
                                  if (context.mounted) {
                                    if (restored) {
                                      context.read<WaterTrackingBloc>().add(const SetProStatusEvent(true));
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          restored
                                              ? 'Purchases restored successfully!'
                                              : 'No active purchases found.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              _buildDivider(isDark),
                              _buildRow(
                                title: 'Rate Sip',
                                isDark: isDark,
                                trailing: _buildChevron(isDark),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Opening App Store review...')),
                                  );
                                },
                              ),
                              _buildDivider(isDark),
                              _buildRow(
                                title: 'Contact support',
                                isDark: isDark,
                                trailing: _buildChevron(isDark),
                                onTap: () => launchUrl(Uri.parse('mailto:support@txlabz.com')),
                              ),
                              _buildDivider(isDark),
                              _buildRow(
                                title: 'Version ${AppConstants.appVersion}',
                                titleColor: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // AdMob Banner Slot (only shown on free tier)
                AdBannerWidget(isPro: isPro),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
    Color? titleColor,
    Widget? badge,
    Widget? trailing,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: '-apple-system',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: titleColor ?? (isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116)),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              badge,
            ],
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 1,
      color: isDark ? const Color(0xFF1F2731) : const Color(0xFFEEF3F7),
    );
  }

  Widget _buildChevron(bool isDark) {
    return const Icon(
      Icons.chevron_right_rounded,
      size: 16,
      color: Color(0xFF9AA4B2),
    );
  }

  Widget _buildProBadge() {
    return Container(
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
    );
  }

  Widget _buildLockCircle(bool isDark) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2731) : const Color(0xFFEEF3F7),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          size: 12,
          color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
        ),
      ),
    );
  }

  Widget _buildUnitButton(String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF27313C) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
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
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
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
      ),
    );
  }
}

// 4-Pointed Sparkle Star Painter
class _SparkleIconPainter extends CustomPainter {
  final Color color;

  _SparkleIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // SVG path d="M12 3l1.8 4.6L18 9l-4.2 1.4L12 15l-1.8-4.6L6 9l4.2-1.4z"
    final path = Path();
    path.moveTo(12, 3);
    path.lineTo(13.8, 7.6);
    path.lineTo(18, 9);
    path.lineTo(13.8, 10.4);
    path.lineTo(12, 15);
    path.lineTo(10.2, 10.4);
    path.lineTo(6, 9);
    path.lineTo(10.2, 7.6);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparkleIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

// Checkmark Painter
class _CheckmarkIconPainter extends CustomPainter {
  final Color color;

  _CheckmarkIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // SVG path d="M5 12l5 5L20 7"
    final path = Path();
    path.moveTo(5, 12);
    path.lineTo(10, 17);
    path.lineTo(20, 7);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CheckmarkIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

// Export Download Icon Painter
class _ExportIconPainter extends CustomPainter {
  final Color color;

  _ExportIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // SVG path: M12 3v12M7 8l5-5 5 5M5 14v5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-5
    canvas.drawLine(const Offset(12, 3), const Offset(12, 15), paint);
    canvas.drawLine(const Offset(7, 8), const Offset(12, 3), paint);
    canvas.drawLine(const Offset(17, 8), const Offset(12, 3), paint);

    final bottomTray = Path();
    bottomTray.moveTo(5, 14);
    bottomTray.lineTo(5, 19);
    bottomTray.arcToPoint(const Offset(7, 21), radius: const Radius.circular(2), clockwise: false);
    bottomTray.lineTo(17, 21);
    bottomTray.arcToPoint(const Offset(19, 19), radius: const Radius.circular(2), clockwise: false);
    bottomTray.lineTo(19, 14);
    canvas.drawPath(bottomTray, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ExportIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
