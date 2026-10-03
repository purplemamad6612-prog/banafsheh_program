import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../core/formatters.dart';
import '../models/app_enums.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/jalali_date_field.dart';
import '../widgets/page_components.dart';
import '../widgets/status_badge.dart';
import '../widgets/unit_converter.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _filter = 'همه گردش‌ها';

  @override
  Widget build(BuildContext context) {
    final movementsAsync = ref.watch(recordsProvider('stock_movements'));
    final productsAsync = ref.watch(recordsProvider('products'));
    final unitsAsync = ref.watch(recordsProvider('product_units'));
    final warehousesAsync = ref.watch(recordsProvider('warehouses'));
    final queue = ref.watch(movementQueueProvider);
    final productsRaw = productsAsync.asData?.value ?? const <JsonMap>[];
    final unitRows = unitsAsync.asData?.value ?? const <JsonMap>[];
    final products = productsRaw.map((row) {
      final related = unitRows.where((unit) => asString(unit['product_id']) == asString(row['id'])).toList();
      return Product.fromMap({...row, if (related.isNotEmpty) 'units': related});
    }).toList();
    final warehouses = warehousesAsync.asData?.value ?? const <JsonMap>[];
    final rows = movementsAsync.asData?.value ?? const <JsonMap>[];
    final filtered = rows.where((row) => _filter == 'همه گردش‌ها' || _movementLabel(asString(row['movement_type'])) == _filter).toList();
    final isWarehouse = ref.watch(activeRoleProvider) == AppRole.warehouse;

    return RefreshIndicator(onRefresh: _reload, child: ListView(padding: const EdgeInsets.fromLTRB(22, 20, 22, 36), children: [
      PageHeading(
        title: 'انبار و گردش کالا',
        subtitle: 'ثبت رسید، حواله، انتقال و اصلاح موجودی بر اساس واحد پایه',
        action: FilledButton.icon(onPressed: products.isEmpty || warehouses.isEmpty ? null : () => _showMovementDialog(context, products, warehouses), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('ثبت گردش')),
      ),
      if (isWarehouse) const InfoPanel(icon: Icons.wifi_off_rounded, text: 'گردش‌ها ابتدا به‌صورت محلی و پایدار ذخیره می‌شوند؛ همگام‌سازی با سرور پس از اتصال انجام می‌شود.', color: Color(0xFFEEF4FF)),
      if (!isWarehouse) const InfoPanel(icon: Icons.inventory_2_outlined, text: 'نمای مدیریتی گردش‌های ثبت‌شده؛ مانده موجودی با جمع ورودها و خروج‌های پایه به‌دست می‌آید.'),
      const SizedBox(height: 13),
      Wrap(spacing: 10, runSpacing: 9, children: [
        _InventoryStat(label: 'سندهای ثبت‌شده', value: persianDigits(rows.length), icon: Icons.receipt_long_outlined),
        _InventoryStat(label: 'در صف آفلاین', value: persianDigits(queue.length), icon: Icons.sync_rounded, alert: queue.isNotEmpty),
        _InventoryStat(label: 'انبارها', value: persianDigits(warehouses.length), icon: Icons.home_work_outlined),
      ]),
      const SizedBox(height: 12),
      if (queue.isNotEmpty) _OfflineQueueCard(queue: queue, onSync: _sync),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        const Icon(Icons.filter_alt_outlined, size: 18, color: pagePurple), const SizedBox(width: 8),
        SizedBox(width: 210, child: DropdownButtonFormField<String>(value: _filter, decoration: const InputDecoration(labelText: 'نوع سند', isDense: true), items: ['همه گردش‌ها', 'رسید خرید', 'حواله خروج', 'انتقال', 'اصلاح موجودی'].map((value) => DropdownMenuItem(value: value, child: Text(value, style: const TextStyle(fontSize: 10)))).toList(), onChanged: (value) => setState(() => _filter = value ?? 'همه گردش‌ها'))),
        const Spacer(), Text('${persianDigits(filtered.length)} سند', style: const TextStyle(fontSize: 9, color: Color(0xFF929CAF))),
      ]))),
      const SizedBox(height: 8),
      LoadingOrError(loading: movementsAsync.isLoading || productsAsync.isLoading || warehousesAsync.isLoading, error: movementsAsync.hasError ? movementsAsync.error : productsAsync.hasError ? productsAsync.error : warehousesAsync.error, onRetry: _reload),
      if (!movementsAsync.isLoading && filtered.isEmpty) const EmptyPanel(title: 'گردشی برای نمایش وجود ندارد.', icon: Icons.swap_horiz_rounded),
      if (filtered.isNotEmpty) Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
        columns: const [DataColumn(label: Text('تاریخ')), DataColumn(label: Text('کالا')), DataColumn(label: Text('نوع')), DataColumn(label: Text('انبار')), DataColumn(label: Text('مقدار پایه')), DataColumn(label: Text('واحد/مقدار')), DataColumn(label: Text('مرجع'))],
        rows: filtered.map((row) {
          final product = products.where((item) => item.id == asString(row['product_id'])).firstOrNull;
          final type = asString(row['movement_type'], fallback: asString(row['type']));
          return DataRow(cells: [
            DataCell(Text(asString(row['business_date_jalali'] ?? row['date']), style: const TextStyle(fontSize: 9))),
            DataCell(Text(product?.name ?? asString(row['product_name'], fallback: 'کالای ثبت‌شده'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700))),
            DataCell(StatusBadge(type, label: _movementLabel(type))),
            DataCell(Text(_warehouseName(asString(row['warehouse_id']), warehouses, fallback: asString(row['warehouse'])), style: const TextStyle(fontSize: 9))),
            DataCell(Text('${persianDigits(asDouble(row['quantity_in_base_unit'] ?? row['quantityBase']))} ${product?.baseUnitName ?? ''}', style: const TextStyle(fontSize: 9))),
            DataCell(Text('${persianDigits(asDouble(row['quantity_in_used_unit'] ?? row['quantity']))} ${asString(row['unit_used'] ?? row['unit'])}', style: const TextStyle(fontSize: 9))),
            DataCell(Text(asString(row['reference_document_id'] ?? row['reference'], fallback: '—'), style: const TextStyle(fontSize: 9))),
          ]);
        }).toList(),
      ))),
    ]));
  }

  String _warehouseName(String id, List<JsonMap> warehouses, {String fallback = ''}) {
    final row = warehouses.where((item) => asString(item['id']) == id).firstOrNull;
    return row == null ? (fallback.isEmpty ? '—' : fallback) : asString(row['name']);
  }

  String _movementLabel(String type) => switch (type) {
        'purchase_in' => 'رسید خرید',
        'sale_out' => 'حواله خروج',
        'transfer_in' || 'transfer_out' => 'انتقال',
        'adjustment' => 'اصلاح موجودی',
        _ => type.isEmpty ? 'نامشخص' : type,
      };

  Future<void> _showMovementDialog(BuildContext context, List<Product> products, List<JsonMap> warehouses) async {
    if (products.isEmpty || warehouses.isEmpty) return;
    Product selectedProduct = products.first;
    String warehouseId = asString(warehouses.first['id']);
    String destinationId = warehouses.length > 1 ? asString(warehouses[1]['id']) : '';
    String type = 'purchase_in';
    String jalali = formatJalaliDate(Jalali.now());
    double quantity = 1, quantityBase = 1, factor = 1;
    String unitName = selectedProduct.baseUnitName;
    String direction = 'increase';
    var busy = false;
    final referenceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: const Text('ثبت گردش انبار', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 470, child: SingleChildScrollView(child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<Product>(value: selectedProduct, decoration: const InputDecoration(labelText: 'کالا'), items: products.map((product) => DropdownMenuItem(value: product, child: Text('${product.code} · ${product.name}', overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => setDialog(() { selectedProduct = value ?? selectedProduct; unitName = selectedProduct.baseUnitName; factor = 1; quantityBase = quantity; })),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'نوع گردش'), items: const [DropdownMenuItem(value: 'purchase_in', child: Text('رسید خرید / ورود')), DropdownMenuItem(value: 'sale_out', child: Text('حواله خروج')), DropdownMenuItem(value: 'transfer_out', child: Text('انتقال بین انبارها')), DropdownMenuItem(value: 'adjustment', child: Text('اصلاح موجودی'))], onChanged: (value) => setDialog(() => type = value ?? type)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: warehouseId, decoration: const InputDecoration(labelText: 'انبار مبدأ / ثبت'), items: warehouses.map((row) => DropdownMenuItem(value: asString(row['id']), child: Text(asString(row['name'])))).toList(), onChanged: (value) => setDialog(() => warehouseId = value ?? warehouseId)),
            if (type == 'transfer_out') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(value: destinationId.isEmpty ? null : destinationId, decoration: const InputDecoration(labelText: 'انبار مقصد'), items: warehouses.where((row) => asString(row['id']) != warehouseId).map((row) => DropdownMenuItem(value: asString(row['id']), child: Text(asString(row['name'])))).toList(), onChanged: (value) => setDialog(() => destinationId = value ?? destinationId)),
            ],
            if (type == 'adjustment') SwitchListTile(title: const Text('کاهش موجودی', style: TextStyle(fontSize: 10)), value: direction == 'decrease', onChanged: (value) => setDialog(() => direction = value ? 'decrease' : 'increase')),
            const SizedBox(height: 8),
            UnitConverter(product: selectedProduct, onChanged: (qty, unit, base) => setDialog(() { quantity = qty; unitName = unit.name; factor = unit.factor; quantityBase = base; })),
            const SizedBox(height: 8),
            JalaliDateField(initialDate: Jalali.now(), onChanged: (date) => jalali = formatJalaliDate(date)),
            const SizedBox(height: 8),
            TextFormField(controller: referenceController, decoration: const InputDecoration(labelText: 'شماره مرجع / توضیح اختیاری')),
          ])))),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton.icon(onPressed: busy ? null : () async {
            if (!(formKey.currentState?.validate() ?? true)) return;
            if (quantity <= 0 || quantityBase <= 0) { _toast('مقدار باید بزرگ‌تر از صفر باشد.'); return; }
            if (type == 'transfer_out' && (destinationId.isEmpty || destinationId == warehouseId)) { _toast('انبار مقصد متفاوت را انتخاب کنید.'); return; }
            setDialog(() => busy = true);
            final id = 'local-${DateTime.now().microsecondsSinceEpoch}';
            final syncId = 'm-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
            final source = warehouses.where((row) => asString(row['id']) == warehouseId).firstOrNull!;
            final dest = warehouses.where((row) => asString(row['id']) == destinationId).firstOrNull;
            final movement = StockMovement(
              id: id, syncId: syncId, productId: selectedProduct.id, productCode: selectedProduct.code,
              productName: selectedProduct.name, warehouse: asString(source['name']), warehouseId: warehouseId,
              destinationWarehouse: dest == null ? '' : asString(dest['name']), type: type, quantityBase: quantityBase,
              unitName: unitName, quantity: quantity, conversionFactor: factor, businessDateJalali: jalali,
              reference: referenceController.text.trim(), direction: direction, clientTimestamp: DateTime.now().toUtc().toIso8601String(),
            );
            try {
              await ref.read(businessRepositoryProvider).recordOfflineMovement(movement.toQueuePayload());
              if (context.mounted) Navigator.pop(dialogContext);
              _toast('گردش به‌صورت محلی ذخیره شد؛ در صورت نبود سرور در صف همگام‌سازی باقی می‌ماند.');
              _reload();
            } catch (error) {
              _toast('ثبت محلی انجام نشد: $error');
              setDialog(() => busy = false);
            }
          }, icon: const Icon(Icons.save_outlined, size: 16), label: busy ? const Text('در حال ثبت…') : const Text('ثبت امن'))],
        )));
    referenceController.dispose();
  }

  Future<void> _sync() async {
    final count = await ref.read(businessRepositoryProvider).syncPendingMovements();
    ref.invalidate(movementQueueProvider);
    _toast(count > 0 ? '${persianDigits(count)} گردش همگام شد.' : 'اتصالی برقرار نشد یا موردی برای همگام‌سازی نبود؛ داده محلی حفظ شده است.');
    _reload();
  }

  Future<void> _reload() async {
    ref.invalidate(recordsProvider('stock_movements'));
    ref.invalidate(stockSummaryProvider);
    ref.invalidate(recordsProvider('products'));
    ref.invalidate(recordsProvider('product_units'));
    ref.invalidate(recordsProvider('warehouses'));
    ref.invalidate(movementQueueProvider);
    await Future<void>.delayed(const Duration(milliseconds: 160));
  }

  void _toast(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
}

