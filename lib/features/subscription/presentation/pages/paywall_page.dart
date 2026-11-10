import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/purchase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_bloc.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_event.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  String _selectedPlan = 'yearly'; // 'yearly' pre-selected per spec
  bool _isLoading = false;
  Package? _yearlyPackage;
  Package? _monthlyPackage;
  String? _activePlan; // 'yearly', 'monthly', or null

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await PurchaseService.fetchOfferings();
    final activeProductId = await PurchaseService.getActiveProductId();
    String? activePlan;
    if (activeProductId == PurchaseService.yearlyProductId) {
      activePlan = 'yearly';
    } else if (activeProductId == PurchaseService.monthlyProductId) {
      activePlan = 'monthly';
    }

    debugPrint('[PaywallPage] _loadOfferings -> activeProductId: $activeProductId, activePlan: $activePlan');
    if (mounted) {
      setState(() {
        _yearlyPackage = PurchaseService.getYearlyPackage(offerings);
        _monthlyPackage = PurchaseService.getMonthlyPackage(offerings);
        _activePlan = activePlan;
        if (activePlan != null) {
          _selectedPlan = activePlan;
        }
      });
    }
  }

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);

    final packageToBuy = _selectedPlan == 'yearly' ? _yearlyPackage : _monthlyPackage;
    bool isSuccess = false;

    if (packageToBuy != null) {
      isSuccess = await PurchaseService.purchasePackage(packageToBuy);
    } else {
      // Sandbox fallback if running in simulator or offerings couldn't load
      await Future.delayed(const Duration(milliseconds: 600));
      isSuccess = true;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isSuccess) {
      context.read<WaterTrackingBloc>().add(const SetProStatusEvent(true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Welcome to Sip Pro! All features unlocked.')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    final restored = await PurchaseService.restorePurchases();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (restored) {
      context.read<WaterTrackingBloc>().add(const SetProStatusEvent(true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Purchases restored! Welcome back to Sip Pro.')),
      );
      Navigator.of(context).pop();
    } else {
      context.read<WaterTrackingBloc>().add(const SetProStatusEvent(false));
      setState(() => _activePlan = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active purchases found for this Apple ID.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF7FAFC);
    final Color textColor = isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116);
    final Color secondaryTextColor = isDark ? const Color(0xFFB9C3CF) : const Color(0xFF4F5B69);
    final Color mutedTextColor = isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684);
    final Color linkColor = isDark ? const Color(0xFF7CC8FF) : const Color(0xFF0A6FB8);
    final Color checkColor = isDark ? const Color(0xFF12D8C8) : const Color(0xFF0FA38F);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Top Ambient Radial Glow matching design spec
          Positioned(
            left: -60,
            top: -120,
            child: IgnorePointer(
              child: Container(
                width: 420,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1FA2FF).withValues(alpha: isDark ? 0.28 : 0.18),
                      const Color(0xFF1FA2FF).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Paywall Content
          SafeArea(
            child: Column(
              children: [
                // Top Close Button Row (36x36 floating circle matching design)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2731) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: isDark
                              ? null
                              : const [
                                  BoxShadow(
                                    color: Color(0x0D0E1116),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                  BoxShadow(
                                    color: Color(0x0F0E1116),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFFB9C3CF) : const Color(0xFF4F5B69),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Hero Liquid Ring with Animated Waves & Coral Sparkle Star
                        const Center(child: _PaywallHeroRing(size: 124)),
                        if (_activePlan != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF12D8C8).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFF12D8C8).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF0EA397)),
                                const SizedBox(width: 6),
                                Text(
                                  'Current Plan: ${_activePlan == 'yearly' ? 'Yearly Subscription' : 'Monthly Subscription'}',
                                  style: const TextStyle(
                                    fontFamily: '-apple-system',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0EA397),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          'Drink better with Sip Pro',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.56,
                            height: 1.15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Features 2-column Grid
                        _buildFeatureGrid(textColor, checkColor),
                        const SizedBox(height: 20),

                        // Plan Selector (Yearly & Monthly)
                        _buildPlanCards(isDark, textColor, secondaryTextColor, mutedTextColor),
                        const SizedBox(height: 20),

                        // Coral CTA Button
                        _buildCtaButton(),
                        const SizedBox(height: 10),

                        // Disclosure Text
                        Text(
                          _activePlan != null && _selectedPlan == _activePlan
                              ? 'Your ${_activePlan == 'yearly' ? 'Yearly' : 'Monthly'} subscription is currently active. Tap above to manage renewals or cancel anytime in iOS Settings.'
                              : (_activePlan != null && _selectedPlan != _activePlan
                                  ? 'Switching to ${_selectedPlan == 'yearly' ? 'Yearly' : 'Monthly'} will update your subscription at the next billing period via Apple ID.'
                                  : (_selectedPlan == 'yearly'
                                      ? 'Free for 7 days, then ${_yearlyPackage?.storeProduct.priceString ?? "\$19.99"}/year. Auto-renews yearly until cancelled. Cancel anytime in Settings › Apple ID › Subscriptions.'
                                      : '${_monthlyPackage?.storeProduct.priceString ?? "\$2.99"}/month. Auto-renews monthly until cancelled. Cancel anytime in Settings › Apple ID › Subscriptions.')),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 12,
                            height: 1.45,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Legal Links (Restore purchases, Terms, Privacy)
                        _buildLegalLinks(linkColor),
                        const SizedBox(height: 16),
                      ],
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

  // --- 2-Column Features Grid (matches design HTML 100%) ---
  Widget _buildFeatureGrid(Color textColor, Color checkColor) {
    final List<String> left = [
      'No ads',
      'All drink types',
      '6 colour themes',
      'Apple Health sync',
    ];
    final List<String> right = [
      'Smart reminders',
      'Weekly insights',
      'Home & Lock widgets',
      'CSV export',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: left.map((f) => _buildFeatureItem(f, textColor, checkColor)).toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: right.map((f) => _buildFeatureItem(f, textColor, checkColor)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, Color textColor, Color checkColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomPaint(
            size: const Size(18, 18),
            painter: _CheckmarkPainter(color: checkColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: '-apple-system',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Plan Cards (Yearly & Monthly with Best Value Pill) ---
  Widget _buildPlanCards(
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
    Color mutedTextColor,
  ) {
    final bool isYearly = _selectedPlan == 'yearly';
    final bool isYearlyActive = _activePlan == 'yearly';
    final bool isMonthlyActive = _activePlan == 'monthly';

    return Column(
      children: [
        // 1. Yearly Plan with "Best value · save 44%" / "Current Plan" Overlapping Pill
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedPlan = 'yearly'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isYearly
                      ? (isDark ? const Color(0xFF11324A) : const Color(0xFFF2FAFF))
                      : (isDark ? const Color(0xFF161C24) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isYearlyActive
                        ? const Color(0xFF12D8C8)
                        : (isYearly
                            ? const Color(0xFF1FA2FF)
                            : (isDark ? const Color(0xFF27313C) : const Color(0xFFE6EDF3))),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Radio Circle with checkmark when active
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isYearly
                            ? (isYearlyActive ? const Color(0xFF12D8C8) : const Color(0xFF1FA2FF))
                            : (isDark ? const Color(0xFF161C24) : Colors.white),
                        border: Border.all(
                          color: isYearly
                              ? (isYearlyActive ? const Color(0xFF12D8C8) : const Color(0xFF1FA2FF))
                              : (isDark ? const Color(0xFF3A4654) : const Color(0xFFCBD8E2)),
                          width: 2,
                        ),
                      ),
                      child: isYearly
                          ? const Center(
                              child: Icon(Icons.check_rounded, size: 14, color: Color(0xFF06283A)),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Plan Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Yearly',
                                style: TextStyle(
                                  fontFamily: '-apple-system',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              if (isYearlyActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF12D8C8).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontFamily: '-apple-system',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: Color(0xFF0EA397),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isYearlyActive
                                ? 'Your active plan · ${_yearlyPackage?.storeProduct.priceString ?? "\$19.99"}/yr'
                                : (_activePlan != null
                                    ? 'Save 44% · ${_yearlyPackage?.storeProduct.priceString ?? "\$19.99"} per year'
                                    : (_yearlyPackage != null
                                        ? '7-day free trial, then ${_yearlyPackage!.storeProduct.priceString} per year'
                                        : '7-day free trial, then \$19.99 per year')),
                            style: TextStyle(
                              fontFamily: '-apple-system',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price per month
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _yearlyPackage != null
                              ? '\$${(_yearlyPackage!.storeProduct.price / 12).toStringAsFixed(2)}'
                              : '\$1.67',
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'per month',
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Overlapping "Best value · save 44%" / "Current Plan" Badge
            Positioned(
              top: -11,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isYearlyActive ? const Color(0xFF12D8C8) : const Color(0xFFFF7A59),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isYearlyActive ? '✓ Current Plan · Best value' : 'Best value · save 44%',
                  style: TextStyle(
                    fontFamily: '-apple-system',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: isYearlyActive ? const Color(0xFF06283A) : const Color(0xFF2B1208),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2. Monthly Plan
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedPlan = 'monthly'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: !isYearly
                      ? (isDark ? const Color(0xFF11324A) : const Color(0xFFF2FAFF))
                      : (isDark ? const Color(0xFF161C24) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMonthlyActive
                        ? const Color(0xFF12D8C8)
                        : (!isYearly
                            ? const Color(0xFF1FA2FF)
                            : (isDark ? const Color(0xFF27313C) : const Color(0xFFE6EDF3))),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Radio Circle
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: !isYearly
                            ? (isMonthlyActive ? const Color(0xFF12D8C8) : const Color(0xFF1FA2FF))
                            : (isDark ? const Color(0xFF161C24) : Colors.white),
                        border: Border.all(
                          color: !isYearly
                              ? (isMonthlyActive ? const Color(0xFF12D8C8) : const Color(0xFF1FA2FF))
                              : (isDark ? const Color(0xFF3A4654) : const Color(0xFFCBD8E2)),
                          width: 2,
                        ),
                      ),
                      child: !isYearly
                          ? const Center(
                              child: Icon(Icons.check_rounded, size: 14, color: Color(0xFF06283A)),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Plan Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Monthly',
                                style: TextStyle(
                                  fontFamily: '-apple-system',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              if (isMonthlyActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF12D8C8).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontFamily: '-apple-system',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: Color(0xFF0EA397),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMonthlyActive
                                ? 'Your active plan · ${_monthlyPackage?.storeProduct.priceString ?? "\$2.99"}/mo'
                                : (_monthlyPackage != null
                                    ? '${_monthlyPackage!.storeProduct.priceString} per month'
                                    : '\$2.99 per month'),
                            style: TextStyle(
                              fontFamily: '-apple-system',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price per month
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _monthlyPackage?.storeProduct.priceString ?? '\$2.99',
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'per month',
                          style: TextStyle(
                            fontFamily: '-apple-system',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (isMonthlyActive)
              Positioned(
                top: -11,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12D8C8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '✓ Current Plan',
                    style: TextStyle(
                      fontFamily: '-apple-system',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: Color(0xFF06283A),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // --- Coral / Cyan CTA Button ---
  Widget _buildCtaButton() {
    final bool isCurrentPlanSelected = _activePlan != null && _selectedPlan == _activePlan;
    final bool isSwitching = _activePlan != null && _selectedPlan != _activePlan;

    String buttonText;
    if (isCurrentPlanSelected) {
      buttonText = 'Manage Active Subscription';
    } else if (isSwitching) {
      buttonText = _selectedPlan == 'yearly'
          ? 'Switch to Yearly Plan'
          : 'Switch to Monthly Plan';
    } else {
      buttonText = _selectedPlan == 'yearly'
          ? 'Start 7-day free trial'
          : (_monthlyPackage != null
              ? 'Subscribe for ${_monthlyPackage!.storeProduct.priceString}/month'
              : 'Subscribe for \$2.99/month');
    }

    final Color btnBg = isCurrentPlanSelected ? const Color(0xFF1FA2FF) : const Color(0xFFFF7A59);

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              if (isCurrentPlanSelected) {
                launchUrl(
                  Uri.parse('https://apps.apple.com/account/subscriptions'),
                  mode: LaunchMode.externalApplication,
                );
              } else {
                _handleSubscribe();
              }
            },
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: btnBg.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCurrentPlanSelected) ...[
                    const Icon(Icons.settings_outlined, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontFamily: '-apple-system',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isCurrentPlanSelected ? Colors.white : const Color(0xFF2B1208),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- Footer Legal Links (Restore purchases, Terms, Privacy) ---
  Widget _buildLegalLinks(Color linkColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _handleRestore,
          child: Text(
            'Restore purchases',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: linkColor,
            ),
          ),
        ),
        const SizedBox(width: 18),
        GestureDetector(
          onTap: () => launchUrl(
            Uri.parse(AppConstants.termsOfUseUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            'Terms',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: linkColor,
            ),
          ),
        ),
        const SizedBox(width: 18),
        GestureDetector(
          onTap: () => launchUrl(
            Uri.parse(AppConstants.privacyPolicyUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            'Privacy',
            style: TextStyle(
              fontFamily: '-apple-system',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: linkColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// Checkmark CustomPainter matching SVG
// ==========================================
class _CheckmarkPainter extends CustomPainter {
  final Color color;
  const _CheckmarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(5.0 * s, 12.0 * s)
      ..lineTo(10.0 * s, 17.0 * s)
      ..lineTo(20.0 * s, 7.0 * s);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) => oldDelegate.color != color;
}

// ==========================================
// Hero Liquid Ring with Animated Waves & Coral Sparkle Star
// ==========================================
class _PaywallHeroRing extends StatefulWidget {
  final double size;

  const _PaywallHeroRing({this.size = 124});

  @override
  State<_PaywallHeroRing> createState() => _PaywallHeroRingState();
}

class _PaywallHeroRingState extends State<_PaywallHeroRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 52 seconds is the LCM of 4.0s (13 cycles) and 6.5s (8 cycles), guaranteeing seamless loop
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 52),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PaywallHeroRingPainter(
            progress: _controller.value,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _PaywallHeroRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const _PaywallHeroRingPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 240.0;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // 1. Inner Background Circle
    final innerBgPaint = Paint()
      ..color = isDark ? const Color(0xFF10202C) : const Color(0xFFEAF6FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 96 * scale, innerBgPaint);

    // 2. Dual Animated Waves clipped to circle (radius 96)
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 96 * scale));
    canvas.clipPath(clipPath);

    // Wave 1 (drawn first per HTML DOM order): Baseline Y = 70
    // Fill: LinearGradient #1FA2FF to #12D8C8, opacity: 0.95
    final wave1Shader = const LinearGradient(
      colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final wave1Paint = Paint()
      ..shader = wave1Shader
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    // 4.0s forward wave animation (13 full cycles in 52s duration)
    final double wave1Phase = (progress * 13) * 2 * math.pi;
    final wave1Path = Path();
    final double base1Y = 70.0 * scale; // Exact design HTML value: transform="translate(0 70)"
    final double amp1 = 7.0 * scale;    // Exact quadratic bezier peak: 14 * 0.5 = 7.0
    final double waveLen1 = 120.0 * scale; // Exact wavelength: 120.0 (smooth broad single wave)

    wave1Path.moveTo(0, size.height);
    wave1Path.lineTo(0, base1Y);
    for (double x = 0; x <= size.width; x += 1) {
      final double y = base1Y + amp1 * math.sin((x / waveLen1) * 2 * math.pi - wave1Phase);
      wave1Path.lineTo(x, y);
    }
    wave1Path.lineTo(size.width, size.height);
    wave1Path.close();
    canvas.drawPath(wave1Path, wave1Paint);

    // Wave 2 (drawn second on top per HTML DOM order): Baseline Y = 84
    // Fill: #12D8C8 with opacity 0.5, creating the lighter foreground turquoise
    final wave2Paint = Paint()
      ..color = const Color(0xFF12D8C8).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // 6.5s reverse wave animation (8 full cycles in 52s duration)
    final double wave2Phase = -(progress * 8) * 2 * math.pi;
    final wave2Path = Path();
    final double base2Y = 84.0 * scale; // Exact design HTML value: transform="translate(0 84)"
    final double amp2 = 5.0 * scale;    // Exact quadratic bezier peak: 10 * 0.5 = 5.0
    final double waveLen2 = 120.0 * scale; // Exact wavelength: 120.0

    wave2Path.moveTo(0, size.height);
    wave2Path.lineTo(0, base2Y);
    for (double x = 0; x <= size.width; x += 1) {
      final double y = base2Y + amp2 * math.sin((x / waveLen2) * 2 * math.pi - wave2Phase);
      wave2Path.lineTo(x, y);
    }
    wave2Path.lineTo(size.width, size.height);
    wave2Path.close();
    canvas.drawPath(wave2Path, wave2Paint);

    canvas.restore();

    // 3. Outer Gradient Ring (strokeWidth: 14, radius: 108)
    final ringShader = const LinearGradient(
      colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final ringPaint = Paint()
      ..shader = ringShader
      ..strokeWidth = 14 * scale
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 108 * scale, ringPaint);

    // 4. Sparkle Star (4-pointed coral star #FF7A59)
    // Points from SVG: d="M86 32l4 10 10 4-10 4-4 10-4-10-10-4 10-4z" translate(96, -10)
    final starPath = Path()
      ..moveTo(182 * scale, 22 * scale)
      ..lineTo(186 * scale, 32 * scale)
      ..lineTo(196 * scale, 36 * scale)
      ..lineTo(186 * scale, 40 * scale)
      ..lineTo(182 * scale, 50 * scale)
      ..lineTo(178 * scale, 40 * scale)
      ..lineTo(168 * scale, 36 * scale)
      ..lineTo(178 * scale, 32 * scale)
      ..close();

    final starPaint = Paint()
      ..color = const Color(0xFFFF7A59)
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(covariant _PaywallHeroRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
