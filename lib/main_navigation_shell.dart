import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'features/water_tracking/presentation/bloc/water_tracking_bloc.dart';
import 'features/water_tracking/presentation/bloc/water_tracking_state.dart';
import 'features/water_tracking/presentation/pages/home_page.dart';
import 'features/history/presentation/pages/history_page.dart';
import 'features/reminders/presentation/pages/reminders_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';

enum NavTabType { home, history, reminders, profile }

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
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xCC161C24) // rgba(22, 28, 36, 0.80)
                      : const Color(0xC7FFFFFF), // rgba(255, 255, 255, 0.78)
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0x0FFFFFFF) // rgba(255, 255, 255, 0.06)
                          : const Color(0x0F0E1116), // rgba(14, 17, 22, 0.06)
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, 'Home', NavTabType.home, isDark, state.activeTheme.primary),
                        _buildNavItem(1, 'History', NavTabType.history, isDark, state.activeTheme.primary),
                        _buildNavItem(2, 'Reminders', NavTabType.reminders, isDark, state.activeTheme.primary),
                        _buildNavItem(3, 'Profile', NavTabType.profile, isDark, state.activeTheme.primary),
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
    NavTabType type,
    bool isDark,
    Color activeThemeColor,
  ) {
    final isSelected = _currentIndex == index;
    final textColor = isSelected
        ? activeThemeColor
        : (isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684));
    final iconColor = isSelected
        ? activeThemeColor
        : (isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684));

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NavTabIcon(
              type: type,
              isSelected: isSelected,
              activeColor: iconColor,
              inactiveColor: iconColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.1,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavTabIcon extends StatelessWidget {
  final NavTabType type;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  const NavTabIcon({
    super.key,
    required this.type,
    required this.isSelected,
    this.activeColor = const Color(0xFF1FA2FF),
    required this.inactiveColor,
  });

  String get _assetPath {
    switch (type) {
      case NavTabType.home:
        return isSelected ? 'assets/icons/nav_home_active.svg' : 'assets/icons/nav_home.svg';
      case NavTabType.history:
        return isSelected ? 'assets/icons/nav_history_active.svg' : 'assets/icons/nav_history.svg';
      case NavTabType.reminders:
        return isSelected ? 'assets/icons/nav_reminders_active.svg' : 'assets/icons/nav_reminders.svg';
      case NavTabType.profile:
        return isSelected ? 'assets/icons/nav_profile_active.svg' : 'assets/icons/nav_profile.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;
    return SvgPicture.asset(
      _assetPath,
      width: 26,
      height: 26,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