class _InventoryStat extends StatelessWidget {
  const _InventoryStat({required this.label, required this.value, required this.icon, this.alert = false});
  final String label, value;
  final IconData icon;
  final bool alert;
  @override
  Widget build(BuildContext context) => SizedBox(width: 172, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [CircleAvatar(radius: 16, backgroundColor: alert ? const Color(0xFFFFF3E8) : const Color(0xFFF0EFFF), child: Icon(icon, size: 15, color: alert ? const Color(0xFFCA7C31) : pagePurple)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF))), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))]))]))));
}

class _OfflineQueueCard extends StatelessWidget {
  const _OfflineQueueCard({required this.queue, required this.onSync});
  final List<JsonMap> queue;
  final VoidCallback onSync;
  @override
  Widget build(BuildContext context) => Card(color: const Color(0xFF111D3A), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        const Icon(Icons.cloud_upload_outlined, color: Color(0xFFA9A3FF), size: 20), const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('گردش‌های آفلاین آماده ارسال', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)), Text('${persianDigits(queue.length)} مورد روی دستگاه نگهداری شده است؛ در تعارض یا قطع شبکه حذف نمی‌شود.', style: const TextStyle(color: Color(0xFFB2BCD1), fontSize: 8))])),
        FilledButton.tonalIcon(onPressed: onSync, icon: const Icon(Icons.sync_rounded, size: 15), label: const Text('همگام‌سازی', style: TextStyle(fontSize: 9))),
      ])));
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
