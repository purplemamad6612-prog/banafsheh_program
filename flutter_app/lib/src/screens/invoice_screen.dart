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

class InvoiceScreen extends ConsumerStatefulWidget {
  const InvoiceScreen({super.key});
  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  String _filter = 'همه فاکتورها';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(activeRoleProvider);
    final invoiceAsync = ref.watch(recordsProvider('invoices'));
    final customersAsync = ref.watch(recordsProvider('customers'));
    final productsAsync = ref.watch(recordsProvider('products'));
    final unitsAsync = ref.watch(recordsProvider('product_units'));
    final warehousesAsync = ref.watch(recordsProvider('warehouses'));
    final investorsAsync = ref.watch(recordsProvider('investors'));
    final invoices = (invoiceAsync.asData?.value ?? const <JsonMap>[]).map(Invoice.fromMap).toList();
    final customers = customersAsync.asData?.value ?? const <JsonMap>[];
    final unitRows = unitsAsync.asData?.value ?? const <JsonMap>[];
    final products = (productsAsync.asData?.value ?? const <JsonMap>[]).map((row) {
      final linked = unitRows.where((unit) => asString(unit['product_id']) == asString(row['id'])).toList();
      return Product.fromMap({...row, if (linked.isNotEmpty) 'units': linked});
    }).toList();
    final warehouses = warehousesAsync.asData?.value ?? const <JsonMap>[];
    final investors = investorsAsync.asData?.value ?? const <JsonMap>[];
    final isCustomer = role == AppRole.customer;
    final canCreate = role == AppRole.admin || role == AppRole.accountant || role == AppRole.sales || isCustomer;
    final canConfirm = role == AppRole.admin || role == AppRole.accountant || role == AppRole.sales;
    final canRecordPayment = role == AppRole.admin || role == AppRole.accountant;
    final filtered = invoices.where((invoice) {
      final query = _search.trim().toLowerCase();
      final queryOk = query.isEmpty || invoice.number.toLowerCase().contains(query) || invoice.customerName.toLowerCase().contains(query);
      final statusOk = _filter == 'همه فاکتورها' || (invoice.status == 'draft' ? _filter == 'پیش‌نویس' : _filter == 'تأییدشده');
      return queryOk && statusOk;
    }).toList()..sort((a, b) => b.dateJalali.compareTo(a.dateJalali));
    final isLoading = invoiceAsync.isLoading || customersAsync.isLoading || productsAsync.isLoading;

