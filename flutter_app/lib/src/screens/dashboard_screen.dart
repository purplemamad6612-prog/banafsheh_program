import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../core/formatters.dart';
import '../models/app_enums.dart';
import '../models/finance.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/stat_card.dart';

const _deepNavy = Color(0xFF111D3A);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(activeRoleProvider);
    final productsAsync = role == AppRole.investor
        ? const AsyncData<List<JsonMap>>(<JsonMap>[])
        : ref.watch(recordsProvider('products'));
    final invoicesAsync = role == AppRole.investor || role == AppRole.warehouse
        ? const AsyncData<List<JsonMap>>(<JsonMap>[])
        : ref.watch(recordsProvider('invoices'));
    final chequesAsync = role == AppRole.admin || role == AppRole.accountant || role == AppRole.investor || role == AppRole.customer
        ? ref.watch(recordsProvider('cheques'))
        : const AsyncData<List<JsonMap>>(<JsonMap>[]);
    final dealsAsync = role == AppRole.admin || role == AppRole.accountant || role == AppRole.investor
        ? ref.watch(recordsProvider('investor_deals'))
        : const AsyncData<List<JsonMap>>(<JsonMap>[]);
    final customersAsync = role == AppRole.admin || role == AppRole.accountant || role == AppRole.sales || role == AppRole.customer
        ? ref.watch(recordsProvider('customers'))
        : const AsyncData<List<JsonMap>>(<JsonMap>[]);
    final rawProducts = productsAsync.asData?.value ?? const <JsonMap>[];
    final products = rawProducts.map(Product.fromMap).toList();
    final stockAsync = role == AppRole.customer || role == AppRole.investor
        ? const AsyncData<Map<String, double>>(<String, double>{})
        : ref.watch(stockSummaryProvider);
    final movementRecordsAsync = role == AppRole.warehouse || role == AppRole.admin
        ? ref.watch(recordsProvider('stock_movements'))
        : const AsyncData<List<JsonMap>>(<JsonMap>[]);
    final stockByProduct = stockAsync.asData?.value ?? const <String, double>{};
    final invoices = (invoicesAsync.asData?.value ?? const <JsonMap>[]).map(Invoice.fromMap).toList();
    final cheques = (chequesAsync.asData?.value ?? const <JsonMap>[]).map(Cheque.fromMap).toList();
    final deals = (dealsAsync.asData?.value ?? const <JsonMap>[]).map(InvestorDeal.fromMap).toList();
    final lowStock = products.where((product) => stockByProduct.containsKey(product.id) && stockByProduct[product.id]! <= product.minStock).toList();
    final customerRows = customersAsync.asData?.value ?? const <JsonMap>[];
    final customerBalance = customerRows.isEmpty ? 0 : Customer.fromMap(customerRows.first).balanceToman;
    final pendingCheques = cheques.where((cheque) => cheque.status == 'in_hand' || cheque.status == 'deposited').toList();
    final sales = invoices.where((invoice) => invoice.type == 'sale' && invoice.status == 'confirmed').toList();
    final saleTotal = sales.fold<int>(0, (sum, invoice) => sum + invoice.totalToman);
    final queued = ref.watch(movementQueueProvider).length;
    final loading = productsAsync.isLoading || stockAsync.isLoading || movementRecordsAsync.isLoading || invoicesAsync.isLoading || chequesAsync.isLoading || dealsAsync.isLoading || customersAsync.isLoading;

    final stats = switch (role) {
      AppRole.warehouse => <_Metric>[
          _Metric('کالاهای فعال', persianDigits(products.length), 'قلم کالا', Icons.inventory_2_outlined),
          _Metric('گردش‌های امروز', persianDigits(movementRecordsAsync.asData?.value.length ?? 0), 'سند انبار', Icons.swap_horiz_rounded, tint: const Color(0xFFE9F8F4)),
          _Metric('موجودی کم', persianDigits(lowStock.length), 'نیازمند رسیدگی', Icons.warning_amber_rounded, tint: const Color(0xFFFFF3E8)),
          _Metric('در صف همگام‌سازی', persianDigits(queued), 'ذخیره محلی', Icons.sync_rounded, tint: const Color(0xFFEDF4FF)),
        ],
      AppRole.investor => <_Metric>[
          _Metric('معاملات من', persianDigits(deals.length), 'معامله', Icons.trending_up_rounded),
          _Metric('سود معاملات من', formatToman(deals.fold<int>(0, (sum, item) => sum + item.investorProfitToman), withUnit: false), 'تومان', Icons.wallet_outlined, tint: const Color(0xFFE9F8F4)),
          _Metric('چک‌های من', persianDigits(cheques.length), 'فقره', Icons.receipt_long_rounded, tint: const Color(0xFFFFF3E8)),
          _Metric('تسویه‌های باز', persianDigits(deals.where((item) => item.status == 'open').length), 'معامله', Icons.account_balance_wallet_outlined, tint: const Color(0xFFEDF4FF)),
        ],
      AppRole.customer => <_Metric>[
          _Metric('مانده حساب شما', formatToman(customerBalance, withUnit: false), 'تومان', Icons.account_balance_wallet_outlined),
          _Metric('فاکتورهای شما', persianDigits(invoices.length), 'فقره', Icons.receipt_long_rounded, tint: const Color(0xFFE9F8F4)),
          _Metric('چک‌های ثبت‌شده', persianDigits(cheques.length), 'فقره', Icons.payments_outlined, tint: const Color(0xFFFFF3E8)),
          _Metric('سفارش‌های جاری', persianDigits(invoices.where((item) => item.status == 'draft').length), 'سفارش', Icons.inventory_2_outlined, tint: const Color(0xFFEDF4FF)),
        ],
      AppRole.accountant => <_Metric>[
          _Metric('فروش ثبت‌شده', formatToman(saleTotal, withUnit: false), 'تومان', Icons.account_balance_wallet_outlined),
          _Metric('فاکتورهای فروش', persianDigits(sales.length), 'فقره', Icons.receipt_long_rounded, tint: const Color(0xFFE9F8F4)),
          _Metric('چک‌های در جریان', persianDigits(pendingCheques.length), 'فقره', Icons.payments_outlined, tint: const Color(0xFFFFF3E8)),
          _Metric('مشتریان', persianDigits(customerRows.length), 'مشتری', Icons.groups_outlined, tint: const Color(0xFFEDF4FF)),
        ],
      _ => <_Metric>[
          _Metric('فروش امروز', formatToman(saleTotal, withUnit: false), 'تومان', Icons.account_balance_wallet_outlined),
          _Metric('فاکتورهای تأییدشده', persianDigits(sales.length), 'فقره', Icons.receipt_long_rounded, tint: const Color(0xFFE9F8F4)),
          _Metric('موجودی کم', persianDigits(lowStock.length), 'قلم کالا', Icons.warning_amber_rounded, tint: const Color(0xFFFFF3E8)),
          _Metric('چک‌های سررسید', persianDigits(pendingCheques.length), 'فقره', Icons.payments_outlined, tint: const Color(0xFFEDF4FF)),
        ],
    };

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recordsProvider('products'));
        ref.invalidate(recordsProvider('invoices'));
        ref.invalidate(recordsProvider('cheques'));
        ref.invalidate(recordsProvider('investor_deals'));
        ref.invalidate(recordsProvider('customers'));
        ref.invalidate(stockSummaryProvider);
        ref.invalidate(recordsProvider('stock_movements'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
        children: [
          Row(children: [
            const Icon(Icons.waving_hand_rounded, color: Color(0xFF776EE8), size: 25),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greeting(role), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF202B43))),
              Text('خلاصه فعالیت امروز · ${formatJalaliLong(Jalali.now())}', style: const TextStyle(fontSize: 10, color: Color(0xFF9099AB))),
            ])),
            IconButton(tooltip: 'تازه‌سازی', onPressed: () { ref.invalidate(recordsProvider('products')); ref.invalidate(recordsProvider('invoices')); ref.invalidate(recordsProvider('cheques')); ref.invalidate(recordsProvider('investor_deals')); ref.invalidate(recordsProvider('customers')); ref.invalidate(stockSummaryProvider); ref.invalidate(recordsProvider('stock_movements')); }, icon: const Icon(Icons.refresh_rounded)),
          ]),
          const SizedBox(height: 17),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          if (stockAsync.hasError)
            LoadingOrError(loading: false, error: stockAsync.error, onRetry: () => ref.invalidate(stockSummaryProvider)),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth > 1180 ? 4 : constraints.maxWidth > 610 ? 2 : 1;
            final gap = 11.0;
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(spacing: gap, runSpacing: gap, children: [
              for (final metric in stats)
                SizedBox(width: width, child: StatCard(title: metric.title, value: metric.value, caption: metric.caption, icon: metric.icon, tint: metric.tint)),
            ]);
          }),
          if (role == AppRole.warehouse) ...[
            const SizedBox(height: 14),
            _OfflineBanner(queued: queued),
          ],
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 800;
            final chart = _SalesTrend(role: role, total: saleTotal);
            final side = role == AppRole.warehouse ? _WarehouseActions() : _QuickStats(role: role, pendingCheques: pendingCheques.length);
            if (narrow) return Column(children: [chart, const SizedBox(height: 12), side]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 7, child: chart), const SizedBox(width: 12), Expanded(flex: 4, child: side)]);
          }),
          const SizedBox(height: 14),
          if (role != AppRole.customer && role != AppRole.investor)
            _LowStockList(products: lowStock.take(5).toList(), role: role, stockByProduct: stockByProduct),
        ],
      ),
    );
  }

  String _greeting(AppRole role) => switch (role) {
        AppRole.admin => 'روز بخیر، مدیر گرامی 👋',
        AppRole.accountant => 'روز بخیر، حسابدار گرامی 👋',
        AppRole.warehouse => 'سلام، انباردار گرامی 👋',
        AppRole.sales => 'روز بخیر، فروشنده گرامی 👋',
        AppRole.investor => 'سلام، سرمایه‌گذار گرامی 👋',
        AppRole.customer => 'سلام، مشتری گرامی 👋',
      };
}

