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

class InvestorScreen extends ConsumerStatefulWidget {
  const InvestorScreen({super.key});
  @override
  ConsumerState<InvestorScreen> createState() => _InvestorScreenState();
}

class _InvestorScreenState extends ConsumerState<InvestorScreen> {
  @override
  Widget build(BuildContext context) {
    final role = ref.watch(activeRoleProvider);
    final investorsAsync = ref.watch(recordsProvider('investors'));
    final dealsAsync = ref.watch(recordsProvider('investor_deals'));
    final settlementsAsync = ref.watch(recordsProvider('investor_settlements'));
    final chequesAsync = ref.watch(recordsProvider('cheques'));
    final invoicesAsync = role == AppRole.admin || role == AppRole.accountant ? ref.watch(recordsProvider('invoices')) : const AsyncData<List<JsonMap>>(<JsonMap>[]);
    final privateCostsAsync = role == AppRole.admin ? ref.watch(recordsProvider('investor_deal_costs')) : const AsyncData<List<JsonMap>>(<JsonMap>[]);
    final investors = investorsAsync.asData?.value ?? const <JsonMap>[];
    final session = ref.watch(sessionProvider);
    final investorId = role == AppRole.investor
        ? (session?.investorId.isNotEmpty == true ? session!.investorId : 'investor-1')
        : _selectedInvestorId;
    final investor = investors.where((row) => asString(row['id']) == investorId).firstOrNull ?? (investors.isNotEmpty && role != AppRole.investor ? investors.first : null);
    final deals = (dealsAsync.asData?.value ?? const <JsonMap>[]).map(InvestorDeal.fromMap).toList();
    final settlements = settlementsAsync.asData?.value ?? const <JsonMap>[];
    final cheques = (chequesAsync.asData?.value ?? const <JsonMap>[]).map(Cheque.fromMap).toList();
    final invoices = (invoicesAsync.asData?.value ?? const <JsonMap>[]).map(Invoice.fromMap).toList();
    final selectedInvestorId = investor == null ? '' : asString(investor['id']);
    final selectedDeals = investor == null ? deals : deals.where((deal) => deal.investorId == selectedInvestorId).toList();
    final selectedSettlements = investor == null ? settlements : settlements.where((row) => asString(row['investor_id']) == selectedInvestorId).toList();
    final selectedCheques = investor == null ? cheques : cheques.where((cheque) => cheque.investorId == selectedInvestorId).toList();
    final profits = selectedDeals.fold<int>(0, (sum, deal) => sum + deal.investorProfitToman);
    final settled = selectedSettlements.fold<int>(0, (sum, row) => sum + asInt(row['amount']));
    final ownInvoices = investor == null ? invoices : invoices.where((invoice) => invoice.saleMode == 'investor' && invoice.investorId == selectedInvestorId).toList();
    final admin = role == AppRole.admin;
    final canSettle = role == AppRole.admin || role == AppRole.accountant;
    final busy = investorsAsync.isLoading || dealsAsync.isLoading || settlementsAsync.isLoading || chequesAsync.isLoading;

    return RefreshIndicator(onRefresh: _reload, child: ListView(padding: const EdgeInsets.fromLTRB(22, 20, 22, 36), children: [
      PageHeading(
        title: role == AppRole.investor ? 'پرتفوی سرمایه‌گذاری شما' : 'سرمایه‌گذاران و تسویه‌ها',
        subtitle: 'معاملات اختصاصی، سود سرمایه‌گذار، چک‌ها و تاریخچه تسویه',
        action: canSettle ? Wrap(spacing: 7, children: [
          OutlinedButton.icon(onPressed: () => _addInvestor(context), icon: const Icon(Icons.person_add_alt_1_rounded, size: 16), label: const Text('سرمایه‌گذار')),
          FilledButton.icon(onPressed: investor == null ? null : () => _addSettlement(context, selectedInvestorId), icon: const Icon(Icons.payments_outlined, size: 16), label: const Text('ثبت تسویه')),
          OutlinedButton.icon(onPressed: () => _addDeal(context, investors, ownInvoices, canSeeCost: admin), icon: const Icon(Icons.add_chart_rounded, size: 16), label: const Text('ثبت معامله')),
        ]) : null,
      ),
      if (role == AppRole.investor) const InfoPanel(icon: Icons.lock_outline_rounded, text: 'نمایش فقط شامل معاملات، سهم سود، چک‌ها و تسویه‌های حساب خود شماست. بهای خرید بنفشه و سود بنفشه هرگز در این نما نیست.', color: Color(0xFFEFF7FF)),
      if (role == AppRole.admin) const InfoPanel(icon: Icons.admin_panel_settings_outlined, text: 'اطلاعات بهای تمام‌شده و سود بنفشه در بخش خصوصی مدیر نمایش داده می‌شود و از مجموعه جداگانه می‌آید.'),
      const SizedBox(height: 12),
      if (role != AppRole.investor && investors.isNotEmpty) DropdownButtonFormField<String>(value: investor == null ? null : selectedInvestorId, decoration: const InputDecoration(labelText: 'سرمایه‌گذار منتخب'), items: investors.map((row) => DropdownMenuItem(value: asString(row['id']), child: Text(asString(row['name'])))).toList(), onChanged: (value) => setState(() => _selectedInvestorId = value ?? '')),
      if (role != AppRole.investor && investors.isNotEmpty) const SizedBox(height: 10),
      LoadingOrError(loading: busy, error: investorsAsync.hasError ? investorsAsync.error : dealsAsync.hasError ? dealsAsync.error : settlementsAsync.hasError ? settlementsAsync.error : chequesAsync.error, onRetry: _reload),
      if (investor == null && !investorsAsync.isLoading) const EmptyPanel(title: 'سرمایه‌گذاری برای این حساب ثبت نشده است.', icon: Icons.trending_up_rounded),
      if (investor != null) ...[
        _InvestorIdentity(
          investor: investor,
          onEdit: canSettle ? () => _editInvestor(context, investor) : null,
          onDelete: admin ? () => _deleteInvestor(context, investor) : null,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final stats = [
            _InvestorStat(label: 'معاملات', value: persianDigits(selectedDeals.length), icon: Icons.trending_up_rounded),
            _InvestorStat(label: 'سود معاملات شما', value: formatToman(profits), icon: Icons.account_balance_wallet_outlined),
            _InvestorStat(label: 'چک‌های مرتبط', value: persianDigits(selectedCheques.length), icon: Icons.payments_outlined),
            _InvestorStat(label: 'تسویه ثبت‌شده', value: formatToman(settled), icon: Icons.fact_check_outlined),
          ];
          final gap = 8.0;
          final columns = constraints.maxWidth > 1020 ? 4 : constraints.maxWidth > 570 ? 2 : 1;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(spacing: gap, runSpacing: gap, children: [for (final stat in stats) SizedBox(width: width, child: stat)]);
        }),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [const Expanded(child: Text('معاملات و سود شما', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))), Text('${persianDigits(selectedDeals.length)} معامله', style: const TextStyle(fontSize: 9, color: Color(0xFF929CAF)))]),
          const SizedBox(height: 9),
          if (selectedDeals.isEmpty) const EmptyPanel(title: 'معامله‌ای برای این سرمایه‌گذار ثبت نشده است.', icon: Icons.trending_up_rounded),
          for (final deal in selectedDeals) _DealRow(
            deal: deal,
            invoices: invoices,
            onEdit: canSettle ? () => _editDeal(context, deal, investors, ownInvoices) : null,
            onDelete: admin ? () => _deleteDeal(context, deal) : null,
          ),
        ]))),
        const SizedBox(height: 10),
        if (admin) _AdminCostPanel(rows: privateCostsAsync.asData?.value ?? const <JsonMap>[], loading: privateCostsAsync.isLoading),
        if (admin) const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final history = _SettlementPanel(
            rows: selectedSettlements,
            canEdit: canSettle,
            canDelete: admin,
            onEdit: (row) => _editSettlement(context, row),
            onDelete: (row) => _deleteSettlement(context, row),
          );
          final chequePanel = _InvestorChequesPanel(rows: selectedCheques);
          if (constraints.maxWidth < 760) return Column(children: [history, const SizedBox(height: 10), chequePanel]);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: history), const SizedBox(width: 10), Expanded(child: chequePanel)]);
        }),
      ],
    ]));
  }

  String _selectedInvestorId = '';

  Future<void> _editInvestor(BuildContext context, JsonMap investor) async {
    final id = asString(investor['id']);
    final name = TextEditingController(text: asString(investor['name']));
    final phone = TextEditingController(text: asString(investor['phone']));
    final address = TextEditingController(text: asString(investor['address']));
    var type = asString(investor['settlement_type'], fallback: 'cash');
    var active = investor['is_active'] != false;
    var busy = false;
    final key = GlobalKey<FormState>();
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: Text('ویرایش سرمایه‌گذار · ${asString(investor['name'])}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 420, child: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'نام'), validator: (value) => value == null || value.trim().isEmpty ? 'نام الزامی است.' : null),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'شماره تماس')),
            TextField(controller: address, decoration: const InputDecoration(labelText: 'نشانی')),
            DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'روش تسویه پیش‌فرض'), items: const [DropdownMenuItem(value: 'cash', child: Text('نقدی')), DropdownMenuItem(value: 'goods', child: Text('کالا')), DropdownMenuItem(value: 'cheque', child: Text('چک')), DropdownMenuItem(value: 'mixed', child: Text('ترکیبی'))], onChanged: (value) => setDialog(() => type = value ?? type)),
            SwitchListTile(title: const Text('حساب فعال', style: TextStyle(fontSize: 10)), value: active, onChanged: (value) => setDialog(() => active = value)),
          ]))),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            if (!(key.currentState?.validate() ?? false)) return;
            setDialog(() => busy = true);
            try {
              await ref.read(businessRepositoryProvider).updateRecord('investors', id, {'name': name.text.trim(), 'phone': phone.text.trim(), 'address': address.text.trim(), 'settlement_type': type, 'is_active': active});
              if (context.mounted) Navigator.pop(dialogContext);
              _toast('پرونده سرمایه‌گذار به‌روزرسانی شد.'); _reload();
            } catch (error) { _toast('ویرایش ناموفق بود: $error'); setDialog(() => busy = false); }
          }, child: busy ? const CircularProgressIndicator() : const Text('ذخیره تغییرات'))],
        )));
    name.dispose(); phone.dispose(); address.dispose();
  }

  Future<void> _deleteInvestor(BuildContext context, JsonMap investor) async {
    final id = asString(investor['id']);
    final confirmed = await confirmDestructiveAction(context, title: 'حذف سرمایه‌گذار', message: 'سرمایه‌گذار «${asString(investor['name'])}» حذف شود؟ وجود معامله یا چک مرتبط ممکن است باعث رد حذف از طرف PocketBase شود.');
    if (!confirmed) return;
    try {
      await ref.read(businessRepositoryProvider).deleteRecord('investors', id);
      if (_selectedInvestorId == id) setState(() => _selectedInvestorId = '');
      _toast('سرمایه‌گذار حذف شد.'); _reload();
    } catch (error) { _toast('حذف سرمایه‌گذار ناموفق بود: $error'); }
  }

  Future<void> _editDeal(BuildContext context, InvestorDeal deal, List<JsonMap> investors, List<Invoice> invoices) async {
    if (investors.isEmpty || invoices.isEmpty) { _toast('برای ویرایش معامله، سرمایه‌گذار و فاکتورهای فروش را دریافت کنید.'); return; }
    var investorId = deal.investorId;
    var invoiceId = invoices.any((invoice) => invoice.id == deal.customerInvoiceId) ? deal.customerInvoiceId : invoices.first.id;
    final saleToBenafsheh = TextEditingController(text: deal.benafshehSellToman.toString());
    var date = _parseJalali(deal.dealDateJalali);
    var status = deal.status;
    var busy = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: Text('ویرایش معامله · ${deal.id}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(value: investors.any((row) => asString(row['id']) == investorId) ? investorId : asString(investors.first['id']), decoration: const InputDecoration(labelText: 'سرمایه‌گذار'), items: investors.map((row) => DropdownMenuItem(value: asString(row['id']), child: Text(asString(row['name'])))).toList(), onChanged: (value) => setDialog(() => investorId = value ?? investorId)),
            DropdownButtonFormField<String>(value: invoiceId, decoration: const InputDecoration(labelText: 'فاکتور فروش'), items: invoices.map((invoice) => DropdownMenuItem(value: invoice.id, child: Text('${invoice.number} · ${invoice.customerName}', overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => setDialog(() => invoiceId = value ?? invoiceId)),
            TextField(controller: saleToBenafsheh, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'فروش بنفشه به سرمایه‌گذار (تومان)')),
            DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'وضعیت'), items: const [DropdownMenuItem(value: 'open', child: Text('باز')), DropdownMenuItem(value: 'settled', child: Text('تسویه‌شده'))], onChanged: (value) => setDialog(() => status = value ?? status)),
            const SizedBox(height: 8), JalaliDateField(initialDate: date, onChanged: (value) => date = value),
          ])),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            final price = _parseMoney(saleToBenafsheh.text);
            final invoice = invoices.where((item) => item.id == invoiceId).first;
            if (price <= 0 || price > invoice.totalToman) { _toast('مبلغ فروش بنفشه باید مثبت و از فروش مشتری بیشتر نباشد.'); return; }
            setDialog(() => busy = true);
            try {
              await ref.read(businessRepositoryProvider).updateRecord('investor_deals', deal.id, {
                'investor_id': investorId, 'customer_invoice_id': invoice.id, 'benafsheh_sell_price': price,
                'customer_sell_price': invoice.totalToman, 'investor_profit': invoice.totalToman - price,
                'status': status, 'deal_date_jalali': formatJalaliDate(date),
              });
              if (context.mounted) Navigator.pop(dialogContext);
              _toast('معامله به‌روزرسانی شد.'); _reload();
            } catch (error) { _toast('ویرایش معامله ناموفق بود: $error'); setDialog(() => busy = false); }
          }, child: busy ? const CircularProgressIndicator() : const Text('ذخیره تغییرات'))],
        )));
    saleToBenafsheh.dispose();
  }

  Future<void> _deleteDeal(BuildContext context, InvestorDeal deal) async {
    final confirmed = await confirmDestructiveAction(context, title: 'حذف معامله', message: 'معامله ${deal.id} حذف شود؟ رکورد هزینه محرمانه مرتبط نیز حذف می‌شود.');
    if (!confirmed) return;
    try {
      final costRows = await ref.read(recordsProvider('investor_deal_costs').future);
      final repo = ref.read(businessRepositoryProvider);
      for (final row in costRows.where((row) => asString(row['investor_deal']) == deal.id)) {
        await repo.deleteRecord('investor_deal_costs', asString(row['id']));
      }
      await repo.deleteRecord('investor_deals', deal.id);
      _toast('معامله حذف شد.'); _reload();
    } catch (error) { _toast('حذف معامله ناموفق بود: $error'); }
  }

  Future<void> _editSettlement(BuildContext context, JsonMap settlement) async {
    final amount = TextEditingController(text: asString(settlement['amount']));
    final notes = TextEditingController(text: asString(settlement['notes']));
    var type = asString(settlement['settlement_type'], fallback: 'cash');
    var date = _parseJalali(asString(settlement['settlement_date_jalali']));
    var busy = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: const Text('ویرایش تسویه سرمایه‌گذار', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 390, child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'نوع تسویه'), items: const [DropdownMenuItem(value: 'cash', child: Text('نقدی')), DropdownMenuItem(value: 'goods', child: Text('کالا')), DropdownMenuItem(value: 'cheque', child: Text('چک'))], onChanged: (value) => setDialog(() => type = value ?? type)),
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ (تومان)')),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'یادداشت')),
            const SizedBox(height: 8), JalaliDateField(initialDate: date, onChanged: (value) => date = value),
          ])),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            final value = _parseMoney(amount.text);
            if (value <= 0) { _toast('مبلغ معتبر وارد کنید.'); return; }
            setDialog(() => busy = true);
            try {
              await ref.read(businessRepositoryProvider).updateRecord('investor_settlements', asString(settlement['id']), {'settlement_type': type, 'amount': value, 'settlement_date_jalali': formatJalaliDate(date), 'notes': notes.text.trim()});
              if (context.mounted) Navigator.pop(dialogContext);
              _toast('تسویه به‌روزرسانی شد.'); _reload();
            } catch (error) { _toast('ویرایش تسویه ناموفق بود: $error'); setDialog(() => busy = false); }
          }, child: busy ? const CircularProgressIndicator() : const Text('ذخیره تغییرات'))],
        )));
    amount.dispose(); notes.dispose();
  }

  Future<void> _deleteSettlement(BuildContext context, JsonMap settlement) async {
    final confirmed = await confirmDestructiveAction(context, title: 'حذف تسویه', message: 'این تسویه حذف شود؟');
    if (!confirmed) return;
    try {
      await ref.read(businessRepositoryProvider).deleteRecord('investor_settlements', asString(settlement['id']));
      _toast('تسویه حذف شد.'); _reload();
    } catch (error) { _toast('حذف تسویه ناموفق بود: $error'); }
  }

  Jalali _parseJalali(String input) {
    var text = input;
    for (var i = 0; i < 10; i++) text = text.replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i').replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i');
    final values = text.split('/').map((part) => int.tryParse(part) ?? 0).toList();
    try { return values.length == 3 && values[0] > 0 ? Jalali(values[0], values[1], values[2]) : Jalali.now(); } catch (_) { return Jalali.now(); }
  }

  Future<void> _addInvestor(BuildContext context) async {
    final name = TextEditingController(), phone = TextEditingController(), address = TextEditingController();
    var type = 'cash', busy = false;
    final key = GlobalKey<FormState>();
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: const Text('افزودن سرمایه‌گذار', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 410, child: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'نام سرمایه‌گذار'), validator: (value) => value == null || value.trim().isEmpty ? 'نام الزامی است.' : null),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'شماره تماس')),
            TextField(controller: address, decoration: const InputDecoration(labelText: 'نشانی')),
            DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'روش تسویه پیش‌فرض'), items: const [DropdownMenuItem(value: 'cash', child: Text('نقدی')), DropdownMenuItem(value: 'goods', child: Text('کالا')), DropdownMenuItem(value: 'cheque', child: Text('چک')), DropdownMenuItem(value: 'mixed', child: Text('ترکیبی'))], onChanged: (value) => setDialog(() => type = value ?? type)),
          ]))),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            if (!(key.currentState?.validate() ?? false)) return;
            setDialog(() => busy = true);
            try {
              await ref.read(businessRepositoryProvider).saveRecord('investors', {'name': name.text.trim(), 'phone': phone.text.trim(), 'address': address.text.trim(), 'settlement_type': type, 'is_active': true});
              if (context.mounted) Navigator.pop(dialogContext);
              _toast('سرمایه‌گذار ثبت شد.'); _reload();
            } catch (error) { _toast('ثبت ناموفق بود: $error'); setDialog(() => busy = false); }
          }, child: busy ? const CircularProgressIndicator() : const Text('ذخیره'))],
        )));
    name.dispose(); phone.dispose(); address.dispose();
  }

  Future<void> _addSettlement(BuildContext context, String investorId) async {
    final amount = TextEditingController(), notes = TextEditingController();
    String type = 'cash', date = formatJalaliDate(Jalali.now());
    var busy = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: const Text('ثبت تسویه سرمایه‌گذار', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'نوع تسویه'), items: const [DropdownMenuItem(value: 'cash', child: Text('نقدی')), DropdownMenuItem(value: 'goods', child: Text('کالا')), DropdownMenuItem(value: 'cheque', child: Text('چک'))], onChanged: (value) => setDialog(() => type = value ?? type)),
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ (تومان)')),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'یادداشت')),
            const SizedBox(height: 8), JalaliDateField(initialDate: Jalali.now(), onChanged: (value) => date = formatJalaliDate(value)),
            const SizedBox(height: 8), const InfoPanel(icon: Icons.shield_outlined, text: 'این تسویه به حساب سرمایه‌گذار انتخاب‌شده پیوند می‌خورد.'),
          ])),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            final value = _parseMoney(amount.text);
            if (value <= 0) { _toast('مبلغ معتبر وارد کنید.'); return; }
            setDialog(() => busy = true);
            try {
              await ref.read(businessRepositoryProvider).createSettlement({'investor_id': investorId, 'settlement_type': type, 'amount': value, 'settlement_date_jalali': date, 'notes': notes.text.trim()});
              if (context.mounted) Navigator.pop(dialogContext);
              _toast('تسویه ثبت شد.'); _reload();
            } catch (error) { _toast('ثبت تسویه ناموفق بود: $error'); setDialog(() => busy = false); }
          }, child: busy ? const CircularProgressIndicator() : const Text('ثبت تسویه'))],
        )));
    amount.dispose(); notes.dispose();
  }

  Future<void> _addDeal(BuildContext context, List<JsonMap> investors, List<Invoice> invoices, {required bool canSeeCost}) async {
    final usableInvoices = invoices.where((invoice) => invoice.status == 'confirmed' && invoice.type == 'sale').toList();
    if (investors.isEmpty || usableInvoices.isEmpty) { _toast('برای ثبت معامله، سرمایه‌گذار و فاکتور فروش تأییدشده لازم است.'); return; }
    String investorId = _selectedInvestorId.isNotEmpty ? _selectedInvestorId : asString(investors.first['id']);
    String invoiceId = usableInvoices.first.id;
    final sellToBenafsheh = TextEditingController();
    final costToBenafsheh = TextEditingController();
    var date = formatJalaliDate(Jalali.now());
    var busy = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: const Text('ثبت معامله سرمایه‌گذاری', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 490, child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(value: investorId, decoration: const InputDecoration(labelText: 'سرمایه‌گذار'), items: investors.map((row) => DropdownMenuItem(value: asString(row['id']), child: Text(asString(row['name'])))).toList(), onChanged: (value) => setDialog(() => investorId = value ?? investorId)),
            DropdownButtonFormField<String>(value: invoiceId, decoration: const InputDecoration(labelText: 'فاکتور فروش مشتری'), items: usableInvoices.map((invoice) => DropdownMenuItem(value: invoice.id, child: Text('${invoice.number} · ${invoice.customerName} · ${formatToman(invoice.totalToman)}', overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => setDialog(() => invoiceId = value ?? invoiceId)),
            TextField(controller: sellToBenafsheh, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ فروش بنفشه به سرمایه‌گذار (تومان)')),
            if (canSeeCost) TextField(controller: costToBenafsheh, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'بهای خرید بنفشه (فقط مدیر)')),
            const SizedBox(height: 8), JalaliDateField(initialDate: Jalali.now(), onChanged: (value) => date = formatJalaliDate(value)),
            const SizedBox(height: 8), InfoPanel(icon: Icons.lock_outline_rounded, text: canSeeCost ? 'بهای خرید و سود بنفشه فقط در رکورد خصوصی مدیر ذخیره می‌شود.' : 'قیمت خرید و سود بنفشه در این نقش نمایش یا ثبت نمی‌شود.'),
          ])),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            final invoice = usableInvoices.where((row) => row.id == invoiceId).first;
            final benafshehPrice = _parseMoney(sellToBenafsheh.text);
            final cost = canSeeCost ? _parseMoney(costToBenafsheh.text) : 0;
            if (benafshehPrice <= 0 || invoice.totalToman < benafshehPrice) { _toast('مبلغ فروش بنفشه باید مثبت و حداکثر برابر با مبلغ فروش مشتری باشد.'); return; }
            if (cost < 0 || cost > benafshehPrice) { _toast('بهای تمام‌شده نمی‌تواند از مبلغ فروش بنفشه بیشتر باشد.'); return; }
            setDialog(() => busy = true);
            try {
              final deal = await ref.read(businessRepositoryProvider).saveRecord('investor_deals', {
                'investor_id': investorId, 'customer_invoice_id': invoice.id, 'benafsheh_sell_price': benafshehPrice,
                'customer_sell_price': invoice.totalToman, 'investor_profit': invoice.totalToman - benafshehPrice,
                'status': 'open', 'deal_date_jalali': date,
              });
              final dealId = asString(deal['id']);
              if (cost > 0 && dealId.isNotEmpty) {
                await ref.read(businessRepositoryProvider).saveRecord('investor_deal_costs', {
                  'investor_deal': dealId, 'benafsheh_cost_price': cost, 'benafsheh_profit': benafshehPrice - cost,
                });
              }
              if (context.mounted) Navigator.pop(dialogContext);
              _toast('معامله و رکوردهای مجاز ثبت شدند.'); _reload();
            } catch (error) { _toast('ثبت معامله ناموفق بود: $error'); setDialog(() => busy = false); }
          }, child: busy ? const CircularProgressIndicator() : const Text('ثبت معامله'))],
        )));
    sellToBenafsheh.dispose(); costToBenafsheh.dispose();
  }

  int _parseMoney(String input) { var text = input; for (var i = 0; i < 10; i++) text = text.replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i').replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i'); return int.tryParse(text.replaceAll(',', '').replaceAll('٬', '')) ?? 0; }
  Future<void> _reload() async { for (final collection in ['investors', 'investor_deals', 'investor_settlements', 'cheques', 'invoices', 'investor_deal_costs']) ref.invalidate(recordsProvider(collection)); await Future<void>.delayed(const Duration(milliseconds: 150)); }
  void _toast(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
}

