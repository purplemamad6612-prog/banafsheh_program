import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    this.tint = const Color(0xFFF0EFFF),
    this.color = const Color(0xFF776EE8),
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color tint;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF8A93A5))),
                    const SizedBox(height: 8),
                    Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF202B43))),
                    const SizedBox(height: 4),
                    Text(caption, style: const TextStyle(fontSize: 9, color: Color(0xFF9AA3B2))),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: color, size: 19),
              ),
            ],
          ),
        ),
      );
}
