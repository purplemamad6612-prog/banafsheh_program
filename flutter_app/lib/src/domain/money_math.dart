/// Exact integer-Toman arithmetic helpers.
/// Quantities use thousandths and unit conversions use ten-thousandths so price
/// calculations never rely on binary floating-point currency values.
class UnitSnapshot {
  const UnitSnapshot({required this.unitName, required this.factorTenThousand, required this.version});

  final String unitName;
  final int factorTenThousand;
  final int version;

  int quantityInBaseThousandths(int quantityThousandths) =>
      (quantityThousandths * factorTenThousand + 5000) ~/ 10000;
}

class TomanMath {
  const TomanMath._();

  static int roundToRule(int value, String rule) {
    final step = switch (rule) {
      'nearest_5000' => 5000,
      'nearest_10000' => 10000,
      'none' => 1,
      _ => 1000,
    };
    return ((value + step ~/ 2) ~/ step) * step;
  }

  /// Multiplies a base-unit integer price by unit conversion and quantity.
  static int lineTotal({
    required int basePriceToman,
    required int quantityThousandths,
    required UnitSnapshot unit,
    String roundingRule = 'nearest_1000',
  }) {
    final numerator = BigInt.from(basePriceToman) *
        BigInt.from(quantityThousandths) *
        BigInt.from(unit.factorTenThousand);
    const denominator = 10000000;
    final exact = ((numerator + BigInt.from(denominator ~/ 2)) ~/ BigInt.from(denominator)).toInt();
    return roundToRule(exact, roundingRule);
  }

  static int applyPercent(int amountToman, int percentHundredths) {
    // percentHundredths: 125 means 1.25 percent.
    final amount = BigInt.from(amountToman) * BigInt.from(10000 + percentHundredths);
    return ((amount + BigInt.from(5000)) ~/ BigInt.from(10000)).toInt();
  }
}
