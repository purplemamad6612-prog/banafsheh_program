import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../core/formatters.dart';
import '../models/app_enums.dart';
import '../models/finance.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/jalali_date_field.dart';
import '../widgets/page_components.dart';
import '../widgets/status_badge.dart';

class ChequesScreen extends ConsumerStatefulWidget {
  const ChequesScreen({super.key});
  @override
  ConsumerState<ChequesScreen> createState() => _ChequesScreenState();
}

class _ChequesScreenState extends ConsumerState<ChequesScreen> {
  String _type = 'همه چک‌ها';
  String _status = 'همه وضعیت‌ها';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(activeRoleProvider);
    final chequesAsync = ref.watch(recordsProvider('cheques'));
    final customersAsync = ref.watch(recordsProvider('customers'));
    final investorsAsync = ref.watch(recordsProvider('investors'));
    final cheques = (chequesAsync.asData?.value ?? const <JsonMap>[]).map(Cheque.fromMap).toList();
    final customers = customersAsync.asData?.value ?? const <JsonMap>[];
    final investors = investorsAsync.asData?.value ?? const <JsonMap>[];
    final filtered = cheques.where((cheque) {
      final query = _query.trim().toLowerCase();
      final typeOk = _type == 'همه چک‌ها' || (cheque.type == 'received' ? _type == 'دریافتی' : _type == 'پرداختی');
      final statusOk = _status == 'همه وضعیت‌ها' || _status == _statusLabel(cheque.status);
      return typeOk && statusOk && (query.isEmpty || cheque.number.toLowerCase().contains(query) || cheque.bank.toLowerCase().contains(query) || cheque.partyName.toLowerCase().contains(query));
    }).toList()..sort((a, b) => a.dueDateJalali.compareTo(b.dueDateJalali));
    final incoming = cheques.where((cheque) => cheque.type == 'received').fold<int>(0, (sum, cheque) => sum + cheque.amountToman);
    final outgoing = cheques.where((cheque) => cheque.type == 'issued').fold<int>(0, (sum, cheque) => sum + cheque.amountToman);
    final pending = cheques.where((cheque) => cheque.status == 'in_hand' || cheque.status == 'deposited').length;
    final canManage = role == AppRole.admin || role == AppRole.accountant;