    return RefreshIndicator(onRefresh: _reload, child: ListView(padding: const EdgeInsets.fromLTRB(22, 20, 22, 36), children: [
      PageHeading(
        title: 'فاکتورها و پیش‌فاکتورها',
        subtitle: 'قیمت فروش فقط از موتور امن PocketBase محاسبه می‌شود؛ مبلغ دستی قابل ورود نیست.',
        action: canCreate ? FilledButton.icon(onPressed: products.isEmpty ? null : () => _createInvoice(context, customers, products, warehouses, investors, isCustomer), icon: const Icon(Icons.add_rounded, size: 18), label: Text(isCustomer ? 'درخواست پیش‌فاکتور' : 'فاکتور جدید')) : null,
      ),
      if (!ref.read(businessRepositoryProvider).isRemoteReady) const InfoPanel(icon: Icons.cloud_off_outlined, text: 'برای صدور پیش‌نویس و محاسبه قیمت نهایی، به PocketBase وارد شوید. قیمت هرگز به‌صورت محلی یا دستی محاسبه نمی‌شود.', color: Color(0xFFFFF6E9)),
      if (role == AppRole.sales) const InfoPanel(icon: Icons.lock_outline_rounded, text: 'فروشنده فقط نوع فروش، مشتری و مقدار را انتخاب می‌کند؛ قیمت خرید و حاشیه سود از سرور پنهان است.'),
      const SizedBox(height: 13),
      Wrap(spacing: 9, runSpacing: 9, children: [
        _InvoiceStat(label: 'همه فاکتورها', value: persianDigits(invoices.length), icon: Icons.receipt_long_outlined),
        _InvoiceStat(label: 'پیش‌نویس', value: persianDigits(invoices.where((row) => row.status == 'draft').length), icon: Icons.edit_note_rounded),
        _InvoiceStat(label: 'فروش تأییدشده', value: formatToman(invoices.where((row) => row.type == 'sale' && row.status == 'confirmed').fold<int>(0, (sum, row) => sum + row.totalToman)), icon: Icons.account_balance_wallet_outlined),
      ]),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 9, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(width: 260, child: TextField(onChanged: (value) => setState(() => _search = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'جستجوی شماره یا مشتری', isDense: true))),
        SizedBox(width: 170, child: DropdownButtonFormField<String>(value: _filter, decoration: const InputDecoration(labelText: 'وضعیت', isDense: true), items: const ['همه فاکتورها', 'پیش‌نویس', 'تأییدشده'].map((value) => DropdownMenuItem(value: value, child: Text(value, style: const TextStyle(fontSize: 10)))).toList(), onChanged: (value) => setState(() => _filter = value ?? 'همه فاکتورها'))),
        Text('${persianDigits(filtered.length)} سند', style: const TextStyle(fontSize: 9, color: Color(0xFF929CAF))),
      ]))),
      const SizedBox(height: 8),
      LoadingOrError(loading: isLoading, error: invoiceAsync.hasError ? invoiceAsync.error : customersAsync.hasError ? customersAsync.error : null, onRetry: _reload),
      if (!isLoading && filtered.isEmpty) const EmptyPanel(title: 'فاکتوری برای نمایش وجود ندارد.', icon: Icons.receipt_long_outlined),
      for (final invoice in filtered) _InvoiceCard(
        invoice: invoice,
        canConfirm: canConfirm && invoice.status == 'draft' && invoice.type != 'purchase',
        canRecordPayment: canRecordPayment && invoice.status == 'confirmed' && invoice.type == 'sale',
        onConfirm: () => _confirmInvoice(invoice),
        onPayment: () => _recordPayment(invoice),
        onDetails: () => _showDetails(invoice),
      ),
    ]));
  }

  Future<void> _createInvoice(BuildContext context, List<JsonMap> customers, List<Product> products, List<JsonMap> warehouses, List<JsonMap> investors, bool isCustomer) async {
    if (customers.isEmpty) { _toast('مشتری فعالی در دسترس نیست.'); return; }
    if (warehouses.isEmpty) { _toast('برای صدور فاکتور، انبار فعال لازم است.'); return; }
    if (products.isEmpty) { _toast('ابتدا کالا ثبت کنید.'); return; }
    String customerId = asString(customers.first['id']);
    String warehouseId = asString(warehouses.first['id']);
    String investorId = investors.isEmpty ? '' : asString(investors.first['id']);
    String invoiceType = isCustomer ? 'quote' : 'sale';
    String saleMode = 'cash';
    String discountScope = 'per_invoice';
    int chequeDays = 30;
    String dateJalali = formatJalaliDate(Jalali.now());
    String notes = '';
    final notesController = TextEditingController();
    final List<_DraftLine> lines = [_DraftLine(products.first)];
    var busy = false;
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: const Text('ایجاد فاکتور با قیمت‌گذاری امن', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 720, child: SingleChildScrollView(child: Form(key: formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 10, runSpacing: 8, children: [
              SizedBox(width: 300, child: DropdownButtonFormField<String>(value: customerId, decoration: const InputDecoration(labelText: 'مشتری'), items: customers.map((row) => DropdownMenuItem(value: asString(row['id']), child: Text('${asString(row['code'])} · ${asString(row['name'])}', overflow: TextOverflow.ellipsis))).toList(), onChanged: isCustomer ? null : (value) => setDialog(() => customerId = value ?? customerId))),
              SizedBox(width: 200, child: DropdownButtonFormField<String>(value: warehouseId, decoration: const InputDecoration(labelText: 'انبار'), items: warehouses.map((row) => DropdownMenuItem(value: asString(row['id']), child: Text(asString(row['name'])))).toList(), onChanged: (value) => setDialog(() => warehouseId = value ?? warehouseId))),
              if (!isCustomer) SizedBox(width: 170, child: DropdownButtonFormField<String>(value: invoiceType, decoration: const InputDecoration(labelText: 'نوع سند'), items: const [DropdownMenuItem(value: 'sale', child: Text('فاکتور فروش')), DropdownMenuItem(value: 'quote', child: Text('پیش‌فاکتور'))], onChanged: (value) => setDialog(() => invoiceType = value ?? invoiceType))),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 8, children: [
              SizedBox(width: 210, child: DropdownButtonFormField<String>(value: saleMode, decoration: const InputDecoration(labelText: 'روش فروش'), items: [const DropdownMenuItem(value: 'cash', child: Text('نقدی')), const DropdownMenuItem(value: 'cheque_direct', child: Text('چک مستقیم')), if (!isCustomer && (ref.read(activeRoleProvider) == AppRole.admin || ref.read(activeRoleProvider) == AppRole.accountant)) const DropdownMenuItem(value: 'investor', child: Text('با سرمایه‌گذار'))], onChanged: (value) => setDialog(() => saleMode = value ?? saleMode))),
              if (saleMode == 'cash') SizedBox(width: 220, child: DropdownButtonFormField<String>(value: discountScope, decoration: const InputDecoration(labelText: 'دامنه تخفیف حجمی'), items: const [DropdownMenuItem(value: 'per_invoice', child: Text('کل فاکتور')), DropdownMenuItem(value: 'per_group', child: Text('گروه کالا'))], onChanged: (value) => setDialog(() => discountScope = value ?? discountScope))),
              if (saleMode != 'cash') SizedBox(width: 160, child: TextFormField(initialValue: '$chequeDays', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مدت چک (روز)'), onChanged: (value) => chequeDays = int.tryParse(value) ?? 0)),
              if (saleMode == 'investor') SizedBox(width: 220, child: DropdownButtonFormField<String>(value: investorId.isEmpty ? null : investorId, decoration: const InputDecoration(labelText: 'سرمایه‌گذار'), items: investors.map((row) => DropdownMenuItem(value: asString(row['id']), child: Text(asString(row['name'])))).toList(), onChanged: (value) => setDialog(() => investorId = value ?? investorId))),
            ]),
            const SizedBox(height: 9),
            JalaliDateField(initialDate: Jalali.now(), onChanged: (date) => dateJalali = formatJalaliDate(date)),
            const SizedBox(height: 12),
            Row(children: [const Expanded(child: Text('اقلام فاکتور', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))), TextButton.icon(onPressed: busy ? null : () => setDialog(() => lines.add(_DraftLine(products.first))), icon: const Icon(Icons.add_rounded, size: 16), label: const Text('افزودن قلم', style: TextStyle(fontSize: 9)))]),
            for (var index = 0; index < lines.length; index++) Padding(padding: const EdgeInsets.only(bottom: 8), child: _DraftLineEditor(key: ValueKey('line-$index'), products: products, value: lines[index], onChanged: (product, unit, quantity) { lines[index].product = product; lines[index].unitName = unit; lines[index].quantity = quantity; }, onRemove: lines.length <= 1 ? null : () => setDialog(() => lines.removeAt(index)))),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'یادداشت اختیاری'), maxLines: 2),
            const SizedBox(height: 9),
            const InfoPanel(icon: Icons.lock_outline_rounded, text: 'این صفحه هیچ فیلد قیمت ندارد. قیمت‌گذاری، تخفیف حجمی، ضریب واحد و افزایش چک باید توسط سرور اعتبارسنجی و محاسبه شوند.'),
          ])))),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')),
            FilledButton.icon(onPressed: busy ? null : () async {
              if (!(formKey.currentState?.validate() ?? true) || lines.any((line) => line.quantity <= 0)) { _toast('مقدار هر کالا باید بزرگ‌تر از صفر باشد.'); return; }
              if (saleMode == 'investor' && investorId.isEmpty) { _toast('سرمایه‌گذار را انتخاب کنید.'); return; }
              setDialog(() => busy = true);
              final currentDate = Jalali.now();
              final invoiceNumber = '${currentDate.year}-${DateTime.now().microsecondsSinceEpoch.toRadixString(10).substring(8)}';
              final lineBodies = lines.map((line) => <String, dynamic>{'product_id': line.product.id, 'unit_name': line.unitName, 'quantity': line.quantity}).toList();
              try {
                final quote = await ref.read(businessRepositoryProvider).quoteAndCreateDraft(
                  customerId: customerId, warehouseId: warehouseId, invoiceType: invoiceType,
                  invoiceNumber: invoiceNumber, dateJalali: dateJalali, saleMode: saleMode,
                  investorId: saleMode == 'investor' ? investorId : '', discountScope: discountScope,
                  chequeDurationDays: chequeDays, lines: lineBodies, notes: notesController.text.trim(),
                );
                if (context.mounted) Navigator.pop(dialogContext);
                final total = asInt(quote['total']);
                _toast('پیش‌نویس ${asString(quote['invoice_number'], fallback: invoiceNumber)} ثبت شد · ${formatToman(total)}');
                _reload();
              } catch (error) {
                _toast('صدور فاکتور ممکن نشد: $error');
                setDialog(() => busy = false);
              }
            }, icon: const Icon(Icons.calculate_outlined, size: 17), label: Text(busy ? 'در حال محاسبه امن…' : 'محاسبه و ثبت پیش‌نویس')),
          ],
        )));
    notes = notesController.text;
    notesController.dispose();
  }

  Future<void> _confirmInvoice(Invoice invoice) async {
    try {
      final result = await ref.read(businessRepositoryProvider).confirmInvoice(invoice.id);
      _toast('فاکتور ${asString(result['invoice_number'], fallback: invoice.number)} تأیید شد؛ موجودی به‌صورت اتمی ثبت شد.');
      ref.invalidate(stockSummaryProvider);
      _reload();
    } catch (error) {
      _toast('تأیید انجام نشد: $error');
    }
  }

  Future<void> _recordPayment(Invoice invoice) async {
    final amount = TextEditingController(text: invoice.totalToman.toString());
    final reference = TextEditingController();
    var type = 'cash';
    var date = formatJalaliDate(Jalali.now());
    var busy = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: Text('ثبت دریافت · ${invoice.number}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'روش دریافت'), items: const [DropdownMenuItem(value: 'cash', child: Text('نقدی')), DropdownMenuItem(value: 'card', child: Text('کارت')), DropdownMenuItem(value: 'cheque', child: Text('چک'))], onChanged: (value) => setDialog(() => type = value ?? type)),
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ به تومان')),
            TextField(controller: reference, decoration: const InputDecoration(labelText: 'شماره پیگیری / توضیح')),
            const SizedBox(height: 8), JalaliDateField(initialDate: Jalali.now(), onChanged: (value) => date = formatJalaliDate(value)),
          ])),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            final parsed = int.tryParse(_englishDigits(amount.text).replaceAll(',', '').replaceAll('٬', ''));
            if (parsed == null || parsed <= 0) { _toast('مبلغ معتبر وارد کنید.'); return; }
            setDialog(() => busy = true);
            try {
              await ref.read(businessRepositoryProvider).saveRecord('payments', {
                'invoice_id': invoice.id, 'customer_id': invoice.customerId, 'payment_type': type,
                'amount': parsed, 'payment_date_jalali': date, 'reference_number': reference.text.trim(),
              });
              if (context.mounted) Navigator.pop(dialogContext);
              _toast('دریافت در دفتر مالی ثبت شد.');
              _reload();
            } catch (error) { _toast('ثبت دریافت ناموفق بود: $error'); setDialog(() => busy = false); }
          }, child: busy ? const CircularProgressIndicator() : const Text('ثبت دریافت'))],
        )));
    amount.dispose(); reference.dispose();
  }

  Future<void> _showDetails(Invoice invoice) async {
    final rows = await ref.read(recordsProvider('invoice_items').future);
    if (!mounted) return;
    final items = rows.where((row) => asString(row['invoice_id']) == invoice.id).toList();
    await showDialog<void>(context: context, builder: (context) => AlertDialog(
          title: Text('فاکتور ${invoice.number}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 520, child: items.isEmpty ? const EmptyPanel(title: 'اقلام این فاکتور موجود نیست.') : Column(mainAxisSize: MainAxisSize.min, children: [
            for (final item in items) ListTile(dense: true, title: Text(asString(item['product_name'], fallback: asString(item['product_id'])), style: const TextStyle(fontSize: 10)), subtitle: Text('${persianDigits(asDouble(item['quantity']))} ${asString(item['unit_used'])} · ضریب ${persianDigits(asDouble(item['conversion_factor_snapshot']))}', style: const TextStyle(fontSize: 8)), trailing: ref.read(activeRoleProvider) == AppRole.warehouse ? const SizedBox.shrink() : Text(formatToman(asInt(item['line_total']), withUnit: false), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700))),
            const Divider(), Align(alignment: Alignment.centerRight, child: Text('مبلغ نهایی: ${formatToman(invoice.totalToman)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))],
        ));
  }

  Future<void> _reload() async {
    for (final collection in ['invoices', 'invoice_items', 'customers', 'payments']) ref.invalidate(recordsProvider(collection));
    await Future<void>.delayed(const Duration(milliseconds: 160));
  }

  String _englishDigits(String value) {
    var result = value;
    for (var i = 0; i < 10; i++) result = result.replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i').replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i');
    return result;
  }

  void _toast(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
}

class _DraftLine {
  _DraftLine(this.product) : unitName = product.sellableUnits.isNotEmpty ? product.sellableUnits.first.name : product.baseUnitName;
  Product product;
  String unitName;
  double quantity = 1;
}

class _DraftLineEditor extends StatefulWidget {
  const _DraftLineEditor({super.key, required this.products, required this.value, required this.onChanged, this.onRemove});
  final List<Product> products;
  final _DraftLine value;
  final void Function(Product product, String unitName, double quantity) onChanged;
  final VoidCallback? onRemove;
  @override
  State<_DraftLineEditor> createState() => _DraftLineEditorState();
}

class _DraftLineEditorState extends State<_DraftLineEditor> {
  late final TextEditingController _quantity;

  @override
  void initState() { super.initState(); _quantity = TextEditingController(text: widget.value.quantity.toString()); }
  @override
  void dispose() { _quantity.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final product = widget.value.product;
    final units = product.sellableUnits.isEmpty ? [ProductUnit(id: '', name: product.baseUnitName, factor: 1)] : product.sellableUnits;
    if (!units.any((unit) => unit.name == widget.value.unitName)) widget.value.unitName = units.first.name;
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF8F9FC), borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFEAEDF4))), child: Column(children: [
      Row(children: [
        Expanded(flex: 5, child: DropdownButtonFormField<Product>(value: product, isExpanded: true, decoration: const InputDecoration(labelText: 'کالا', isDense: true), items: widget.products.map((item) => DropdownMenuItem(value: item, child: Text('${item.code} · ${item.name}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9)))).toList(), onChanged: (value) { if (value == null) return; final nextUnits = value.sellableUnits; final unit = nextUnits.isEmpty ? value.baseUnitName : nextUnits.first.name; widget.onChanged(value, unit, double.tryParse(_quantity.text) ?? 1); setState(() {}); })),
        const SizedBox(width: 7),
        Expanded(flex: 2, child: TextField(controller: _quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'مقدار', isDense: true), onChanged: (text) => widget.onChanged(product, widget.value.unitName, _parseQuantity(text)))),
        if (widget.onRemove != null) IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC35656), size: 18)),
      ]),
      const SizedBox(height: 7),
      Row(children: [Expanded(child: DropdownButtonFormField<String>(value: widget.value.unitName, decoration: const InputDecoration(labelText: 'واحد فروش', isDense: true), items: units.map((unit) => DropdownMenuItem(value: unit.name, child: Text('${unit.name} · ضریب ${persianDigits(unit.factor)} · نسخه ${persianDigits(unit.version)}', style: const TextStyle(fontSize: 9)))).toList(), onChanged: (value) { if (value == null) return; widget.onChanged(product, value, _parseQuantity(_quantity.text)); setState(() {}); })), const SizedBox(width: 10), Expanded(child: Text('معادل پایه: ${persianDigits((_parseQuantity(_quantity.text) * units.firstWhere((unit) => unit.name == widget.value.unitName).factor).toStringAsFixed(3))} ${product.baseUnitName}', style: const TextStyle(fontSize: 8, color: Color(0xFF758097))))]),
    ]));
  }

  double _parseQuantity(String text) => double.tryParse(_english(text).replaceAll(',', '').replaceAll('٬', '')) ?? 0;
  String _english(String text) { var value = text; for (var i = 0; i < 10; i++) value = value.replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i').replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i'); return value; }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.canConfirm, required this.canRecordPayment, required this.onConfirm, required this.onPayment, required this.onDetails});
  final Invoice invoice;
  final bool canConfirm, canRecordPayment;
  final VoidCallback onConfirm, onPayment, onDetails;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), child: Column(children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: const Color(0xFFF0EFFF), child: Icon(invoice.type == 'purchase' ? Icons.shopping_bag_outlined : Icons.receipt_long_outlined, color: pagePurple, size: 17)),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${invoice.number} · ${_invoiceType(invoice.type)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: pageInk)), Text('${invoice.customerName} · ${invoice.dateJalali}', style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF)))])),
          StatusBadge(invoice.status),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(formatToman(invoice.totalToman), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: pageInk)), Text(_mode(invoice.saleMode), style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF)))]),
        ]),
        const Divider(height: 18),
        Row(children: [Text('تخفیف ${formatToman(invoice.discountToman)}', style: const TextStyle(fontSize: 8, color: Color(0xFF758097))), const SizedBox(width: 14), Text('افزایش ${formatToman(invoice.surchargeToman)}', style: const TextStyle(fontSize: 8, color: Color(0xFF758097))), const Spacer(), TextButton.icon(onPressed: onDetails, icon: const Icon(Icons.visibility_outlined, size: 15), label: const Text('اقلام', style: TextStyle(fontSize: 8))), if (canRecordPayment) TextButton.icon(onPressed: onPayment, icon: const Icon(Icons.payments_outlined, size: 15), label: const Text('ثبت دریافت', style: TextStyle(fontSize: 8))), if (canConfirm) FilledButton.tonalIcon(onPressed: onConfirm, icon: const Icon(Icons.check_rounded, size: 15), label: const Text('تأیید و ثبت موجودی', style: TextStyle(fontSize: 8)))]),
      ])));
}

class _InvoiceStat extends StatelessWidget {
  const _InvoiceStat({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: 200, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [CircleAvatar(radius: 16, backgroundColor: const Color(0xFFF0EFFF), child: Icon(icon, size: 15, color: pagePurple)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF))), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))]))]))));
}

String _invoiceType(String value) => switch (value) { 'sale' => 'فروش', 'purchase' => 'خرید', 'quote' => 'پیش‌فاکتور', 'sale_return' => 'برگشت فروش', 'purchase_return' => 'برگشت خرید', _ => value };
String _mode(String value) => switch (value) { 'cash' => 'نقدی', 'cheque_direct' => 'چک مستقیم', 'investor' => 'سرمایه‌گذار', _ => value };
