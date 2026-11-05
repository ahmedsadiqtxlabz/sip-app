import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SipToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isLockedPro;

  const SipToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.isLockedPro = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color trackColor;
    if (isLockedPro) {
      trackColor = isDark ? const Color(0xFF222E3A) : const Color(0xFFD5DEE6);
    } else if (value) {
      trackColor = AppColors.aquaPrimary;
    } else {
      trackColor = isDark ? const Color(0xFF222E3A) : const Color(0xFFD5DEE6);
    }

    return GestureDetector(
      onTap: () {
        if (onChanged != null) {
          onChanged!(!value);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
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
          child: isLockedPro
              ? const Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: Color(0xFF6B7684),
                )
              : null,
        ),
      ),
    );
  }
}