    return RefreshIndicator(onRefresh: _reload, child: ListView(padding: const EdgeInsets.fromLTRB(22, 20, 22, 36), children: [
      PageHeading(title: 'مدیریت چک‌ها', subtitle: 'پیگیری چک‌های دریافتی و پرداختی، سررسید و وضعیت وصول', action: canManage ? FilledButton.icon(onPressed: () => _addCheque(context, customers, investors), icon: const Icon(Icons.add_rounded, size: 17), label: const Text('ثبت چک')) : null),
      if (role == AppRole.investor) const InfoPanel(icon: Icons.shield_outlined, text: 'فقط چک‌های متصل به حساب سرمایه‌گذاری شما نمایش داده می‌شود.'),
      if (role == AppRole.accountant) const InfoPanel(icon: Icons.lock_outline_rounded, text: 'چک‌های مشتری و تأمین‌کننده در این صفحه دیده می‌شوند؛ قیمت خرید کالا یا حاشیه سود در دسترس نیست.'),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final stats = [
          _ChequeStat(label: 'چک دریافتی', value: formatToman(incoming), icon: Icons.call_received_rounded, color: const Color(0xFF25866E)),
          _ChequeStat(label: 'چک پرداختی', value: formatToman(outgoing), icon: Icons.call_made_rounded, color: const Color(0xFFC47C34)),
          _ChequeStat(label: 'در جریان', value: persianDigits(pending), icon: Icons.schedule_rounded, color: pagePurple),
        ];
        if (constraints.maxWidth < 600) return Column(children: stats.map((stat) => Padding(padding: const EdgeInsets.only(bottom: 8), child: stat)).toList());
        return Row(children: [for (var index = 0; index < stats.length; index++) Expanded(child: Padding(padding: EdgeInsetsDirectional.only(end: index == stats.length - 1 ? 0 : 9), child: stats[index]))]);
      }),
      const SizedBox(height: 11),
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 9, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(width: 240, child: TextField(onChanged: (value) => setState(() => _query = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'شماره چک، بانک یا طرف حساب', isDense: true))),
        SizedBox(width: 145, child: DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'نوع چک', isDense: true), items: const ['همه چک‌ها', 'دریافتی', 'پرداختی'].map((value) => DropdownMenuItem(value: value, child: Text(value, style: const TextStyle(fontSize: 9)))).toList(), onChanged: (value) => setState(() => _type = value ?? 'همه چک‌ها'))),
        SizedBox(width: 165, child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'وضعیت', isDense: true), items: const ['همه وضعیت‌ها', 'در دست', 'واگذار به بانک', 'وصول‌شده', 'برگشتی', 'واگذار شده'].map((value) => DropdownMenuItem(value: value, child: Text(value, style: const TextStyle(fontSize: 9)))).toList(), onChanged: (value) => setState(() => _status = value ?? 'همه وضعیت‌ها'))),
        Text('${persianDigits(filtered.length)} فقره', style: const TextStyle(fontSize: 9, color: Color(0xFF929CAF))),
      ]))),
      const SizedBox(height: 8),
      LoadingOrError(loading: chequesAsync.isLoading, error: chequesAsync.error, onRetry: _reload),
      if (!chequesAsync.isLoading && filtered.isEmpty) const EmptyPanel(title: 'چکی مطابق فیلتر وجود ندارد.', icon: Icons.payments_outlined),
      for (final cheque in filtered) _ChequeCard(cheque: cheque, canManage: canManage, onStatus: (status) => _changeStatus(cheque, status)),
    ]));
  }

  Future<void> _addCheque(BuildContext context, List<JsonMap> customers, List<JsonMap> investors) async {
    final number = TextEditingController(), bank = TextEditingController(), amount = TextEditingController(), notes = TextEditingController();
    String type = 'received', status = 'in_hand', partyId = '', investorId = '';
    String due = formatJalaliDate(Jalali.now());
    var busy = false;
    final key = GlobalKey<FormState>();
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: const Text('ثبت چک دریافتی یا پرداختی', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 500, child: SingleChildScrollView(child: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              SizedBox(width: 180, child: DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'نوع چک'), items: const [DropdownMenuItem(value: 'received', child: Text('دریافتی')), DropdownMenuItem(value: 'issued', child: Text('پرداختی'))], onChanged: (value) => setDialog(() { type = value ?? type; partyId = ''; investorId = ''; }))),
              SizedBox(width: 180, child: DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'وضعیت اولیه'), items: const [DropdownMenuItem(value: 'in_hand', child: Text('در دست')), DropdownMenuItem(value: 'deposited', child: Text('واگذار به بانک'))], onChanged: (value) => setDialog(() => status = value ?? status))),
            ]),
            TextFormField(controller: number, decoration: const InputDecoration(labelText: 'شماره چک'), validator: (value) => value == null || value.trim().isEmpty ? 'شماره چک الزامی است.' : null),
            TextFormField(controller: bank, decoration: const InputDecoration(labelText: 'بانک'), validator: (value) => value == null || value.trim().isEmpty ? 'نام بانک الزامی است.' : null),
            TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ (تومان)'), validator: (value) => _money(value) <= 0 ? 'مبلغ معتبر وارد کنید.' : null),
            const SizedBox(height: 8),
            JalaliDateField(initialDate: Jalali.now(), label: 'تاریخ سررسید شمسی', onChanged: (value) => due = formatJalaliDate(value)),
            if (customers.isNotEmpty && type == 'received') DropdownButtonFormField<String>(value: partyId.isEmpty ? null : partyId, decoration: const InputDecoration(labelText: 'مشتری مرتبط (اختیاری)'), items: customers.map((row) => DropdownMenuItem(value: asString(row['id']), child: Text(asString(row['name'])))).toList(), onChanged: (value) => setDialog(() => partyId = value ?? '')),
            if (investors.isNotEmpty) DropdownButtonFormField<String>(value: investorId.isEmpty ? null : investorId, decoration: const InputDecoration(labelText: 'سرمایه‌گذار مرتبط (اختیاری)'), items: investors.map((row) => DropdownMenuItem(value: asString(row['id']), child: Text(asString(row['name'])))).toList(), onChanged: (value) => setDialog(() => investorId = value ?? '')),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'یادداشت')),
          ])))),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            if (!(key.currentState?.validate() ?? false)) return;
            final value = _money(amount.text);
            setDialog(() => busy = true);
            final body = <String, dynamic>{'cheque_type': type, 'cheque_number': number.text.trim(), 'bank_name': bank.text.trim(), 'amount': value, 'due_date_jalali': due, 'status': status, 'notes': notes.text.trim()};
            if (partyId.isNotEmpty) body['related_party_id'] = partyId;
            if (investorId.isNotEmpty) body['investor_id'] = investorId;
            try {
              await ref.read(businessRepositoryProvider).saveRecord('cheques', body);
              if (context.mounted) Navigator.pop(dialogContext);
              _toast('چک ثبت شد.'); _reload();
            } catch (error) { _toast('ثبت چک ناموفق بود: $error'); setDialog(() => busy = false); }
          }, child: busy ? const CircularProgressIndicator() : const Text('ذخیره چک'))],
        )));
    number.dispose(); bank.dispose(); amount.dispose(); notes.dispose();
  }

  Future<void> _changeStatus(Cheque cheque, String status) async {
    try {
      await ref.read(businessRepositoryProvider).updateRecord('cheques', cheque.id, {'status': status});
      _toast('وضعیت چک به «${_statusLabel(status)}» تغییر کرد.'); _reload();
    } catch (error) { _toast('تغییر وضعیت ناموفق بود: $error'); }
  }

  int _money(String? value) { var text = value ?? ''; for (var i = 0; i < 10; i++) text = text.replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i').replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i'); return int.tryParse(text.replaceAll(',', '').replaceAll('٬', '')) ?? 0; }
  String _statusLabel(String value) => switch (value) { 'in_hand' => 'در دست', 'deposited' => 'واگذار به بانک', 'cleared' => 'وصول‌شده', 'bounced' => 'برگشتی', 'transferred' => 'واگذار شده', _ => value };
  Future<void> _reload() async { for (final collection in ['cheques', 'customers', 'investors']) ref.invalidate(recordsProvider(collection)); await Future<void>.delayed(const Duration(milliseconds: 140)); }
  void _toast(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
}

