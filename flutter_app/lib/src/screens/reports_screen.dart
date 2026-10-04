import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../core/formatters.dart';
import '../core/platform_export_stub.dart'
    if (dart.library.html) '../core/platform_export_web.dart' as platform_export;
import '../models/app_enums.dart';
import '../models/finance.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/page_components.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _report = 'فروش';

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(activeRoleProvider);
    final invoiceAsync = ref.watch(recordsProvider('invoices'));
    final itemAsync = ref.watch(recordsProvider('invoice_items'));
    final productsAsync = ref.watch(recordsProvider('products'));
    final movementAsync = ref.watch(recordsProvider('stock_movements'));
    final chequeAsync = ref.watch(recordsProvider('cheques'));
    final customerAsync = ref.watch(recordsProvider('customers'));
    final paymentAsync = ref.watch(recordsProvider('payments'));
    final costAsync = role == AppRole.admin ? ref.watch(recordsProvider('invoice_item_costs')) : const AsyncData<List<JsonMap>>(<JsonMap>[]);
    final invoices = (invoiceAsync.asData?.value ?? const <JsonMap>[]).map(Invoice.fromMap).toList();
    final items = itemAsync.asData?.value ?? const <JsonMap>[];
    final products = productsAsync.asData?.value ?? const <JsonMap>[];
    final movements = movementAsync.asData?.value ?? const <JsonMap>[];
    final cheques = (chequeAsync.asData?.value ?? const <JsonMap>[]).map(Cheque.fromMap).toList();
    final customers = (customerAsync.asData?.value ?? const <JsonMap>[]).map(Customer.fromMap).toList();
    final payments = paymentAsync.asData?.value ?? const <JsonMap>[];
    final costs = costAsync.asData?.value ?? const <JsonMap>[];
    final confirmedSales = invoices.where((invoice) => invoice.type == 'sale' && invoice.status == 'confirmed').toList();
    final totalSales = confirmedSales.fold<int>(0, (sum, invoice) => sum + invoice.totalToman);
    final stockRows = _stockRows(products, movements);
    final profit = role == AppRole.admin ? _grossProfit(confirmedSales, items, costs) : null;
    final today = _todaySales(confirmedSales);
    final loading = invoiceAsync.isLoading || itemAsync.isLoading || productsAsync.isLoading || movementAsync.isLoading || chequeAsync.isLoading || customerAsync.isLoading || paymentAsync.isLoading;

    final rows = switch (_report) {
      'فروش' => confirmedSales.map((invoice) => [invoice.dateJalali, invoice.number, invoice.customerName, formatToman(invoice.totalToman)]).toList(),
      'موجودی' => stockRows.map((row) => [row.name, row.code, '${persianDigits(row.stock)} ${row.unit}', '${persianDigits(row.minimum)} ${row.unit}']).toList(),
      'چک‌ها' => cheques.map((cheque) => [cheque.dueDateJalali, cheque.number, cheque.bank, _chequeType(cheque.type), _chequeStatus(cheque.status), formatToman(cheque.amountToman)]).toList(),
      _ => customers.map((customer) => [customer.code, customer.name, customer.phone, formatToman(customer.balanceToman)]).toList(),
    };
    final csv = _toCsv(_headers(_report), rows);
    final adminOnly = role == AppRole.admin;

    return RefreshIndicator(onRefresh: _reload, child: ListView(padding: const EdgeInsets.fromLTRB(22, 20, 22, 36), children: [
      PageHeading(title: 'گزارش‌ها و خروجی', subtitle: 'گزارش فروش، موجودی، سررسید چک و حساب مشتریان', trailing: IconButton(tooltip: 'چاپ صفحه', onPressed: _printReport, icon: const Icon(Icons.print_outlined)), action: FilledButton.icon(onPressed: () => _exportCsv(csv), icon: const Icon(Icons.download_outlined, size: 17), label: const Text('خروجی CSV'))),
      if (!adminOnly) const InfoPanel(icon: Icons.shield_outlined, text: 'گزارش این نقش فاقد قیمت خرید و سود است. داده‌ها از دسترسی‌های سرور PocketBase پیروی می‌کنند.'),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final stats = [
          _ReportStat(title: 'فروش تأییدشده', value: formatToman(totalSales), icon: Icons.account_balance_wallet_outlined, tint: const Color(0xFFE9F8F4)),
          _ReportStat(title: 'فروش روز جاری', value: formatToman(today), icon: Icons.today_outlined, tint: const Color(0xFFF0EFFF)),
          _ReportStat(title: 'چک‌های در جریان', value: persianDigits(cheques.where((row) => row.status == 'in_hand' || row.status == 'deposited').length), icon: Icons.payments_outlined, tint: const Color(0xFFFFF3E8)),
          _ReportStat(title: 'مطالبات مشتریان', value: formatToman(customers.fold<int>(0, (sum, row) => sum + row.balanceToman)), icon: Icons.groups_outlined, tint: const Color(0xFFEDF4FF)),
        ];
        final gap = 9.0;
        final columns = constraints.maxWidth > 1100 ? 4 : constraints.maxWidth > 650 ? 2 : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(spacing: gap, runSpacing: gap, children: [for (final stat in stats) SizedBox(width: width, child: stat)]);
      }),
      if (profit != null) ...[
        const SizedBox(height: 10),
        _AdminProfitCard(profit: profit),
      ],
      const SizedBox(height: 12),
      LoadingOrError(loading: loading, error: invoiceAsync.hasError ? invoiceAsync.error : productsAsync.hasError ? productsAsync.error : null, onRetry: _reload),
      Card(child: Padding(padding: const EdgeInsets.all(13), child: Wrap(spacing: 8, runSpacing: 7, children: [
        for (final name in const ['فروش', 'موجودی', 'چک‌ها', 'مانده مشتریان']) ChoiceChip(label: Text(name, style: const TextStyle(fontSize: 9)), selected: _report == name, onSelected: (_) => setState(() => _report = name)),
        const SizedBox(width: 8),
        OutlinedButton.icon(onPressed: () => _exportCsv(csv), icon: const Icon(Icons.copy_all_outlined, size: 15), label: const Text('کپی CSV', style: TextStyle(fontSize: 9))),
      ]))),
      const SizedBox(height: 10),
      if (_report == 'فروش') _SalesChart(invoices: confirmedSales),
      if (_report == 'فروش') const SizedBox(height: 10),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Expanded(child: Text('گزارش $_report', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))), Text('${persianDigits(rows.length)} ردیف', style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF)))]),
        const SizedBox(height: 8),
        if (rows.isEmpty) const EmptyPanel(title: 'داده‌ای برای گزارش وجود ندارد.', icon: Icons.bar_chart_rounded),
        if (rows.isNotEmpty) SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          columns: _headers(_report).map((header) => DataColumn(label: Text(header, style: const TextStyle(fontSize: 9)))).toList(),
          rows: rows.map((row) => DataRow(cells: row.map((value) => DataCell(Text(value, style: const TextStyle(fontSize: 9)))).toList())).toList(),
        )),
      ]))),
      const SizedBox(height: 10),
      if (_report == 'مانده مشتریان') _PaymentSummary(payments: payments),
    ]));
  }

  List<_StockRow> _stockRows(List<JsonMap> products, List<JsonMap> movements) {
    return products.map((row) {
      final product = Product.fromMap(row);
      final hasSnapshot = row.containsKey('stock_base') || row.containsKey('stockBase');
      var stock = hasSnapshot ? product.stockBase : 0.0;
      if (!hasSnapshot) {
        for (final movement in movements.where((item) => asString(item['product_id']) == product.id)) {
          final amount = asDouble(movement['quantity_in_base_unit']);
          final type = asString(movement['movement_type']);
          if (type == 'purchase_in' || type == 'transfer_in') stock += amount;
          if (type == 'sale_out' || type == 'transfer_out') stock -= amount;
          if (type == 'adjustment') stock += asString(movement['direction']) == 'decrease' ? -amount : amount;
        }
      }
      return _StockRow(name: product.name, code: product.code, stock: stock, minimum: product.minStock, unit: product.baseUnitName);
    }).toList()..sort((a, b) => a.stock.compareTo(b.stock));
  }

  int _grossProfit(List<Invoice> invoices, List<JsonMap> items, List<JsonMap> costs) {
    final invoiceIds = invoices.map((invoice) => invoice.id).toSet();
    final costByItem = {for (final row in costs) asString(row['invoice_item']): asInt(row['cost_total'])};
    var profit = 0;
    for (final item in items.where((row) => invoiceIds.contains(asString(row['invoice_id'])))) {
      profit += asInt(item['line_total']) - (costByItem[asString(item['id'])] ?? 0);
    }
    return profit;
  }

  int _todaySales(List<Invoice> invoices) {
    final now = Jalali.now();
    final date = '${persianDigits(now.year)}/${persianDigits(now.month.toString().padLeft(2, '0'))}/${persianDigits(now.day.toString().padLeft(2, '0'))}';
    return invoices.where((invoice) => invoice.dateJalali == date).fold<int>(0, (sum, invoice) => sum + invoice.totalToman);
  }

  List<String> _headers(String report) => switch (report) {
        'فروش' => const ['تاریخ شمسی', 'شماره فاکتور', 'مشتری', 'مبلغ کل (تومان)'],
        'موجودی' => const ['نام کالا', 'کد کالا', 'موجودی پایه', 'حداقل موجودی'],
        'چک‌ها' => const ['سررسید شمسی', 'شماره چک', 'بانک', 'نوع', 'وضعیت', 'مبلغ (تومان)'],
        _ => const ['کد', 'مشتری', 'تلفن', 'مانده (تومان)'],
      };

  String _toCsv(List<String> headers, List<List<String>> rows) {
    String escape(String value) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }

    return [headers, ...rows].map((row) => row.map(escape).join(',')).join('\r\n');
  }

  void _exportCsv(String csv) async {
    final ok = platform_export.downloadText('benafsheh-$_report.csv', 'text/csv;charset=utf-8', csv);
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) _toast('خروجی CSV در کلیپ‌بورد کپی شد؛ آن را در صفحه‌گسترده جای‌گذاری کنید.');
    } else if (mounted) {
      _toast('فایل CSV دانلود شد.');
    }
  }

  void _printReport() {
    final ok = platform_export.printCurrentPage();
    if (!ok) showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('چاپ گزارش'), content: const Text('برای خروجی چاپ روی این دستگاه، از گزینهٔ «خروجی CSV» استفاده کنید یا گزارش را کپی کنید و در نرم‌افزار صفحه‌گسترده چاپ بگیرید.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))]));
  }

  Future<void> _reload() async {
    for (final collection in ['invoices', 'invoice_items', 'products', 'stock_movements', 'cheques', 'customers', 'payments', 'invoice_item_costs']) {
      ref.invalidate(recordsProvider(collection));
    }
    await Future<void>.delayed(const Duration(milliseconds: 160));
  }

  String _chequeType(String type) => type == 'received' ? 'دریافتی' : 'پرداختی';
  String _chequeStatus(String value) => switch (value) { 'in_hand' => 'در دست', 'deposited' => 'واگذار به بانک', 'cleared' => 'وصول‌شده', 'bounced' => 'برگشتی', 'transferred' => 'واگذار شده', _ => value };
  void _toast(String message) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
}

