import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'features/water_tracking/presentation/bloc/water_tracking_bloc.dart';
import 'features/water_tracking/presentation/bloc/water_tracking_state.dart';
import 'features/water_tracking/presentation/pages/home_page.dart';
import 'features/history/presentation/pages/history_page.dart';
import 'features/reminders/presentation/pages/reminders_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    HistoryPage(),
    RemindersPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<WaterTrackingBloc, WaterTrackingState>(
      builder: (context, state) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xCC0E1116) // 80% opacity
                      : const Color(0xCCFFFFFF),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, 'Home', Icons.water_drop_outlined, Icons.water_drop_rounded, isDark),
                        _buildNavItem(1, 'History', Icons.bar_chart_outlined, Icons.bar_chart_rounded, isDark),
                        _buildNavItem(2, 'Reminders', Icons.alarm_outlined, Icons.alarm_rounded, isDark),
                        _buildNavItem(3, 'Profile', Icons.person_outline_rounded, Icons.person_rounded, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    IconData unselectedIcon,
    IconData selectedIcon,
    bool isDark,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? AppColors.aquaPrimary
        : (isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.badge(color: color).copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

