import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/liquid_water_ring.dart';
import '../../../../gen/assets.gen.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_bloc.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_event.dart';
import '../../../../main_navigation_shell.dart';
import '../../../../core/services/notification_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  late final TextEditingController _weightController;
  int _currentStep = 0;

  // Onboarding Form State
  int _weight = 72;
  String _weightUnit = 'kg';
  String _activity = 'Moderate';
  String _climate = 'Mild';
  int _suggestedGoal = 2500;
  String _goalUnit = 'ml';
  TimeOfDay _wakeTimeOfDay = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bedTimeOfDay = const TimeOfDay(hour: 23, minute: 0);
  double _intervalHours = 2.0;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: '72');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _recalculateSuggestedGoal() {
    int base = (_weight * 35);
    if (_weightUnit == 'lb') {
      base = ((_weight * 0.453592) * 35).round();
    }
    if (_activity == 'Active') base += 500;
    if (_activity == 'Moderate') base += 250;
    if (_climate == 'Hot') base += 500;
    if (_climate == 'Mild') base += 200;

    setState(() {
      _suggestedGoal = (base / 50).round() * 50;
    });
  }

  void _nextPage() {
    if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() {
    context.read<WaterTrackingBloc>().add(
          CompleteOnboardingEvent(
            goal: _goalUnit == 'ml' ? _suggestedGoal : (_suggestedGoal * 29.5735).round(),
            weight: _weightUnit == 'kg' ? _weight : (_weight * 0.453592).round(),
            activity: _activity.toLowerCase(),
            climate: _climate.toLowerCase(),
          ),
        );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _pickTime({required bool isWake}) async {
    final initial = isWake ? _wakeTimeOfDay : _bedTimeOfDay;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isWake) {
          _wakeTimeOfDay = picked;
        } else {
          _bedTimeOfDay = picked;
        }
      });
    }
  }

  String _getFrequencyLabel() {
    if (_intervalHours == 1.0) return '1 hour';
    if (_intervalHours % 1 == 0) return '${_intervalHours.toInt()} hours';
    return '${_intervalHours.toInt()}½ hours';
  }

  // --- Step Indicator Dots ---
  Widget _buildStepIndicator(int activeIndex) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final bool isActive = (i == activeIndex.clamp(0, 3));
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.aquaPrimary : const Color(0xFFCBD8E2),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // --- Header Bar ---
  Widget _buildHeader(bool isDark) {
    if (_currentStep == 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: _previousPage,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? AppColors.darkInk : const Color(0xFF0A6FB8),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back Arrow above the indicator (shown when step > 0)
          if (_currentStep > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: _previousPage,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: isDark ? AppColors.darkInk : const Color(0xFF0A6FB8),
                  ),
                ),
              ),
            ),

          // Row with Indicator at START (left) and Skip / Not Now at END (right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Indicator at the Start
              _buildStepIndicator(_currentStep == 4 ? 3 : _currentStep),

              // Skip / Not now at the End
              GestureDetector(
                onTap: _currentStep == 4 ? _nextPage : _finishOnboarding,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Text(
                    _currentStep == 4 ? 'Not now' : 'Skip',
                    style: AppTypography.headline(
                      color: isDark ? AppColors.darkLink : const Color(0xFF0A6FB8),
                    ).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Sticky Bottom Action Button ---
  Widget _buildStickyBottom(bool isDark) {
    String buttonText = 'Continue';
    String? subText;

    if (_currentStep == 0) {
      buttonText = 'Get started';
    } else if (_currentStep == 1) {
      buttonText = 'Continue';
    } else if (_currentStep == 2) {
      buttonText = 'Looks good';
    } else if (_currentStep == 3) {
      buttonText = 'Continue';
    } else if (_currentStep == 4) {
      buttonText = 'Enable reminders';
      subText = 'iOS will ask you to confirm next.';
    } else if (_currentStep == 5) {
      buttonText = 'Continue';
      subText = 'You decide on the next screen.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF7FAFC),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFF7FAFC).withValues(alpha: 0.9),
                  blurRadius: 10,
                  offset: const Offset(0, -6),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                if (_currentStep == 4) {
                  // Request Notification Permission
                  await NotificationService().requestPermissions();
                  _nextPage();
                } else if (_currentStep == 5) {
                  // Request ATT permission
                  try {
                    await AppTrackingTransparency.requestTrackingAuthorization();
                  } catch (_) {}
                  _finishOnboarding();
                } else {
                  _nextPage();
                }
              },
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x401FA2FF),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontFamily: '-apple-system',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF06283A),
                    ),
                  ),
                ),
              ),
            ),
            if (subText != null) ...[
              const SizedBox(height: 8),
              Text(
                subText,
                style: const TextStyle(
                  fontFamily: '-apple-system',
                  fontSize: 12,
                  color: Color(0xFF6B7684),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          _previousPage();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF7FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // Fixed Top Header with Back Arrow, Step Indicators at start & Skip at end
              _buildHeader(isDark),

              // Scrollable Content in PageView with smooth swipe navigation
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentStep = i),
                  children: [
                    _buildWelcomeStep(isDark),
                    _buildPersonalizeStep(isDark),
                    _buildGoalStep(isDark),
                    _buildRemindersStep(isDark),
                    _buildNotificationPermissionStep(isDark),
                    _buildPreAttStep(isDark),
                  ],
                ),
              ),

              // Fixed Sticky Bottom Continue Button
              _buildStickyBottom(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 1: WELCOME (Screen 2a)
  // ==========================================
  Widget _buildWelcomeStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Live Animated Liquid Ring with dynamic wave motion (matching design HTML)
          const LiquidWaterRing(
            size: 260,
            progress: 0.65,
            percentText: '65%',
            subText: '1,625 of 2,500 ml',
          ),
          const SizedBox(height: 36),
          Text(
            'Hit your water goal, one tap at a time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
              color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Set a goal, log each drink in a tap, keep your streak going.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 17,
              height: 1.4,
              color: isDark ? AppColors.darkInkSecondary : const Color(0xFF4F5B69),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: PERSONALIZE (Screen 2b)
  // ==========================================
  Widget _buildPersonalizeStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A little about you',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
              color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We use this to suggest a daily goal. You can change it any time.',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 16,
              height: 1.4,
              color: isDark ? AppColors.darkInkSecondary : const Color(0xFF4F5B69),
            ),
          ),
          const SizedBox(height: 28),

          // --- Weight Card ---
          Text(
            'WEIGHT',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkInkMuted : const Color(0xFF4F5B69),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isDark ? Border.all(color: AppColors.darkBorder) : null,
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0D0E1116),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontFamily: '-apple-system',
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          _weight = parsed;
                          _recalculateSuggestedGoal();
                        });
                      }
                    },
                  ),
                ),
                // Weight Unit Segmented Control (kg | lb)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2833) : const Color(0xFFEEF3F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildUnitOption('kg', isSelected: _weightUnit == 'kg', isDark: isDark, onTap: () {
                        if (_weightUnit != 'kg') {
                          setState(() {
                            _weightUnit = 'kg';
                            _weight = (_weight * 0.453592).round();
                            _weightController.text = '$_weight';
                            _recalculateSuggestedGoal();
                          });
                        }
                      }),
                      _buildUnitOption('lb', isSelected: _weightUnit == 'lb', isDark: isDark, onTap: () {
                        if (_weightUnit != 'lb') {
                          setState(() {
                            _weightUnit = 'lb';
                            _weight = (_weight / 0.453592).round();
                            _weightController.text = '$_weight';
                            _recalculateSuggestedGoal();
                          });
                        }
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Activity Level ---
          Text(
            'ACTIVITY LEVEL',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkInkMuted : const Color(0xFF4F5B69),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ['Light', 'Moderate', 'Active'].map((level) {
              final isSelected = _activity == level;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildChoiceChip(
                    label: level,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () {
                      setState(() {
                        _activity = level;
                        _recalculateSuggestedGoal();
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // --- Climate ---
          Text(
            'CLIMATE',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkInkMuted : const Color(0xFF4F5B69),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ['Cool', 'Mild', 'Hot'].map((climate) {
              final isSelected = _climate == climate;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildChoiceChip(
                    label: climate,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () {
                      setState(() {
                        _climate = climate;
                        _recalculateSuggestedGoal();
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: DAILY GOAL (Screen 2c)
  // ==========================================
  Widget _buildGoalStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your daily goal',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
              color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your weight, activity and climate. Adjust it if you like.',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 16,
              height: 1.4,
              color: isDark ? AppColors.darkInkSecondary : const Color(0xFF4F5B69),
            ),
          ),
          const SizedBox(height: 28),

          // Big Goal Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: isDark ? Border.all(color: AppColors.darkBorder) : null,
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0D0E1116),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
            ),
            child: Column(
              children: [
                // Suggested for you badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF142E42) : const Color(0xFFE6F4FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.water_drop_rounded, size: 14, color: Color(0xFF0A6FB8)),
                      const SizedBox(width: 6),
                      Text(
                        'Suggested for you',
                        style: TextStyle(
                          fontFamily: '-apple-system',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF68BFFF) : const Color(0xFF0A6FB8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stepper Row: (-) [ 2,500 ] (+)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Minus Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _suggestedGoal = (_suggestedGoal - 250).clamp(500, 6000);
                        });
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF24303D) : const Color(0xFFEEF3F7),
                        ),
                        child: Center(
                          child: Text(
                            '−',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Big Number
                    Column(
                      children: [
                        Text(
                          _suggestedGoal.toString().replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]},',
                              ),
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 60,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2.4,
                            height: 1.0,
                            color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_goalUnit per day',
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkInkMuted : const Color(0xFF4F5B69),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),

                    // Plus Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _suggestedGoal = (_suggestedGoal + 250).clamp(500, 6000);
                        });
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF06283A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Unit Toggle (ml | fl oz)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2833) : const Color(0xFFEEF3F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildUnitOption('ml', isSelected: _goalUnit == 'ml', isDark: isDark, onTap: () {
                        setState(() => _goalUnit = 'ml');
                      }),
                      _buildUnitOption('fl oz', isSelected: _goalUnit == 'fl oz', isDark: isDark, onTap: () {
                        setState(() => _goalUnit = 'fl oz');
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'About 10 cups. Most adults do well between 2,000 and 3,000 ml.',
              style: TextStyle(
                fontFamily: '-apple-system',
                fontSize: 13,
                color: isDark ? AppColors.darkInkMuted : const Color(0xFF6B7684),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 4: GENTLE REMINDERS (Screen 2d)
  // ==========================================
  Widget _buildRemindersStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gentle reminders',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
              color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll only nudge you while you're awake.",
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 16,
              height: 1.4,
              color: isDark ? AppColors.darkInkSecondary : const Color(0xFF4F5B69),
            ),
          ),
          const SizedBox(height: 24),

          // TWO SIDE-BY-SIDE TILES: Wake up & Bedtime
          Row(
            children: [
              // Wake Up Tile
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(isWake: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                      boxShadow: isDark
                          ? null
                          : const [
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
                        Text(
                          'Wake up',
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkInkMuted : const Color(0xFF4F5B69),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatTime(_wakeTimeOfDay),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: '-apple-system',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: isDark ? AppColors.darkInkMuted : const Color(0xFF6B7684),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Bedtime Tile
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(isWake: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                      boxShadow: isDark
                          ? null
                          : const [
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
                        Text(
                          'Bedtime',
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkInkMuted : const Color(0xFF4F5B69),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatTime(_bedTimeOfDay),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: '-apple-system',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: isDark ? AppColors.darkInkMuted : const Color(0xFF6B7684),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Remind me every Slider Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isDark ? Border.all(color: AppColors.darkBorder) : null,
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0D0E1116),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remind me every',
                      style: TextStyle(
                        fontFamily: '-apple-system',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
                      ),
                    ),
                    Text(
                      _getFrequencyLabel(),
                      style: const TextStyle(
                        fontFamily: '-apple-system',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A6FB8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    trackShape: const _GradientSliderTrackShape(),
                    thumbShape: const _SipSliderThumbShape(radius: 14),
                    overlayColor: const Color(0x1F1FA2FF),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                    tickMarkShape: SliderTickMarkShape.noTickMark,
                  ),
                  child: Slider(
                    value: _intervalHours,
                    min: 1.0,
                    max: 3.0,
                    onChanged: (v) => setState(() => _intervalHours = v),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 hr', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkInkMuted : const Color(0xFF6B7684))),
                      Text('2 hr', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkInkMuted : const Color(0xFF6B7684))),
                      Text('3 hr', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkInkMuted : const Color(0xFF6B7684))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Smart reminders Card (Locked PRO feature)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isDark ? Border.all(color: AppColors.darkBorder) : null,
              boxShadow: isDark
                  ? null
                  : const [
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome_rounded, size: 20, color: Color(0xFFD9532F)),
                  ),
                ),
                const SizedBox(width: 14),
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
                              color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)]),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF06283A)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Adapts timing to when you actually drink',
                        style: TextStyle(
                          fontFamily: '-apple-system',
                          fontSize: 13,
                          color: isDark ? AppColors.darkInkMuted : const Color(0xFF6B7684),
                        ),
                      ),
                    ],
                  ),
                ),
                // Locked Toggle Visual
                Container(
                  width: 51,
                  height: 31,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DEE6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    width: 27,
                    height: 27,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x330E1116),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.lock_rounded, size: 12, color: Color(0xFF6B7684)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 5: NOTIFICATION PERMISSION (Screen 2d_notif)
  // ==========================================
  Widget _buildNotificationPermissionStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          // Notification Preview Bubbles (Width 300px centered, matching design spec)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Center(
              child: SizedBox(
                width: 300,
                child: Column(
                  children: [
                    // Bubble 1: "now" (active, slight -2 deg angle, width: 300)
                    Transform.rotate(
                      angle: -0.035, // ~ -2 deg
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xF21F2833) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F0E1116),
                              blurRadius: 32,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)]),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Sip', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkInk : const Color(0xFF0E1116))),
                                      const Text('now', style: TextStyle(fontSize: 12, color: Color(0xFF6B7684))),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Time for a sip? You're 250 ml from halfway.",
                                    style: TextStyle(fontSize: 14, height: 1.3, color: isDark ? AppColors.darkInkSecondary : const Color(0xFF0E1116)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Bubble 2: "2h ago" (secondary, slight 1.5 deg angle, scaled 0.94, opacity 0.85)
                    Transform.rotate(
                      angle: 0.026, // ~1.5 deg
                      child: Transform.scale(
                        scale: 0.94,
                        child: Opacity(
                          opacity: 0.85,
                          child: Container(
                            width: 300,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xE61A222D) : const Color(0xD9FFFFFF),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x140E1116),
                                  blurRadius: 24,
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
                                    gradient: const LinearGradient(colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)]),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Sip', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkInk : const Color(0xFF0E1116))),
                                          const Text('2h ago', style: TextStyle(fontSize: 12, color: Color(0xFF6B7684))),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Nice, 12-day streak. Keep it flowing.',
                                        style: TextStyle(fontSize: 14, height: 1.3, color: isDark ? AppColors.darkInkSecondary : const Color(0xFF0E1116)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Allow reminders?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
              color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'A few friendly nudges a day, only between your wake time and bedtime. You can change this any time in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 16,
              height: 1.45,
              color: isDark ? AppColors.darkInkSecondary : const Color(0xFF4F5B69),
            ),
          ),
          const SizedBox(height: 28),

          // Checklist items
          _buildCheckItem('Never during quiet hours', isDark),
          const SizedBox(height: 12),
          _buildCheckItem('Log a drink straight from the notification', isDark),
          const SizedBox(height: 12),
          _buildCheckItem('No marketing, ever', isDark),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 6: PRE-ATT EXPLAINER (Screen 3)
  // ==========================================
  Widget _buildPreAttStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Exact Blue Shield with Checkmark Icon from design spec
          Assets.icons.adsShield.image(
            width: 96,
            height: 96,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),

          Text(
            'One quick thing about ads',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
              color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sip is free thanks to a small ad at the bottom of the screen. Next, iOS will ask if the ad partner may track you across other apps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 16,
              height: 1.45,
              color: isDark ? AppColors.darkInkSecondary : const Color(0xFF4F5B69),
            ),
          ),
          const SizedBox(height: 28),

          // Info Card with 3 bullet lines
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: isDark ? Border.all(color: AppColors.darkBorder) : null,
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0D0E1116),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
            ),
            child: Column(
              children: [
                _buildAttBullet('Allow', ' and ads are a bit more relevant.', isDark),
                const SizedBox(height: 14),
                _buildAttBullet('Ask App Not to Track', ' and everything still works exactly the same.', isDark),
                const SizedBox(height: 14),
                _buildAttBullet('', 'Your water log never leaves your device.', isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Prefer no ads at all? Sip Pro removes them.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 13,
              color: isDark ? AppColors.darkInkMuted : const Color(0xFF6B7684),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Segmented Unit Option (kg / lb / ml / fl oz)
  Widget _buildUnitOption(String label, {required bool isSelected, required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF2C3947) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected && !isDark
              ? const [
                  BoxShadow(
                    color: Color(0x1F0E1116),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? (isDark ? AppColors.darkInk : const Color(0xFF0E1116))
                  : (isDark ? AppColors.darkInkMuted : const Color(0xFF4F5B69)),
            ),
          ),
        ),
      ),
    );
  }

  // Helper: Choice Chip for Activity & Climate
  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF142E42) : const Color(0xFFE6F4FF))
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.aquaPrimary
                : (isDark ? AppColors.darkBorder : const Color(0xFFE1E8EF)),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? (isDark ? const Color(0xFF68BFFF) : const Color(0xFF0A6FB8))
                  : (isDark ? AppColors.darkInk : const Color(0xFF0E1116)),
            ),
          ),
        ),
      ),
    );
  }

  // Helper: Checklist Item with Green Check
  Widget _buildCheckItem(String text, bool isDark) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, color: Color(0xFF0FA38F), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
            ),
          ),
        ),
      ],
    );
  }

  // Helper: Pre-ATT Explainer Bullet
  Widget _buildAttBullet(String boldPrefix, String restOfText, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_rounded, color: Color(0xFF0FA38F), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: '-apple-system',
                fontSize: 15,
                height: 1.4,
                color: isDark ? AppColors.darkInk : const Color(0xFF0E1116),
              ),
              children: [
                if (boldPrefix.isNotEmpty)
                  TextSpan(
                    text: boldPrefix,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                TextSpan(text: restOfText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom Slider Track with continuous LinearGradient (#1FA2FF -> #12D8C8)
class _GradientSliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  static const LinearGradient _gradient = LinearGradient(
    colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
  );

  const _GradientSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint paint = Paint()
      ..shader = _gradient.createShader(trackRect)
      ..style = PaintingStyle.fill;

    // Draw continuous 6px gradient rounded track matching design spec
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, const Radius.circular(3)),
      paint,
    );
  }
}

/// Custom 28px diameter white circular slider thumb with soft shadow
class _SipSliderThumbShape extends SliderComponentShape {
  final double radius;

  const _SipSliderThumbShape({this.radius = 14.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Soft drop shadow matching CSS: box-shadow: 0 2px 8px rgba(14,17,22,0.2)
    final shadowPaint = Paint()
      ..color = const Color(0x330E1116)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(0, 2), radius, shadowPaint);

    // Pure white thumb circle
    final thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, thumbPaint);
  }
}
