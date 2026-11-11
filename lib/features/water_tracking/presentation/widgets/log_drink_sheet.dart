import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';

class LogDrinkSheet extends StatefulWidget {
  final bool isPro;
  final String unit;
  final int initialAmount;
  final String initialDrinkType;
  final LinearGradient? customGradient;
  final Function(int amount, String drinkType) onAddDrink;

  const LogDrinkSheet({
    super.key,
    required this.isPro,
    required this.unit,
    this.initialAmount = 250,
    this.initialDrinkType = 'water',
    this.customGradient,
    required this.onAddDrink,
  });

  @override
  State<LogDrinkSheet> createState() => _LogDrinkSheetState();
}

class _LogDrinkSheetState extends State<LogDrinkSheet> {
  late int _amount;
  late String _selectedDrinkType;
  bool _isSuccess = false;
  DateTime _selectedTime = DateTime.now();

  final List<int> _presets = [150, 250, 350, 500];

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
    _selectedDrinkType = widget.initialDrinkType;
  }

  Widget _buildDrinkChip(
    String typeKey,
    String label,
    IconData icon,
    bool isProFeature,
    bool isDark,
  ) {
    final isSelected = _selectedDrinkType == typeKey;
    final isLocked = isProFeature && !widget.isPro;

    return InkWell(
      onTap: () {
        if (isLocked) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallPage()),
          );
        } else {
          setState(() => _selectedDrinkType = typeKey);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF11324A) : const Color(0xFFE6F4FF))
              : (isDark ? const Color(0xFF1A222C) : const Color(0xFFF3F6F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1FA2FF)
                : (isDark ? const Color(0xFF263140) : const Color(0xFFE1E8EF)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? const Color(0xFF1FA2FF)
                  : (isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? const Color(0xFF7CC8FF) : const Color(0xFF0A6FB8))
                    : (isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116)),
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                  ),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF06283A),
                  ),
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E0E1116),
            blurRadius: 40,
            offset: Offset(0, -12),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E3846) : const Color(0xFFCBD8E2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),

          // Header: Log a drink + Close (X) button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log a drink',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27313C) : const Color(0xFFEEF3F7),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF4F5B69),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stepper: Minus, Amount / unit, Plus
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Minus button
              InkWell(
                onTap: () {
                  if (_amount > 50) {
                    setState(() => _amount -= 50);
                  }
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27313C) : const Color(0xFFEEF3F7),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '−',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Center amount display
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 140),
                child: Column(
                  children: [
                    Text(
                      '$_amount',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2.0,
                        height: 1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.unit,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Plus button
              InkWell(
                onTap: () {
                  if (_amount < 2000) {
                    setState(() => _amount += 50);
                  }
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x331FA2FF),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF06283A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Presets Row (150 ml, 250 ml, 350 ml, 500 ml)
          Row(
            children: _presets.map((preset) {
              final isSelected = _amount == preset;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _amount = preset),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF11324A) : const Color(0xFFE6F4FF))
                            : (isDark ? const Color(0xFF1C232D) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1FA2FF)
                              : (isDark ? const Color(0xFF263140) : const Color(0xFFE1E8EF)),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$preset ml',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? (isDark ? const Color(0xFF7CC8FF) : const Color(0xFF0A6FB8))
                              : (isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116)),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Card: Drink Type & Time
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C232D) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF263140) : const Color(0xFFEEF3F7),
              ),
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
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              children: [
                // Beverage Type Selector Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Beverage',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Row(
                    children: [
                      _buildDrinkChip('water', 'Water', Icons.water_drop_rounded, false, isDark),
                      const SizedBox(width: 8),
                      _buildDrinkChip('coffee', 'Coffee', Icons.coffee_rounded, true, isDark),
                      const SizedBox(width: 8),
                      _buildDrinkChip('tea', 'Tea', Icons.emoji_food_beverage_rounded, true, isDark),
                      const SizedBox(width: 8),
                      _buildDrinkChip('juice', 'Juice', Icons.local_bar_rounded, true, isDark),
                      const SizedBox(width: 8),
                      _buildDrinkChip('other', 'Other', Icons.more_horiz_rounded, true, isDark),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? const Color(0xFF263140) : const Color(0xFFEEF3F7),
                ),
                // Time Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Time',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
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
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('hh:mm a').format(_selectedTime),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Add Drink CTA Button with Success State
          InkWell(
            onTap: () async {
              if (_isSuccess) return;
              HapticFeedback.mediumImpact();
              setState(() => _isSuccess = true);
              widget.onAddDrink(_amount, _selectedDrinkType);
              final navigator = Navigator.of(context);
              await Future.delayed(const Duration(milliseconds: 350));
              if (!mounted) return;
              navigator.pop();
            },
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: _isSuccess
                    ? const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                      )
                    : (widget.customGradient ??
                        const LinearGradient(
                          colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                        )),
                boxShadow: [
                  BoxShadow(
                    color: _isSuccess ? const Color(0x4000C853) : const Color(0x401FA2FF),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSuccess) ...[
                    const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Added!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ] else
                    Text(
                      'Add $_amount ${widget.unit}',
                      style: const TextStyle(
                        fontSize: 17,
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
    );
  }
}
