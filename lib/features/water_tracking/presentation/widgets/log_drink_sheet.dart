import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';

class LogDrinkSheet extends StatefulWidget {
  final bool isPro;
  final String unit;
  final int initialAmount;
  final LinearGradient? customGradient;
  final Function(int amount, String drinkType) onAddDrink;

  const LogDrinkSheet({
    super.key,
    required this.isPro,
    required this.unit,
    this.initialAmount = 250,
    this.customGradient,
    required this.onAddDrink,
  });

  @override
  State<LogDrinkSheet> createState() => _LogDrinkSheetState();
}

class _LogDrinkSheetState extends State<LogDrinkSheet> {
  late int _amount;
  final String _selectedDrinkType = 'water';
  DateTime _selectedTime = DateTime.now();

  final List<int> _presets = [150, 250, 350, 500];

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
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
                // Drink Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Drink',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF0E1116),
                        ),
                      ),
                      const Spacer(),
                      // Active Water Chip
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF11324A) : const Color(0xFFE6F4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              size: 14,
                              color: isDark ? const Color(0xFF7CC8FF) : const Color(0xFF0A6FB8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Water',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF7CC8FF) : const Color(0xFF0A6FB8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // More PRO badge
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaywallPage()),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'More ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7684),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                                ),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF06283A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

          // Add Drink CTA Button
          InkWell(
            onTap: () {
              widget.onAddDrink(_amount, _selectedDrinkType);
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: widget.customGradient ??
                    const LinearGradient(
                      colors: [Color(0xFF1FA2FF), Color(0xFF12D8C8)],
                    ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x401FA2FF),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Add ${_amount}ml',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF06283A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