class _InvestorIdentity extends StatelessWidget {
  const _InvestorIdentity({required this.investor, this.onEdit, this.onDelete});
  final JsonMap investor;
  final VoidCallback? onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [CircleAvatar(radius: 19, backgroundColor: const Color(0xFFF0EFFF), child: const Icon(Icons.trending_up_rounded, color: pagePurple, size: 17)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(asString(investor['name']), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), Text(asString(investor['phone'], fallback: 'شماره تماس ثبت نشده'), style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF)))])), StatusBadge(investor['is_active'] == false ? 'inactive' : 'active', label: investor['is_active'] == false ? 'غیرفعال' : 'فعال'), if (onEdit != null) IconButton(tooltip: 'ویرایش سرمایه‌گذار', onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 17)), if (onDelete != null) IconButton(tooltip: 'حذف سرمایه‌گذار', onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFC35656)))])));
}

class _InvestorStat extends StatelessWidget {
  const _InvestorStat({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [CircleAvatar(radius: 16, backgroundColor: const Color(0xFFF0EFFF), child: Icon(icon, color: pagePurple, size: 15)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF))), Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))]))])));
}

class _DealRow extends StatelessWidget {
  const _DealRow({required this.deal, required this.invoices, this.onEdit, this.onDelete});
  final InvestorDeal deal;
  final List<Invoice> invoices;
  final VoidCallback? onEdit, onDelete;
  @override
  Widget build(BuildContext context) {
    final invoice = invoices.where((row) => row.id == deal.customerInvoiceId).firstOrNull;
    final customer = deal.customerName.isNotEmpty ? deal.customerName : invoice?.customerName ?? 'معامله ${deal.id}';
    return Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F2F6)))), child: Row(children: [
          const CircleAvatar(radius: 16, backgroundColor: Color(0xFFE9F8F4), child: Icon(Icons.trending_up_rounded, color: Color(0xFF25866E), size: 15)), const SizedBox(width: 9),
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(customer, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)), Text('${deal.dealDateJalali} · ${deal.id}', style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF)))])),
          Expanded(child: _MoneyColumn(label: 'فروش مشتری', value: deal.customerSellToman)),
          Expanded(child: _MoneyColumn(label: 'سود شما', value: deal.investorProfitToman, highlight: true)),
          StatusBadge(deal.status),
          if (onEdit != null) IconButton(tooltip: 'ویرایش معامله', onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 16)),
          if (onDelete != null) IconButton(tooltip: 'حذف معامله', onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFC35656))),
        ]));
  }
}

