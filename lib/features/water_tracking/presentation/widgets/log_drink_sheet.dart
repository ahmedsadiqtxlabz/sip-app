import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sip_button.dart';
import '../../../../core/widgets/sip_chip.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';

class LogDrinkSheet extends StatefulWidget {
  final bool isPro;
  final String unit;
  final Function(int amount, String drinkType) onAddDrink;

  const LogDrinkSheet({
    super.key,
    required this.isPro,
    required this.unit,
    required this.onAddDrink,
  });

  @override
  State<LogDrinkSheet> createState() => _LogDrinkSheetState();
}

class _LogDrinkSheetState extends State<LogDrinkSheet> {
  int _amount = 250;
  String _selectedDrinkType = 'water';
  DateTime _selectedTime = DateTime.now();

  final List<int> _cupPresets = [150, 250, 350, 500];

  final List<Map<String, dynamic>> _drinkTypes = [
    {'id': 'water', 'label': 'Water', 'icon': Icons.water_drop_rounded, 'isPro': false},
    {'id': 'coffee', 'label': 'Coffee', 'icon': Icons.coffee_rounded, 'isPro': true},
    {'id': 'tea', 'label': 'Tea', 'icon': Icons.emoji_food_beverage_rounded, 'isPro': true},
    {'id': 'juice', 'label': 'Juice', 'icon': Icons.local_bar_rounded, 'isPro': true},
    {'id': 'soda', 'label': 'Soda', 'icon': Icons.local_drink_rounded, 'isPro': true},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Log a drink',
            style: AppTypography.title2(
              color: isDark ? AppColors.darkInk : AppColors.lightInk,
            ),
          ),
          const SizedBox(height: 20),

          // Stepper: - 250 +
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                color: AppColors.aquaPrimary,
                onPressed: () {
                  if (_amount > 50) {
                    setState(() => _amount -= 50);
                  }
                },
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  Text(
                    '$_amount',
                    style: AppTypography.heroNumber(
                      color: isDark ? AppColors.darkInk : AppColors.lightInk,
                    ).copyWith(fontSize: 48),
                  ),
                  Text(
                    widget.unit,
                    style: AppTypography.caption(
                      color: isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                color: AppColors.aquaPrimary,
                onPressed: () {
                  setState(() => _amount += 50);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Cup Presets Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _cupPresets.map((preset) {
              final isSelected = _amount == preset;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SipChip(
                  label: '$preset',
                  state: isSelected ? SipChipState.selected : SipChipState.defaultState,
                  onTap: () => setState(() => _amount = preset),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Drink Types Row
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'DRINK TYPE',
              style: AppTypography.sectionLabel(color: AppColors.lightInkMuted),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _drinkTypes.map((type) {
                final isSelected = _selectedDrinkType == type['id'];
                final isLocked = type['isPro'] && !widget.isPro;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SipChip(
                    label: type['label'],
                    icon: Icon(type['icon'], size: 16),
                    state: isSelected
                        ? SipChipState.selected
                        : (isLocked ? SipChipState.locked : SipChipState.defaultState),
                    showProBadge: type['isPro'] && !widget.isPro,
                    onTap: () {
                      if (isLocked) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PaywallPage()),
                        );
                      } else {
                        setState(() => _selectedDrinkType = type['id']);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Time Picker Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIME',
                style: AppTypography.sectionLabel(color: AppColors.lightInkMuted),
              ),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedTime),
                  );
                  if (time != null) {
                    final now = DateTime.now();
                    setState(() {
                      _selectedTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
                child: Row(
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(_selectedTime),
                      style: AppTypography.body(
                        color: isDark ? AppColors.darkLink : AppColors.lightLink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.aquaPrimary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Add Drink CTA
          SipButton(
            text: 'Add drink',
            onPressed: () {
              widget.onAddDrink(_amount, _selectedDrinkType);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