class _Metric {
  const _Metric(this.title, this.value, this.caption, this.icon, {this.tint = const Color(0xFFF0EFFF)});
  final String title, value, caption;
  final IconData icon;
  final Color tint;
}

class _SalesTrend extends StatelessWidget {
  const _SalesTrend({required this.role, required this.total});
  final AppRole role;
  final int total;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(role == AppRole.warehouse ? 'گردش موجودی' : role == AppRole.customer ? 'خریدهای شما' : 'روند فروش', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('نمای کلی عملکرد هفتگی', style: TextStyle(fontSize: 9, color: Color(0xFF929CAF))),
            const SizedBox(height: 12),
            Text(role == AppRole.warehouse ? 'داده‌های گردش به‌روز' : formatToman(total, withUnit: false), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SizedBox(
              height: 185,
              child: LineChart(LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 100,
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25, getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF0F2F7), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 22), FlSpot(1, 38), FlSpot(2, 34), FlSpot(3, 67), FlSpot(4, 54), FlSpot(5, 78), FlSpot(6, 70)],
                    isCurved: true,
                    color: const Color(0xFF776EE8),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF776EE8).withOpacity(.1)),
                  ),
                ],
              )),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('شنبه'), Text('یکشنبه'), Text('دوشنبه'), Text('سه‌شنبه'), Text('چهارشنبه'), Text('پنجشنبه'), Text('جمعه')].map((widget) => DefaultTextStyle(style: TextStyle(fontSize: 8, color: Color(0xFF929CAF)), child: widget)).toList()),
          ]),
        ),
      );
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.queued});
  final int queued;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _deepNavy, borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFA9A3FF), size: 20),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('حالت آفلاین انبار', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            Text('گردش کالا روی دستگاه ذخیره می‌شود و بعداً همگام می‌شود.', style: TextStyle(color: Color(0xFFAAB7D0), fontSize: 9)),
          ])),
          Text('${persianDigits(queued)} مورد در صف', style: const TextStyle(color: Color(0xFFD8D9FF), fontSize: 9)),
        ]),
      );
}

