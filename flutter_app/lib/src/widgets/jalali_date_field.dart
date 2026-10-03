import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../core/formatters.dart';
import '../core/jalali_date_picker.dart';

class JalaliDateField extends StatefulWidget {
  const JalaliDateField({
    super.key,
    this.initialDate,
    this.label = 'تاریخ شمسی',
    this.onChanged,
  });

  final Jalali? initialDate;
  final String label;
  final ValueChanged<Jalali>? onChanged;

  @override
  State<JalaliDateField> createState() => _JalaliDateFieldState();
}

class _JalaliDateFieldState extends State<JalaliDateField> {
  late Jalali _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? Jalali.now();
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () async {
          final selected = await showJalaliDatePicker(context, initialDate: _date);
          if (selected == null) return;
          setState(() => _date = selected);
          widget.onChanged?.call(selected);
        },
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(labelText: widget.label, prefixIcon: const Icon(Icons.calendar_month_outlined)),
          child: Text(
            '${persianDigits(_date.year)}/${persianDigits(_date.month.toString().padLeft(2, '0'))}/${persianDigits(_date.day.toString().padLeft(2, '0'))}',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
          ),
        ),
      );
}
