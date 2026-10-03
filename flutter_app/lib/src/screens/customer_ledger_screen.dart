import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../models/app_enums.dart';
import '../models/finance.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/page_components.dart';

class CustomerLedgerScreen extends ConsumerStatefulWidget {
  const CustomerLedgerScreen({super.key});
  @override
  ConsumerState<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends ConsumerState<CustomerLedgerScreen> {
  String _selectedCustomerId = '';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(activeRoleProvider);
    final customersAsync = ref.watch(recordsProvider('customers'));
    final invoicesAsync = ref.watch(recordsProvider('invoices'));
    final paymentsAsync = ref.watch(recordsProvider('payments'));
    final chequesAsync = ref.watch(recordsProvider('cheques'));
    final customers = (customersAsync.asData?.value ?? const <JsonMap>[]).map(Customer.fromMap).toList();
    final user = ref.watch(sessionProvider);
    final roleCustomerId = role == AppRole.customer ? (user?.customerId ?? '') : '';
    final selected = customers.where((customer) => customer.id == (roleCustomerId.isNotEmpty ? roleCustomerId : _selectedCustomerId)).firstOrNull ?? (roleCustomerId.isEmpty && customers.isNotEmpty ? customers.first : null);
    final invoiceRows = invoicesAsync.asData?.value ?? const <JsonMap>[];
    final paymentRows = paymentsAsync.asData?.value ?? const <JsonMap>[];
    final chequeRows = chequesAsync.asData?.value ?? const <JsonMap>[];
    final visibleCustomers = customers.where((customer) => customer.name.toLowerCase().contains(_search.toLowerCase()) || customer.code.toLowerCase().contains(_search.toLowerCase()) || customer.phone.contains(_search)).toList();
    final relevantInvoices = selected == null ? <Invoice>[] : invoiceRows.map(Invoice.fromMap).where((row) => row.customerId == selected.id && (row.type == 'sale' || row.type == 'sale_return') && row.status == 'confirmed').toList();
    final relevantPayments = selected == null ? <JsonMap>[] : paymentRows.where((row) => asString(row['customer_id']) == selected.id).toList();
    final relevantCheques = selected == null ? <JsonMap>[] : chequeRows.where((row) => asString(row['related_party_id'] ?? row['customer_id']) == selected.id).toList();
    final entries = <_LedgerRow>[];
    for (final invoice in relevantInvoices) {
      entries.add(_LedgerRow(date: invoice.dateJalali, kind: invoice.type == 'sale_return' ? 'برگشت فروش' : invoice.type == 'quote' ? 'پیش‌فاکتور' : 'فاکتور فروش', reference: invoice.number, debit: invoice.type == 'sale_return' ? 0 : invoice.totalToman, credit: invoice.type == 'sale_return' ? invoice.totalToman : 0));
    }
    for (final payment in relevantPayments) {
      entries.add(_LedgerRow(date: asString(payment['payment_date_jalali']), kind: 'دریافت ${_paymentLabel(asString(payment['payment_type']))}', reference: asString(payment['reference_number'], fallback: 'دریافت'), debit: 0, credit: asInt(payment['amount'])));
    }
    entries.sort((a, b) => a.date.compareTo(b.date));
    final movementNet = entries.fold<int>(0, (sum, row) => sum + row.debit - row.credit);
    final opening = selected == null ? 0 : selected.balanceToman - movementNet;
    final ledgerRows = <Widget>[];
    var rowBalance = opening;
    for (final entry in entries) {
      rowBalance += entry.debit - entry.credit;
      ledgerRows.add(_LedgerTableRow(date: entry.date, description: entry.kind, reference: entry.reference, debit: entry.debit, credit: entry.credit, balance: rowBalance, header: false));
    }
    final isLoading = customersAsync.isLoading || invoicesAsync.isLoading || paymentsAsync.isLoading;
    final canCreateCustomer = role == AppRole.admin || role == AppRole.accountant || role == AppRole.sales;

    return RefreshIndicator(onRefresh: _reload, child: ListView(padding: const EdgeInsets.fromLTRB(22, 20, 22, 36), children: [
      PageHeading(
        title: role == AppRole.customer ? 'حساب و گردش شما' : 'مشتریان و دفتر حساب',
        subtitle: 'مانده بدهکار/بستانکار، اسناد فروش و دریافت‌های ثبت‌شده',
        action: canCreateCustomer ? FilledButton.icon(onPressed: () => _addCustomer(context), icon: const Icon(Icons.person_add_alt_1_rounded, size: 17), label: const Text('مشتری جدید')) : null,
      ),
      if (role == AppRole.customer) const InfoPanel(icon: Icons.shield_outlined, text: 'این صفحه فقط گردش حساب و مانده متعلق به حساب کاربری شما را نشان می‌دهد.'),
      if (role == AppRole.accountant) const InfoPanel(icon: Icons.visibility_off_outlined, text: 'اطلاعات دفتر حساب و دریافت‌ها نمایش داده می‌شود؛ هزینه خرید و حاشیه سود محصول در این نقش قابل مشاهده نیست.'),
      const SizedBox(height: 12),
      if (role != AppRole.customer) Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Expanded(child: TextField(onChanged: (value) => setState(() => _search = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'جستجوی مشتری', isDense: true))),
        const SizedBox(width: 9),
        Expanded(child: DropdownButtonFormField<String>(value: selected != null && visibleCustomers.any((customer) => customer.id == selected.id) ? selected.id : null, decoration: const InputDecoration(labelText: 'مشتری انتخاب‌شده', isDense: true), items: visibleCustomers.map((customer) => DropdownMenuItem(value: customer.id, child: Text('${customer.code} · ${customer.name}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9)))).toList(), onChanged: (value) => setState(() => _selectedCustomerId = value ?? ''))),
      ]))),
      const SizedBox(height: 10),
      LoadingOrError(loading: isLoading, error: customersAsync.hasError ? customersAsync.error : invoicesAsync.hasError ? invoicesAsync.error : paymentsAsync.error, onRetry: _reload),
      if (selected == null && !customersAsync.isLoading) const EmptyPanel(title: 'مشتری مجازی برای نمایش وجود ندارد.', icon: Icons.groups_outlined),
      if (selected != null) ...[
        _CustomerProfile(customer: selected, invoices: relevantInvoices.length, cheques: relevantCheques.length),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 650;
          final cards = [
            _BalanceCard(title: 'مانده فعلی حساب', value: formatToman(selected.balanceToman), icon: Icons.account_balance_wallet_outlined, tint: const Color(0xFFF0EFFF)),
            _BalanceCard(title: 'مانده افتتاحیه محاسبه‌شده', value: formatToman(opening), icon: Icons.history_rounded, tint: const Color(0xFFEDF4FF)),
            _BalanceCard(title: 'جمع گردش فاکتورها', value: formatToman(relevantInvoices.fold<int>(0, (sum, row) => sum + row.totalToman)), icon: Icons.receipt_long_outlined, tint: const Color(0xFFE9F8F4)),
          ];
          if (narrow) return Column(children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 8), child: card)).toList());
          return Row(children: [for (var index = 0; index < cards.length; index++) Expanded(child: Padding(padding: EdgeInsetsDirectional.only(end: index == cards.length - 1 ? 0 : 9), child: cards[index]))]);
        }),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [const Expanded(child: Text('دفتر ریز گردش حساب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))), Text('${persianDigits(entries.length)} ردیف', style: const TextStyle(fontSize: 9, color: Color(0xFF929CAF)))]),
          const SizedBox(height: 8),
          _LedgerTableRow(date: 'تاریخ', description: 'شرح سند', reference: 'شماره مرجع', debit: 0, credit: 0, balance: 0, header: true),
          if (opening != 0) _LedgerTableRow(date: 'مانده افتتاحیه', description: 'مانده ابتدای دوره', reference: '—', debit: opening > 0 ? opening : 0, credit: opening < 0 ? opening.abs() : 0, balance: opening, header: false),
          ...ledgerRows,
          if (entries.isEmpty) const EmptyPanel(title: 'گردش ثبت‌شده‌ای برای این مشتری نیست.', icon: Icons.history_rounded),
        ]))),
        const SizedBox(height: 10),
        Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('چک‌های مرتبط', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          if (relevantCheques.isEmpty) const Text('چکی ثبت نشده است.', style: TextStyle(fontSize: 9, color: Color(0xFF929CAF))),
          for (final cheque in relevantCheques) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.payments_outlined, color: pagePurple), title: Text('${asString(cheque['bank_name'])} · ${asString(cheque['cheque_number'])}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)), subtitle: Text('سررسید ${asString(cheque['due_date_jalali'])} · ${asString(cheque['status'])}', style: const TextStyle(fontSize: 8)), trailing: Text(formatToman(asInt(cheque['amount'])), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700))),
        ]))),
      ],
    ]));
  }

  Future<void> _addCustomer(BuildContext context) async {
    final code = TextEditingController(), name = TextEditingController(), phone = TextEditingController(), address = TextEditingController(), limit = TextEditingController(text: '0');
    var type = 'wholesale';
    var busy = false;
    final key = GlobalKey<FormState>();
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: const Text('مشتری جدید', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 420, child: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: code, decoration: const InputDecoration(labelText: 'کد مشتری'), validator: (value) => value == null || value.trim().isEmpty ? 'کد لازم است.' : null),
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'نام مشتری'), validator: (value) => value == null || value.trim().isEmpty ? 'نام لازم است.' : null),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'تلفن')),
            TextField(controller: address, decoration: const InputDecoration(labelText: 'نشانی')),
            DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'نوع مشتری'), items: const [DropdownMenuItem(value: 'wholesale', child: Text('عمده‌فروش')), DropdownMenuItem(value: 'retail', child: Text('خرده‌فروش')), DropdownMenuItem(value: 'misc', child: Text('سایر'))], onChanged: (value) => setDialog(() => type = value ?? type)),
            TextField(controller: limit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سقف اعتبار (تومان)')),
            const SizedBox(height: 8), const InfoPanel(icon: Icons.shield_outlined, text: 'قیمت خرید و سود در پرونده مشتری ذخیره یا نمایش داده نمی‌شود.'),
          ])))),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            if (!(key.currentState?.validate() ?? false)) return;
            final credit = int.tryParse(_english(limit.text).replaceAll(',', '').replaceAll('٬', '')) ?? 0;
            setDialog(() => busy = true);
            try {
              await ref.read(businessRepositoryProvider).saveRecord('customers', {'code': code.text.trim(), 'name': name.text.trim(), 'phone': phone.text.trim(), 'address': address.text.trim(), 'customer_type': type, 'credit_limit': credit, 'current_balance': 0, 'is_active': true});
              if (context.mounted) Navigator.pop(dialogContext);
              _toast('مشتری ثبت شد.'); _reload();
            } catch (error) { _toast('ثبت مشتری ناموفق بود: $error'); setDialog(() => busy = false); }
          }, child: busy ? const CircularProgressIndicator() : const Text('ثبت مشتری'))],
        )));
    code.dispose(); name.dispose(); phone.dispose(); address.dispose(); limit.dispose();
  }

  Future<void> _reload() async { for (final collection in ['customers', 'invoices', 'payments', 'cheques']) ref.invalidate(recordsProvider(collection)); await Future<void>.delayed(const Duration(milliseconds: 160)); }
  String _english(String text) { var value = text; for (var i = 0; i < 10; i++) value = value.replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i').replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i'); return value; }
  String _paymentLabel(String type) => switch (type) { 'cash' => 'نقدی', 'card' => 'کارتی', 'cheque' => 'چکی', _ => type };
  void _toast(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
}