class _MoneyColumn extends StatelessWidget {
  const _MoneyColumn({required this.label, required this.value, this.highlight = false});
  final String label;
  final int value;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(label, style: const TextStyle(fontSize: 7, color: Color(0xFF929CAF))), Text(formatToman(value, withUnit: false), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: highlight ? const Color(0xFF25866E) : pageInk))]);
}

class _SettlementPanel extends StatelessWidget {
  const _SettlementPanel({required this.rows, required this.canEdit, required this.canDelete, required this.onEdit, required this.onDelete});
  final List<JsonMap> rows;
  final bool canEdit, canDelete;
  final ValueChanged<JsonMap> onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('تسویه‌های ثبت‌شده', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        if (rows.isEmpty) const Text('تسویه‌ای ثبت نشده است.', style: TextStyle(fontSize: 9, color: Color(0xFF929CAF))),
        for (final row in rows) ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.fact_check_outlined, color: pagePurple, size: 18),
          title: Text('${_settlementType(asString(row['settlement_type']))} · ${formatToman(asInt(row['amount']))}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
          subtitle: Text(asString(row['settlement_date_jalali']), style: const TextStyle(fontSize: 8)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (canEdit) IconButton(tooltip: 'ویرایش تسویه', onPressed: () => onEdit(row), icon: const Icon(Icons.edit_outlined, size: 16)),
            if (canDelete) IconButton(tooltip: 'حذف تسویه', onPressed: () => onDelete(row), icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFC35656))),
          ]),
        ),
      ])));
}

