import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/purchase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sip_button.dart';
import '../../../../core/widgets/sip_card.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_bloc.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_event.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  String _selectedPlan = 'yearly'; // 'yearly' pre-selected per Ahmed's spec
  bool _isLoading = false;

  final List<String> _proFeatures = [
    'No ads — clean and uninterrupted interface',
    'Smart reminders that learn when you usually drink',
    'Coffee, tea, juice and other drink types',
    'Weekly insights (e.g. weekend drop-off alerts)',
    'Six vibrant colour themes',
    'Home Screen and Lock Screen widgets',
    'Apple Health sync',
    'CSV export of your history',
  ];

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);
    // Simulate / Trigger RevenueCat flow
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      // Set Pro status active in BLoC & Hive
      context.read<WaterTrackingBloc>().add(const SetProStatusEvent(true));
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Welcome to Sip Pro! All features unlocked.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // Droplet Hero
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.water_drop_rounded, size: 38, color: Colors.white),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Drink better with Sip Pro',
                textAlign: TextAlign.center,
                style: AppTypography.title1(color: isDark ? AppColors.darkInk : AppColors.lightInk),
              ),
              const SizedBox(height: 8),
              Text(
                'Build healthy hydration habits with smart reminders, analytics and widgets.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(
                  color: isDark ? AppColors.darkInkSecondary : AppColors.lightInkSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Feature Checklist Card
              SipCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: _proFeatures.map((f) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.aquaPrimary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              f,
                              style: AppTypography.caption(
                                color: isDark ? AppColors.darkInk : AppColors.lightInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Plans Selection: Yearly vs Monthly
              // 1. Yearly Plan (Pre-selected)
              GestureDetector(
                onTap: () => setState(() => _selectedPlan = 'yearly'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedPlan == 'yearly' ? AppColors.aquaPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: _selectedPlan == 'yearly' ? 2 : 1,
                    ),
                    boxShadow: isDark ? null : AppColors.lightCardShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedPlan == 'yearly' ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: _selectedPlan == 'yearly' ? AppColors.aquaPrimary : AppColors.lightInkMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Yearly', style: AppTypography.headline(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1F1FA2FF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text('7-DAY FREE TRIAL', style: AppTypography.badge(color: AppColors.aquaPrimary)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('7 days free, then \$19.99/year (\$1.67/mo)', style: AppTypography.caption(color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted)),
                          ],
                        ),
                      ),
                      Text('\$1.67', style: AppTypography.headline(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                      Text('/mo', style: AppTypography.caption(color: AppColors.lightInkMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Monthly Plan
              GestureDetector(
                onTap: () => setState(() => _selectedPlan = 'monthly'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedPlan == 'monthly' ? AppColors.aquaPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: _selectedPlan == 'monthly' ? 2 : 1,
                    ),
                    boxShadow: isDark ? null : AppColors.lightCardShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedPlan == 'monthly' ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: _selectedPlan == 'monthly' ? AppColors.aquaPrimary : AppColors.lightInkMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monthly', style: AppTypography.headline(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                            const SizedBox(height: 2),
                            Text('\$2.99 per month, cancel anytime', style: AppTypography.caption(color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted)),
                          ],
                        ),
                      ),
                      Text('\$2.99', style: AppTypography.headline(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                      Text('/mo', style: AppTypography.caption(color: AppColors.lightInkMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Accent CTA Button: Start 7-day free trial
              SipButton(
                text: _selectedPlan == 'yearly' ? 'Start 7-day free trial' : 'Subscribe for \$2.99/mo',
                type: SipButtonType.accent,
                onPressed: _isLoading ? null : _handleSubscribe,
              ),
              const SizedBox(height: 16),

              // Footer Legal
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final restored = await PurchaseService.restorePurchases();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(restored ? 'Purchases restored!' : 'No purchases found.')),
                        );
                      }
                    },
                    child: Text('Restore purchases', style: AppTypography.caption(color: isDark ? AppColors.darkLink : AppColors.lightLink)),
                  ),
                  Text(' · ', style: AppTypography.caption(color: AppColors.lightInkMuted)),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse('https://txlabz.com/terms')),
                    child: Text('Terms', style: AppTypography.caption(color: isDark ? AppColors.darkLink : AppColors.lightLink)),
                  ),
                  Text(' · ', style: AppTypography.caption(color: AppColors.lightInkMuted)),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse('https://txlabz.com/privacy')),
                    child: Text('Privacy', style: AppTypography.caption(color: isDark ? AppColors.darkLink : AppColors.lightLink)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