class _ChequeStat extends StatelessWidget {
  const _ChequeStat({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [CircleAvatar(radius: 17, backgroundColor: color.withOpacity(.1), child: Icon(icon, size: 16, color: color)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF))), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))]))])));
}

class _ChequeCard extends StatelessWidget {
  const _ChequeCard({required this.cheque, required this.canManage, required this.onStatus});
  final Cheque cheque;
  final bool canManage;
  final ValueChanged<String> onStatus;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), child: Row(children: [
        CircleAvatar(radius: 19, backgroundColor: cheque.type == 'received' ? const Color(0xFFE9F8F4) : const Color(0xFFFFF3E8), child: Icon(cheque.type == 'received' ? Icons.call_received_rounded : Icons.call_made_rounded, size: 17, color: cheque.type == 'received' ? const Color(0xFF25866E) : const Color(0xFFC47C34))),
        const SizedBox(width: 9),
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('چک ${cheque.type == 'received' ? 'دریافتی' : 'پرداختی'} · ${cheque.number}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)), Text('${cheque.bank} · ${cheque.partyName.isEmpty ? 'طرف حساب ثبت نشده' : cheque.partyName}', style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF)))])),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('سررسید', style: TextStyle(fontSize: 8, color: Color(0xFF929CAF))), Text(cheque.dueDateJalali, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700))])),
        Expanded(child: Text(formatToman(cheque.amountToman), textAlign: TextAlign.end, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
        const SizedBox(width: 9),
        if (canManage) PopupMenuButton<String>(tooltip: 'تغییر وضعیت', onSelected: onStatus, itemBuilder: (_) => const [PopupMenuItem(value: 'in_hand', child: Text('در دست')), PopupMenuItem(value: 'deposited', child: Text('واگذار به بانک')), PopupMenuItem(value: 'cleared', child: Text('وصول‌شده')), PopupMenuItem(value: 'bounced', child: Text('برگشتی')), PopupMenuItem(value: 'transferred', child: Text('واگذار شده'))], child: StatusBadge(cheque.status)) else StatusBadge(cheque.status),
      ])));
}