class _InvestorChequesPanel extends StatelessWidget {
  const _InvestorChequesPanel({required this.rows});
  final List<Cheque> rows;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('چک‌های مرتبط با حساب شما', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), const SizedBox(height: 7), if (rows.isEmpty) const Text('چکی ثبت نشده است.', style: TextStyle(fontSize: 9, color: Color(0xFF929CAF))), for (final cheque in rows) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.payments_outlined, color: pagePurple, size: 18), title: Text('${cheque.number} · ${cheque.bank}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)), subtitle: Text('سررسید ${cheque.dueDateJalali}', style: const TextStyle(fontSize: 8)), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(formatToman(cheque.amountToman), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)), StatusBadge(cheque.status)]))])));
}

class _AdminCostPanel extends StatelessWidget {
  const _AdminCostPanel({required this.rows, required this.loading});
  final List<JsonMap> rows;
  final bool loading;
  @override
  Widget build(BuildContext context) => Card(color: const Color(0xFF111D3A), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('هزینه و سود محرمانه · مدیر', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4), const Text('این داده از مجموعه خصوصی investor_deal_costs می‌آید؛ نقش‌های دیگر به آن دسترسی ندارند.', style: TextStyle(color: Color(0xFFB2BCD1), fontSize: 8)),
        if (loading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
        if (!loading && rows.isEmpty) const Padding(padding: EdgeInsets.only(top: 9), child: Text('هزینه محرمانه‌ای برای نمایش ثبت نشده است.', style: TextStyle(color: Color(0xFFD0D7E7), fontSize: 9))),
        for (final row in rows) Padding(padding: const EdgeInsets.only(top: 9), child: Row(children: [Expanded(child: Text(asString(row['investor_deal']), style: const TextStyle(color: Color(0xFFD0D7E7), fontSize: 8))), Text('بهای خرید ${formatToman(asInt(row['benafsheh_cost_price']))} · سود بنفشه ${formatToman(asInt(row['benafsheh_profit']))}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))])),
      ])));
}

String _settlementType(String type) => switch (type) { 'cash' => 'نقدی', 'goods' => 'کالا', 'cheque' => 'چک', 'mixed' => 'ترکیبی', _ => type };
extension _FirstOrNull<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