class _WarehouseActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('عملیات سریع انبار', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => ref.read(activePageProvider.notifier).state = AppPage.inventory, icon: const Icon(Icons.swap_horiz_rounded), label: const Text('ثبت گردش کالا')),
          OutlinedButton.icon(onPressed: () => ref.read(activePageProvider.notifier).state = AppPage.products, icon: const Icon(Icons.search_rounded), label: const Text('جستجوی کالا')),
        ])),
      );
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.role, required this.pendingCheques});
  final AppRole role;
  final int pendingCheques;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(role == AppRole.investor ? 'اطلاعات پرتفوی شما' : 'یادآوری‌های امروز', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.payments_outlined, label: 'چک‌های در جریان', value: persianDigits(pendingCheques)),
          const _InfoRow(icon: Icons.calendar_month_outlined, label: 'تاریخ شمسی', value: 'امروز'),
          const _InfoRow(icon: Icons.shield_outlined, label: 'سطح دسترسی', value: 'بر اساس نقش'),
        ])),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Icon(icon, size: 17, color: const Color(0xFF776EE8)), const SizedBox(width: 8), Expanded(child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF66718A)))), Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))]));
}

class _LowStockList extends StatelessWidget {
  const _LowStockList({required this.products, required this.role, required this.stockByProduct});
  final List<Product> products;
  final AppRole role;
  final Map<String, double> stockByProduct;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('هشدار موجودی', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('کالاهای نزدیک به حداقل موجودی', style: TextStyle(fontSize: 9, color: Color(0xFF929CAF))),
          const SizedBox(height: 8),
          if (products.isEmpty) const Text('موردی برای نمایش نیست.', style: TextStyle(fontSize: 10, color: Color(0xFF929CAF))),
          for (final product in products) ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: Color(0xFFFFF3E8), child: Icon(Icons.warning_amber_rounded, color: Color(0xFFCB8237), size: 18)),
            title: Text(product.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            subtitle: Text('${product.code} · حداقل ${persianDigits(product.minStock)} ${product.baseUnitName}', style: const TextStyle(fontSize: 9)),
            trailing: Text('${persianDigits(stockByProduct[product.id] ?? 0)} ${product.baseUnitName}', style: const TextStyle(fontSize: 9, color: Color(0xFFCB8237))),
          ),
        ])),
      );
}
