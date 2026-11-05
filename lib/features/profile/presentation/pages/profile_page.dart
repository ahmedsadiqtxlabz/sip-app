import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/pro_themes.dart';
import '../../../../core/services/purchase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sip_card.dart';
import '../../../../core/widgets/sip_chip.dart';
import '../../../../core/widgets/sip_toggle.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_bloc.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_event.dart';
import '../../../water_tracking/presentation/bloc/water_tracking_state.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showGoalDialog(BuildContext context, int currentGoal, String unit) {
    int tempGoal = currentGoal;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Daily Goal', style: AppTypography.title2()),
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
              Text('$tempGoal $unit', style: AppTypography.headline()),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all your drink logs, streaks, and local settings. This action cannot be undone.',
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
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
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
          appBar: AppBar(
            title: Text(
              'Profile',
              style: AppTypography.title2(
                color: isDark ? AppColors.darkInk : AppColors.lightInk,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header Card
                SipCard(
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: state.activeTheme.gradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            settings.userName.isNotEmpty ? settings.userName[0].toUpperCase() : 'M',
                            style: AppTypography.headline(color: Colors.white).copyWith(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${settings.userName} Lindqvist',
                              style: AppTypography.headline(color: isDark ? AppColors.darkInk : AppColors.lightInk),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isPro ? 'Sip Pro · Active' : 'Sip Free',
                              style: AppTypography.caption(
                                color: isPro ? AppColors.aquaPrimary : AppColors.lightInkMuted,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Upgrade Card (If !isPro)
                if (!isPro)
                  SipCard(
                    type: SipCardType.upsell,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.aquaPrimary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Upgrade to Sip Pro', style: AppTypography.headline(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                              Text('Remove ads, unlock all themes & smart reminders', style: AppTypography.caption(color: isDark ? AppColors.darkLink : AppColors.lightLink)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.lightInkMuted),
                      ],
                    ),
                  )
                else
                  SipCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sip Pro · Annual', style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                            Text('Renews 6 November 2025', style: AppTypography.caption(color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted)),
                          ],
                        ),
                        Text('Manage', style: AppTypography.caption(color: AppColors.aquaPrimary)),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Preferences Section
                Text('PREFERENCES', style: AppTypography.sectionLabel(color: AppColors.lightInkMuted)),
                const SizedBox(height: 8),

                SipCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Daily Goal
                      ListTile(
                        title: Text('Daily goal', style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${settings.dailyGoal} ${settings.unit}', style: AppTypography.body(color: isDark ? AppColors.darkLink : AppColors.lightLink)),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.lightInkMuted),
                          ],
                        ),
                        onTap: () => _showGoalDialog(context, settings.dailyGoal, settings.unit),
                      ),
                      const Divider(),

                      // Units
                      ListTile(
                        title: Text('Units', style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SipChip(
                              label: 'ml',
                              state: settings.unit == 'ml' ? SipChipState.selected : SipChipState.defaultState,
                              onTap: () => context.read<WaterTrackingBloc>().add(const UpdateUnitEvent('ml')),
                            ),
                            const SizedBox(width: 6),
                            SipChip(
                              label: 'fl oz',
                              state: settings.unit == 'fl oz' ? SipChipState.selected : SipChipState.defaultState,
                              onTap: () => context.read<WaterTrackingBloc>().add(const UpdateUnitEvent('fl oz')),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Themes Selector (6 Swatches)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Theme', style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                                Text(state.activeTheme.name, style: AppTypography.caption(color: isDark ? AppColors.darkLink : AppColors.lightLink)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: ProThemes.allThemes.map((theme) {
                                final isSelected = state.activeTheme.name == theme.name;
                                return GestureDetector(
                                  onTap: () {
                                    if (!isPro && theme.name != 'Aqua') {
                                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
                                    } else {
                                      context.read<WaterTrackingBloc>().add(ChangeThemeEvent(theme.name));
                                    }
                                  },
                                  child: Container(
                                    width: 42,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: theme.gradient,
                                      borderRadius: BorderRadius.circular(10),
                                      border: isSelected
                                          ? Border.all(color: Colors.white, width: 2)
                                          : null,
                                      boxShadow: isSelected
                                          ? const [
                                              BoxShadow(
                                                color: Color(0x4D000000),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: !isPro && theme.name != 'Aqua'
                                        ? const Center(child: Icon(Icons.lock_rounded, size: 12, color: Colors.white))
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Apple Health Sync
                      ListTile(
                        title: Text('Apple Health sync', style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                        subtitle: Text('Write water logs to Apple Health', style: AppTypography.caption(color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted)),
                        trailing: SipToggle(
                          value: settings.appleHealthSync,
                          isLockedPro: !isPro,
                          onChanged: (val) {
                            if (!isPro) {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
                            }
                          },
                        ),
                      ),
                      const Divider(),

                      // Export CSV
                      ListTile(
                        title: Text('Export CSV', style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isPro) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF26323F) : AppColors.lightSurface2,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text('PRO', style: AppTypography.badge(color: AppColors.aquaPrimary)),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Icon(Icons.download_rounded, size: 20, color: AppColors.aquaPrimary),
                          ],
                        ),
                        onTap: () {
                          if (!isPro) {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exporting CSV...')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Legal & Support Section
                Text('LEGAL & SUPPORT', style: AppTypography.sectionLabel(color: AppColors.lightInkMuted)),
                const SizedBox(height: 8),

                SipCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Privacy policy', style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.lightInkMuted),
                        onTap: () => launchUrl(Uri.parse('https://txlabz.com/privacy')),
                      ),
                      const Divider(),
                      ListTile(
                        title: Text('Terms of use', style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.lightInkMuted),
                        onTap: () => launchUrl(Uri.parse('https://txlabz.com/terms')),
                      ),
                      const Divider(),
                      ListTile(
                        title: Text('Restore purchases', style: AppTypography.body(color: isDark ? AppColors.darkInk : AppColors.lightInk)),
                        trailing: const Icon(Icons.restore_rounded, size: 18, color: AppColors.lightInkMuted),
                        onTap: () async {
                          final restored = await PurchaseService.restorePurchases();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(restored ? 'Purchases restored!' : 'No active subscriptions found.')),
                            );
                          }
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Reset all data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.delete_forever_rounded, size: 20, color: Colors.red),
                        onTap: () => _showResetConfirmDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
