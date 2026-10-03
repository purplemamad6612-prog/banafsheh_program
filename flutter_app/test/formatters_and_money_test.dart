import 'package:flutter_test/flutter_test.dart';
import 'package:banafsheh_client/src/core/formatters.dart';
import 'package:banafsheh_client/src/domain/money_math.dart';

void main() {
  group('Persian formatters', () {
    test('formats integer Toman with Persian digits and separators', () {
      expect(formatToman(123456789), '۱۲۳٬۴۵۶٬۷۸۹ تومان');
      expect(formatToman(-2500, withUnit: false), '−۲٬۵۰۰');
    });

    test('converts ASCII digits to Persian digits', () {
      expect(persianDigits('1405/07/12'), '۱۴۰۵/۰۷/۱۲');
    });
  });

  group('exact Toman arithmetic', () {
    const unit = UnitSnapshot(unitName: 'بسته', factorTenThousand: 250000, version: 2);

    test('keeps unit conversion and quantity in integer arithmetic', () {
      expect(unit.quantityInBaseThousandths(2000), 50000);
      expect(TomanMath.lineTotal(basePriceToman: 1770000, quantityThousandths: 2000, unit: unit), 88500000);
    });

    test('applies basis-point percent without floating point money', () {
      expect(TomanMath.applyPercent(100000, 250), 102500);
      expect(TomanMath.roundToRule(102500, 'nearest_5000'), 105000);
    });
  });
}
