import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'formatters.dart';

Future<Jalali?> showJalaliDatePicker(
  BuildContext context, {
  Jalali? initialDate,
}) {
  final start = initialDate ?? Jalali.now();
  var year = start.year;
  var month = start.month;
  var day = start.day;

  return showDialog<Jalali>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final first = Jalali(year, month, 1);
        final daysInMonth = first.monthLength;
        final offset = first.weekDay - 1;
        final years = List<int>.generate(11, (index) => start.year - 5 + index);
        return AlertDialog(
          title: const Text('انتخاب تاریخ شمسی', textAlign: TextAlign.right),
          content: SizedBox(
            width: 330,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: month,
                        isExpanded: true,
                        items: List<DropdownMenuItem<int>>.generate(
                          12,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(jalaliMonthNames[index]),
                          ),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            month = value;
                            if (day > Jalali(year, month, 1).monthLength) {
                              day = Jalali(year, month, 1).monthLength;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: years.contains(year) ? year : start.year,
                      items: years
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(persianDigits(value)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          year = value;
                          if (day > Jalali(year, month, 1).monthLength) {
                            day = Jalali(year, month, 1).monthLength;
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج']
                      .map((label) => Expanded(
                            child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF7A8294)))),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 5),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 42,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemBuilder: (context, index) {
                    final value = index - offset + 1;
                    if (value < 1 || value > daysInMonth) return const SizedBox.shrink();
                    final selected = day == value;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setDialogState(() => day = value),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? Theme.of(context).colorScheme.primary : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          persianDigits(value),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? Colors.white : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('انصراف')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, Jalali(year, month, day)),
              child: const Text('انتخاب'),
            ),
          ],
        );
      },
    ),
  );
}
