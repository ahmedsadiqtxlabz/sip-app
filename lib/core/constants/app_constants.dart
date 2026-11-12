abstract class AppConstants {
  static const String appName = 'Sip';
  static const String appVersion = '1.0.0';

  static const String privacyPolicyUrl =
      'https://app.notion.com/p/PRIVACY-POLICY-410bb112c53b802bb192d2a1aea60d9b?source=copy_link';
  static const String termsOfUseUrl =
      'https://app.notion.com/p/TERMS-OF-USE-410bb112c53b80dbac44df886cec69b8?source=copy_link';
}

abstract class UnitConverter {
  static const double mlPerFlOz = 29.5735295625;

  static int mlToFlOz(num ml) => (ml / mlPerFlOz).round();
  static int flOzToMl(num flOz) => (flOz * mlPerFlOz).round();

  static int toDisplayAmount(num mlAmount, String unit) {
    if (unit == 'fl oz') {
      return mlToFlOz(mlAmount);
    }
    return mlAmount.round();
  }

  static String formatVolume(num mlAmount, String unit) {
    final amount = toDisplayAmount(mlAmount, unit);
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatted $unit';
  }
}

