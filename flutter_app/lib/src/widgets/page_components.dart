import 'package:flutter/material.dart';

const pageInk = Color(0xFF202B43);
const pagePurple = Color(0xFF776EE8);

class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, required this.subtitle, this.action, this.trailing});
  final String title;
  final String subtitle;
  final Widget? action;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: pageInk)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF929CAF))),
          ])),
          if (trailing != null) trailing!,
          if (action != null) ...[const SizedBox(width: 8), action!],
        ]),
      );
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.icon, required this.text, this.color = const Color(0xFFF0EFFF)});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(11)),
        child: Row(children: [Icon(icon, size: 16, color: pagePurple), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 9, color: Color(0xFF5F6580))))]),
      );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({super.key, required this.title, this.icon = Icons.inbox_outlined, this.action});
  final String title;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 32, color: const Color(0xFFA9B0BF)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF929CAF))),
          if (action != null) ...[const SizedBox(height: 10), action!],
        ]),
      );
}

class LoadingOrError extends StatelessWidget {
  const LoadingOrError({super.key, required this.loading, this.error, this.onRetry});
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const LinearProgressIndicator(minHeight: 2);
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFB84B43), size: 17),
            const SizedBox(width: 8),
            Expanded(child: Text('دریافت اطلاعات با خطا روبه‌رو شد: $error', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF8F413B)))),
            if (onRetry != null) IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 17)),
          ]),
        ),
      ),
    );
  }
}

class FormCard extends StatelessWidget {
  const FormCard({super.key, required this.title, required this.child, this.icon = Icons.tune_rounded});
  final String title;
  final Widget child;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Icon(icon, color: pagePurple, size: 17), const SizedBox(width: 7), Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: pageInk))]),
        const SizedBox(height: 13),
        child,
      ])));
}