class _StockRow {
  const _StockRow({required this.name, required this.code, required this.stock, required this.minimum, required this.unit});
  final String name, code, unit;
  final double stock, minimum;
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({required this.title, required this.value, required this.icon, required this.tint});
  final String title, value;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [Container(width: 35, height: 35, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: pagePurple, size: 17)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF))), Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)]))])));
}

class _AdminProfitCard extends StatelessWidget {
  const _AdminProfitCard({required this.profit});
  final int profit;
  @override
  Widget build(BuildContext context) => Card(color: const Color(0xFF111D3A), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFFB7B1FF), size: 20), const SizedBox(width: 9), const Expanded(child: Text('سود ناخالص فروش · فقط مدیر', style: TextStyle(color: Color(0xFFE9E7FF), fontSize: 10, fontWeight: FontWeight.w700))), Text(formatToman(profit), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))])));
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.invoices});
  final List<Invoice> invoices;
  @override
  Widget build(BuildContext context) {
    final buckets = List<int>.filled(7, 0);
    for (final invoice in invoices) {
      final tail = invoice.dateJalali.split('/').last;
      final normalized = tail.replaceAllMapped(RegExp(r'[۰-۹]'), (match) => '۰۱۲۳۴۵۶۷۸۹'.indexOf(match[0]!).toString());
      final day = int.tryParse(normalized);
      if (day != null) buckets[day % 7] += invoice.totalToman;
    }
    final maxValue = buckets.fold<int>(1, (max, value) => value > max ? value : max).toDouble();
    return Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('نمای نموداری فروش', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(height: 150, child: BarChart(BarChartData(
            maxY: maxValue * 1.2,
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF0F2F7), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            barGroups: List.generate(7, (index) => BarChartGroupData(x: index, barRods: [BarChartRodData(toY: buckets[index].toDouble(), color: const Color(0xFF776EE8), width: 15, borderRadius: BorderRadius.circular(5))])),
          ))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const ['روز ۱', '۲', '۳', '۴', '۵', '۶', '۷'].map((label) => Text(label, style: TextStyle(fontSize: 8, color: Color(0xFF929CAF)))).toList()),
        ])));
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.payments});
  final List<JsonMap> payments;
  @override
  Widget build(BuildContext context) {
    final total = payments.fold<int>(0, (sum, row) => sum + asInt(row['amount']));
    return Card(child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [const Icon(Icons.payments_outlined, color: pagePurple), const SizedBox(width: 8), const Expanded(child: Text('دریافت‌های ثبت‌شده', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))), Text(formatToman(total), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))])));
  }
}