class _CustomerProfile extends StatelessWidget {
  const _CustomerProfile({required this.customer, required this.invoices, required this.cheques});
  final Customer customer;
  final int invoices, cheques;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        CircleAvatar(radius: 21, backgroundColor: const Color(0xFFF0EFFF), child: const Icon(Icons.person_outline_rounded, color: pagePurple)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(customer.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)), Text('${customer.code} · ${customer.phone} · ${customer.address}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF)))])),
        _TinyCount(label: 'فاکتور', value: invoices), const SizedBox(width: 7), _TinyCount(label: 'چک', value: cheques),
      ])));
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.title, required this.value, required this.icon, required this.tint});
  final String title, value;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 17, color: pagePurple)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF))), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)]))])));
}

class _TinyCount extends StatelessWidget {
  const _TinyCount({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Column(children: [Text(persianDigits(value), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF)))]);
}

class _LedgerRow {
  const _LedgerRow({required this.date, required this.kind, required this.reference, required this.debit, required this.credit});
  final String date, kind, reference;
  final int debit, credit;
}

class _LedgerTableRow extends StatelessWidget {
  const _LedgerTableRow({required this.date, required this.description, required this.reference, required this.debit, required this.credit, required this.balance, required this.header});
  final String date, description, reference;
  final int debit, credit, balance;
  final bool header;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: header ? const Color(0xFFF7F8FB) : Colors.transparent, border: const Border(bottom: BorderSide(color: Color(0xFFF0F2F6)))), child: Row(children: [
        Expanded(flex: 2, child: Text(date, style: TextStyle(fontSize: 8, fontWeight: header ? FontWeight.w800 : FontWeight.normal, color: header ? pageInk : const Color(0xFF758097)))),
        Expanded(flex: 3, child: Text(description, style: TextStyle(fontSize: 8, fontWeight: header ? FontWeight.w800 : FontWeight.normal, color: header ? pageInk : const Color(0xFF45516A)))),
        Expanded(flex: 2, child: Text(reference, style: TextStyle(fontSize: 8, fontWeight: header ? FontWeight.w800 : FontWeight.normal, color: const Color(0xFF758097)))),
        Expanded(flex: 2, child: Text(header ? 'بدهکار' : formatToman(debit, withUnit: false), textAlign: TextAlign.end, style: TextStyle(fontSize: 8, fontWeight: header ? FontWeight.w800 : FontWeight.normal, color: const Color(0xFFB45D57)))),
        Expanded(flex: 2, child: Text(header ? 'بستانکار' : formatToman(credit, withUnit: false), textAlign: TextAlign.end, style: TextStyle(fontSize: 8, fontWeight: header ? FontWeight.w800 : FontWeight.normal, color: const Color(0xFF29836B)))),
        Expanded(flex: 2, child: Text(header ? 'مانده' : formatToman(balance, withUnit: false), textAlign: TextAlign.end, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: pageInk))),
      ]));
}

extension _FirstOrNull<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
