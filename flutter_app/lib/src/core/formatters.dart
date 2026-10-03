import 'package:shamsi_date/shamsi_date.dart';

const _faDigits = '۰۱۲۳۴۵۶۷۸۹';
const jalaliMonthNames = <String>[
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
];

String persianDigits(Object? value) => (value ?? '').toString().replaceAllMapped(
      RegExp(r'\d'),
      (match) => _faDigits[int.parse(match[0]!)],
    );

String formatToman(int value, {bool withUnit = true}) {
  final negative = value < 0;
  final raw = value.abs().toString();
  final grouped = raw.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '٬');
  final formatted = '${negative ? '−' : ''}${persianDigits(grouped)}';
  return withUnit ? '$formatted تومان' : formatted;
}

String formatJalaliDate(Jalali date) =>
    '${persianDigits(date.year)}/${persianDigits(date.month.toString().padLeft(2, '0'))}/${persianDigits(date.day.toString().padLeft(2, '0'))}';

String formatJalaliLong(Jalali date) =>
    '${date.formatter.wN}، ${persianDigits(date.day)} ${jalaliMonthNames[date.month - 1]} ${persianDigits(date.year)}';
