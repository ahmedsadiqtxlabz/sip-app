import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sip_button.dart';
import '../../../../core/widgets/sip_card.dart';
import '../../../../core/widgets/sip_chip.dart';
import '../../../../core/widgets/sip_toggle.dart';
import '../../../../core/widgets/water_fill_ring.dart';
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
  int _currentStep = 0;

  // Onboarding Form State
  int _weight = 72;
  String _weightUnit = 'kg';
  String _activity = 'moderate';
  String _climate = 'mild';
  int _suggestedGoal = 2500;
  String _wakeTime = '07:00 AM';
  String _bedTime = '11:00 PM';
  double _intervalHours = 2.0;
  bool _smartReminders = false;

  void _recalculateSuggestedGoal() {
    // Standard hydration math: Weight(kg) * 35ml + Activity bump + Climate bump
    int base = (_weight * 35);
    if (_weightUnit == 'lbs') {
      base = ((_weight * 0.453592) * 35).round();
    }
    if (_activity == 'active') base += 500;
    if (_activity == 'moderate') base += 250;
    if (_climate == 'hot') base += 500;
    if (_climate == 'mild') base += 200;

    setState(() {
      _suggestedGoal = (base / 50).round() * 50; // rounded to nearest 50
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

  Future<void> _finishOnboarding() async {
    // Pre-ATT on iOS
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {}

    if (!mounted) return;
    context.read<WaterTrackingBloc>().add(
          CompleteOnboardingEvent(
            goal: _suggestedGoal,
            weight: _weight,
            activity: _activity,
            climate: _climate,
          ),
        );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
              )
            : null,
        actions: [
          if (_currentStep < 5)
            TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                'Skip',
                style: AppTypography.body(
                  color: isDark ? AppColors.darkLink : AppColors.lightLink,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
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
    );
  }

  // --- Step 1: Welcome ---
  Widget _buildWelcomeStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const Spacer(),
          const WaterFillRing(
            progress: 0.65,
            currentAmount: 1625,
            goalAmount: 2500,
            size: 220,
          ),
          const SizedBox(height: 36),
          Text(
            'Hit your water goal,\none tap at a time.',
            textAlign: TextAlign.center,
            style: AppTypography.title1(
              color: isDark ? AppColors.darkInk : AppColors.lightInk,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Set a goal, log each drink in a tap, keep your streak going.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary(
              color: isDark ? AppColors.darkInkSecondary : AppColors.lightInkSecondary,
            ),
          ),
          const Spacer(),
          SipButton(
            text: 'Get started',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- Step 2: Personalize ---
  Widget _buildPersonalizeStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A little about you',
            style: AppTypography.title1(
              color: isDark ? AppColors.darkInk : AppColors.lightInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We use this to suggest a daily goal. You can change it any time.',
            style: AppTypography.bodySecondary(
              color: isDark ? AppColors.darkInkSecondary : AppColors.lightInkSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // Weight Card
          Text('WEIGHT', style: AppTypography.sectionLabel(color: AppColors.lightInkMuted)),
          const SizedBox(height: 8),
          SipCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$_weight',
                    style: AppTypography.heroNumber(
                      color: isDark ? AppColors.darkInk : AppColors.lightInk,
                    ).copyWith(fontSize: 42),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 30),
                  onPressed: () {
                    if (_weight > 30) {
                      setState(() => _weight -= 1);
                      _recalculateSuggestedGoal();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 30),
                  onPressed: () {
                    setState(() => _weight += 1);
                    _recalculateSuggestedGoal();
                  },
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    SipChip(
                      label: 'kg',
                      state: _weightUnit == 'kg'
                          ? SipChipState.selected
                          : SipChipState.defaultState,
                      onTap: () {
                        setState(() => _weightUnit = 'kg');
                        _recalculateSuggestedGoal();
                      },
                    ),
                    const SizedBox(width: 6),
                    SipChip(
                      label: 'lbs',
                      state: _weightUnit == 'lbs'
                          ? SipChipState.selected
                          : SipChipState.defaultState,
                      onTap: () {
                        setState(() => _weightUnit = 'lbs');
                        _recalculateSuggestedGoal();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Activity Level
          Text('ACTIVITY LEVEL', style: AppTypography.sectionLabel(color: AppColors.lightInkMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SipChip(
                  label: 'Light',
                  state: _activity == 'light' ? SipChipState.selected : SipChipState.defaultState,
                  onTap: () {
                    setState(() => _activity = 'light');
                    _recalculateSuggestedGoal();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SipChip(
                  label: 'Moderate',
                  state: _activity == 'moderate' ? SipChipState.selected : SipChipState.defaultState,
                  onTap: () {
                    setState(() => _activity = 'moderate');
                    _recalculateSuggestedGoal();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SipChip(
                  label: 'Active',
                  state: _activity == 'active' ? SipChipState.selected : SipChipState.defaultState,
                  onTap: () {
                    setState(() => _activity = 'active');
                    _recalculateSuggestedGoal();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Climate
          Text('CLIMATE', style: AppTypography.sectionLabel(color: AppColors.lightInkMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SipChip(
                  label: 'Cool',
                  state: _climate == 'cool' ? SipChipState.selected : SipChipState.defaultState,
                  onTap: () {
                    setState(() => _climate = 'cool');
                    _recalculateSuggestedGoal();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SipChip(
                  label: 'Mild',
                  state: _climate == 'mild' ? SipChipState.selected : SipChipState.defaultState,
                  onTap: () {
                    setState(() => _climate = 'mild');
                    _recalculateSuggestedGoal();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SipChip(
                  label: 'Hot',
                  state: _climate == 'hot' ? SipChipState.selected : SipChipState.defaultState,
                  onTap: () {
                    setState(() => _climate = 'hot');
                    _recalculateSuggestedGoal();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          SipButton(
            text: 'Continue',
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }

  // --- Step 3: Goal ---
  Widget _buildGoalStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(
            'Your daily goal',
            style: AppTypography.title1(
              color: isDark ? AppColors.darkInk : AppColors.lightInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Based on your weight, activity and climate. Adjust if it feels off.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary(
              color: isDark ? AppColors.darkInkSecondary : AppColors.lightInkSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Suggested badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkTint : AppColors.lightTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: AppColors.aquaPrimary),
                const SizedBox(width: 6),
                Text(
                  'Suggested for you',
                  style: AppTypography.caption(
                    color: isDark ? AppColors.darkLink : AppColors.lightLink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stepper Card
          SipCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                  onPressed: () {
                    if (_suggestedGoal > 500) {
                      setState(() => _suggestedGoal -= 100);
                    }
                  },
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Text(
                      '$_suggestedGoal',
                      style: AppTypography.heroNumber(
                        color: isDark ? AppColors.darkInk : AppColors.lightInk,
                      ),
                    ),
                    Text(
                      'ml per day',
                      style: AppTypography.caption(
                        color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                  onPressed: () {
                    setState(() => _suggestedGoal += 100);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'About ${(_suggestedGoal / 250).round()} cups. Most adults need between 2,000 and 3,000 ml.',
            textAlign: TextAlign.center,
            style: AppTypography.caption(
              color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
            ),
          ),
          const Spacer(),
          SipButton(
            text: 'Looks good',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- Step 4: Reminders ---
  Widget _buildRemindersStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gentle reminders',
            style: AppTypography.title1(
              color: isDark ? AppColors.darkInk : AppColors.lightInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "We'll only nudge you while you're awake.",
            style: AppTypography.bodySecondary(
              color: isDark ? AppColors.darkInkSecondary : AppColors.lightInkSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // Wake up & Bedtime Card
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
          const SizedBox(height: 24),

          // Remind me every
          Text('REMIND ME EVERY', style: AppTypography.sectionLabel(color: AppColors.lightInkMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SipChip(
                  label: '1 h',
                  state: _intervalHours == 1.0 ? SipChipState.selected : SipChipState.defaultState,
                  onTap: () => setState(() => _intervalHours = 1.0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SipChip(
                  label: '1.5 h',
                  state: _intervalHours == 1.5 ? SipChipState.selected : SipChipState.defaultState,
                  onTap: () => setState(() => _intervalHours = 1.5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SipChip(
                  label: '2 h',
                  state: _intervalHours == 2.0 ? SipChipState.selected : SipChipState.defaultState,
                  onTap: () => setState(() => _intervalHours = 2.0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SipChip(
                  label: '3 h',
                  state: _intervalHours == 3.0 ? SipChipState.selected : SipChipState.defaultState,
                  onTap: () => setState(() => _intervalHours = 3.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Smart reminders toggle card
          SipCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Smart reminders',
                            style: AppTypography.body(
                              color: isDark ? AppColors.darkInk : AppColors.lightInk,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'PRO',
                              style: AppTypography.badge(color: AppColors.lightOnGradient),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Learns when you usually drink',
                        style: AppTypography.caption(
                          color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SipToggle(
                  value: _smartReminders,
                  isLockedPro: true,
                  onChanged: (val) {
                    setState(() => _smartReminders = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          SipButton(
            text: 'Continue',
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }

  // --- Step 5: Notification Permission ---
  Widget _buildNotificationPermissionStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Mock Notification Preview Card
          SipCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0x261FA2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: AppColors.aquaPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sip', style: AppTypography.caption(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                          Text('now', style: AppTypography.caption(color: AppColors.lightInkMuted)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Time for a sip! You're 250 ml behind target",
                        style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Allow reminders?',
            style: AppTypography.title1(color: isDark ? AppColors.darkInk : AppColors.lightInk),
          ),
          const SizedBox(height: 8),
          Text(
            'A few friendly nudges a day, only between your wake time and bedtime. You can change this any time in Settings.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary(
              color: isDark ? AppColors.darkInkSecondary : AppColors.lightInkSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // Checklist
          _buildChecklistItem('Never during quiet hours', isDark),
          const SizedBox(height: 12),
          _buildChecklistItem('Log a drink straight from the notification', isDark),
          const SizedBox(height: 12),
          _buildChecklistItem('No spamming, ever', isDark),

          const Spacer(),
          SipButton(
            text: 'Enable reminders',
            onPressed: () async {
              await NotificationService().requestPermissions();
              _nextPage();
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _nextPage,
            child: Text(
              'Not now',
              style: AppTypography.body(color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- Step 6: Pre-ATT Explainer ---
  Widget _buildPreAttStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkTint : AppColors.lightTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 40,
              color: AppColors.aquaPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'One quick thing about ads',
            textAlign: TextAlign.center,
            style: AppTypography.title1(
              color: isDark ? AppColors.darkInk : AppColors.lightInk,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sip is free thanks to a small ad at the bottom of the screen. Next, you will see if the ad can feel relevant to you across other apps.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary(
              color: isDark ? AppColors.darkInkSecondary : AppColors.lightInkSecondary,
            ),
          ),
          const SizedBox(height: 28),
          _buildChecklistItem('When ads are relevant, they reward our work', isDark),
          const SizedBox(height: 12),
          _buildChecklistItem('Ads keep Sip free, everything else is the same', isDark),
          const SizedBox(height: 12),
          _buildChecklistItem('Your water log never leaves your device', isDark),
          const Spacer(),
          SipButton(
            text: 'Continue',
            onPressed: _finishOnboarding,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool isDark) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.aquaPrimary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body(
              color: isDark ? AppColors.darkInk : AppColors.lightInk,
            ),
          ),
        ),
      ],
    );
  }
}
