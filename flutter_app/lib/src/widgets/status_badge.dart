import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.label});
  final String status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' || 'cleared' || 'settled' || 'active' => const Color(0xFF188D70),
      'bounced' || 'cancelled' => const Color(0xFFC54D60),
      'draft' || 'in_hand' || 'open' || 'pending' => const Color(0xFFCB8237),
      _ => const Color(0xFF6F7890),
    };
    final displayLabel = label ?? switch (status) {
      'confirmed' => 'تأیید شده',
      'draft' => 'پیش‌نویس',
      'cancelled' => 'لغو شده',
      'in_hand' => 'در دست',
      'deposited' => 'واگذار به بانک',
      'cleared' => 'وصول شده',
      'bounced' => 'برگشتی',
      'transferred' => 'واگذار شده',
      'open' => 'باز',
      'settled' => 'تسویه شده',
      'pending' => 'در انتظار',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
      child: Text(displayLabel, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
