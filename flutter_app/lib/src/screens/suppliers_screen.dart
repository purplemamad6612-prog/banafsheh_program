import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/page_components.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});
  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recordsProvider('suppliers'));
    final rows = async.asData?.value ?? const <JsonMap>[];
    final filtered = rows.where((row) {
      final query = _query.trim().toLowerCase();
      return query.isEmpty || asString(row['name']).toLowerCase().contains(query) || asString(row['phone']).contains(query);
    }).toList();
    return RefreshIndicator(onRefresh: _reload, child: ListView(padding: const EdgeInsets.fromLTRB(22, 20, 22, 35), children: [
      PageHeading(title: 'تأمین‌کنندگان', subtitle: 'دفتر تماس تأمین‌کننده‌ها و سرنخ خرید', action: FilledButton.icon(onPressed: () => _addSupplier(context), icon: const Icon(Icons.add_rounded, size: 17), label: const Text('تأمین‌کننده جدید'))),
      const InfoPanel(icon: Icons.admin_panel_settings_outlined, text: 'قیمت تمام‌شده و جزئیات هزینه در مجموعه‌های خصوصی مدیر نگهداری می‌شوند؛ این فهرست فقط اطلاعات تماس و توضیحات را نشان می‌دهد.'),
      const SizedBox(height: 12),
      Wrap(spacing: 9, runSpacing: 9, children: [
        _SupplierStat(label: 'تأمین‌کننده فعال', value: persianDigits(rows.length), icon: Icons.local_shipping_outlined),
        _SupplierStat(label: 'جستجو شده', value: persianDigits(filtered.length), icon: Icons.search_rounded),
      ]),
      const SizedBox(height: 11),
      Card(child: Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (value) => setState(() => _query = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'نام یا شماره تماس', isDense: true)))),
      const SizedBox(height: 8),
      LoadingOrError(loading: async.isLoading, error: async.error, onRetry: _reload),
      if (!async.isLoading && filtered.isEmpty) const EmptyPanel(title: 'تأمین‌کننده‌ای برای نمایش نیست.', icon: Icons.local_shipping_outlined),
      LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth > 950 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
        final gap = 10.0;
        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final row in filtered) SizedBox(width: width, child: _SupplierCard(row: row)),
        ]);
      }),
    ]));
  }

  Future<void> _addSupplier(BuildContext context) async {
    final name = TextEditingController(), phone = TextEditingController(), address = TextEditingController(), notes = TextEditingController();
    var busy = false;
    final key = GlobalKey<FormState>();
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: const Text('افزودن تأمین‌کننده', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 410, child: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'نام مجموعه'), validator: (value) => value == null || value.trim().isEmpty ? 'نام الزامی است.' : null),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'تلفن تماس')),
            TextField(controller: address, decoration: const InputDecoration(labelText: 'نشانی')),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'توضیحات تأمین'), maxLines: 3),
          ])))),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            if (!(key.currentState?.validate() ?? false)) return;
            setDialog(() => busy = true);
            try {
              await ref.read(businessRepositoryProvider).saveRecord('suppliers', {'name': name.text.trim(), 'phone': phone.text.trim(), 'address': address.text.trim(), 'notes': notes.text.trim(), 'is_active': true});
              if (context.mounted) Navigator.pop(dialogContext);
              _toast('تأمین‌کننده ثبت شد.'); _reload();
            } catch (error) { _toast('ثبت تأمین‌کننده ناموفق بود: $error'); setDialog(() => busy = false); }
          }, child: busy ? const CircularProgressIndicator() : const Text('ذخیره'))],
        )));
    name.dispose(); phone.dispose(); address.dispose(); notes.dispose();
  }

  Future<void> _reload() async { ref.invalidate(recordsProvider('suppliers')); await Future<void>.delayed(const Duration(milliseconds: 140)); }
  void _toast(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
}

class _SupplierStat extends StatelessWidget {
  const _SupplierStat({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: 190, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [CircleAvatar(radius: 16, backgroundColor: const Color(0xFFF0EFFF), child: Icon(icon, size: 15, color: pagePurple)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF))), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))]))]))));
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.row});
  final JsonMap row;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [CircleAvatar(radius: 18, backgroundColor: const Color(0xFFE9F8F4), child: const Icon(Icons.local_shipping_outlined, size: 17, color: Color(0xFF25866E))), const SizedBox(width: 9), Expanded(child: Text(asString(row['name']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))), const Icon(Icons.more_horiz_rounded, color: Color(0xFF929CAF))]),
        const Divider(height: 20),
        _SupplierLine(icon: Icons.phone_outlined, text: asString(row['phone'], fallback: 'تلفن ثبت نشده')),
        const SizedBox(height: 7), _SupplierLine(icon: Icons.location_on_outlined, text: asString(row['address'], fallback: 'نشانی ثبت نشده')),
        if (asString(row['notes']).isNotEmpty) ...[const SizedBox(height: 9), Text(asString(row['notes']), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF758097)))],
      ])));
}

class _SupplierLine extends StatelessWidget {
  const _SupplierLine({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 14, color: const Color(0xFF8E97A8)), const SizedBox(width: 7), Expanded(child: Text(text, style: const TextStyle(fontSize: 9, color: Color(0xFF66718A))))]);
}
