import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../models/app_enums.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/page_components.dart';
import '../widgets/status_badge.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});
  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _search = TextEditingController();
  String _group = 'همه گروه‌ها';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(activeRoleProvider);
    final productsAsync = ref.watch(recordsProvider('products'));
    final unitsAsync = ref.watch(recordsProvider('product_units'));
    final hidesStock = role == AppRole.customer || role == AppRole.investor;
    final stockAsync = hidesStock ? const AsyncData<Map<String, double>>(<String, double>{}) : ref.watch(stockSummaryProvider);
    final groupsAsync = ref.watch(recordsProvider('product_groups'));
    final groups = groupsAsync.asData?.value ?? const <JsonMap>[];
    final productRows = productsAsync.asData?.value ?? const <JsonMap>[];
    final stocks = stockAsync.asData?.value ?? const <String, double>{};
    final unitRows = unitsAsync.asData?.value ?? const <JsonMap>[];
    final products = productRows.map((row) {
      final id = asString(row['id']);
      final linked = unitRows.where((unit) => asString(unit['product_id']) == id).toList();
      final map = <String, dynamic>{...row};
      if (linked.isNotEmpty) map['units'] = linked;
      final group = groups.where((item) => asString(item['id']) == asString(row['product_group_id'])).firstOrNull;
      if (group != null) map['group_name'] = asString(group['name']);
      return Product.fromMap(map);
    }).toList();
    final groupNames = <String>{'همه گروه‌ها', ...products.map((product) => product.groupName)}.toList();
    final filtered = products.where((product) {
      final query = _search.text.trim().toLowerCase();
      final matchesQuery = query.isEmpty || product.name.toLowerCase().contains(query) || product.code.toLowerCase().contains(query);
      final matchesGroup = _group == 'همه گروه‌ها' || product.groupName == _group;
      return product.isActive && matchesQuery && matchesGroup;
    }).toList();
    final lowCount = hidesStock ? 0 : products.where((product) => _stock(product, stocks) <= product.minStock).length;
    final canSeeSalePrice = role == AppRole.admin || role == AppRole.accountant || role == AppRole.sales || role == AppRole.customer;
    final isAdmin = role == AppRole.admin;
    final loading = productsAsync.isLoading || unitsAsync.isLoading || groupsAsync.isLoading || stockAsync.isLoading;

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(padding: const EdgeInsets.fromLTRB(22, 20, 22, 35), children: [
        PageHeading(
          title: 'کالاها و قیمت‌گذاری',
          subtitle: 'مدیریت کالا، واحدهای نسخه‌دار و مشاهده موجودی پایه',
          action: isAdmin ? FilledButton.icon(onPressed: () => _addProduct(context, groups), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('کالای جدید')) : null,
          trailing: IconButton(tooltip: 'تازه‌سازی', onPressed: _reload, icon: const Icon(Icons.refresh_rounded)),
        ),
        if (role == AppRole.warehouse) const InfoPanel(icon: Icons.visibility_off_outlined, text: 'نمای انبار فاقد قیمت خرید و فروش است؛ موجودی بر اساس واحد پایه محاسبه می‌شود.'),
        if (role == AppRole.investor) const InfoPanel(icon: Icons.shield_outlined, text: 'اطلاعات قیمت خرید، حاشیه سود و فروش عمومی برای این نقش در دسترس نیست.'),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(child: _MiniStat(label: 'کالاهای فعال', value: persianDigits(products.where((product) => product.isActive).length), icon: Icons.inventory_2_outlined)),
          const SizedBox(width: 9),
          Expanded(child: _MiniStat(label: hidesStock ? 'اطلاعات اختصاصی' : 'موجودی زیر حد', value: hidesStock ? 'نمایش امن' : persianDigits(lowCount), icon: hidesStock ? Icons.shield_outlined : Icons.warning_amber_rounded, alert: !hidesStock)),
        ]),
        const SizedBox(height: 13),
        Card(child: Padding(padding: const EdgeInsets.all(13), child: Wrap(spacing: 9, runSpacing: 9, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(width: 280, child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'جستجوی نام یا کد کالا', isDense: true))),
          SizedBox(width: 190, child: DropdownButtonFormField<String>(value: groupNames.contains(_group) ? _group : 'همه گروه‌ها', decoration: const InputDecoration(labelText: 'گروه کالا', isDense: true), items: groupNames.map((group) => DropdownMenuItem(value: group, child: Text(group, style: const TextStyle(fontSize: 10)))).toList(), onChanged: (value) => setState(() => _group = value ?? 'همه گروه‌ها'))),
          Text('${persianDigits(filtered.length)} کالا', style: const TextStyle(fontSize: 9, color: Color(0xFF828CA1))),
        ]))),
        const SizedBox(height: 9),
        LoadingOrError(loading: loading, error: productsAsync.hasError ? productsAsync.error : unitsAsync.hasError ? unitsAsync.error : groupsAsync.hasError ? groupsAsync.error : stockAsync.error, onRetry: _reload),
        if (!loading && filtered.isEmpty) const EmptyPanel(title: 'کالایی مطابق جستجو پیدا نشد.'),
        LayoutBuilder(builder: (context, constraints) {
          final cols = constraints.maxWidth > 1050 ? 3 : constraints.maxWidth > 660 ? 2 : 1;
          final gap = 10.0;
          final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (final product in filtered)
              SizedBox(width: width, child: _ProductCard(
                product: product,
                stock: _stock(product, stocks),
                showStock: !hidesStock,
                canSeeSalePrice: canSeeSalePrice,
                isAdmin: isAdmin,
                onUnits: () => _addUnit(context, product),
                onInventory: () => ref.read(activePageProvider.notifier).state = AppPage.inventory,
              )),
          ]);
        }),
      ]),
    );
  }

  double _stock(Product product, Map<String, double> stocks) => stocks[product.id] ?? product.stockBase;

  Future<void> _reload() async {
    ref.invalidate(recordsProvider('products'));
    ref.invalidate(recordsProvider('product_units'));
    ref.invalidate(recordsProvider('product_groups'));
    ref.invalidate(stockSummaryProvider);
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }

  Future<void> _addProduct(BuildContext context, List<JsonMap> groups) async {
    final code = TextEditingController();
    final name = TextEditingController();
    final unit = TextEditingController(text: 'عدد');
    final min = TextEditingController(text: '0');
    final key = GlobalKey<FormState>();
    String? selectedGroupId;
    var busy = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: const Text('افزودن کالای جدید', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 410, child: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: code, decoration: const InputDecoration(labelText: 'کد کالا'), validator: (v) => v == null || v.trim().isEmpty ? 'کد کالا الزامی است.' : null),
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'نام کالا'), validator: (v) => v == null || v.trim().isEmpty ? 'نام کالا الزامی است.' : null),
            DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'گروه کالا'), value: selectedGroupId, items: [const DropdownMenuItem<String>(value: null, child: Text('بدون گروه')), ...groups.map((row) => DropdownMenuItem(value: asString(row['id']), child: Text(asString(row['name']))))], onChanged: (value) => setDialog(() => selectedGroupId = value)),
            TextFormField(controller: unit, decoration: const InputDecoration(labelText: 'واحد پایه'), validator: (v) => v == null || v.trim().isEmpty ? 'واحد پایه الزامی است.' : null),
            TextFormField(controller: min, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'حداقل موجودی'), validator: _numberValidator),
            const SizedBox(height: 9),
            const InfoPanel(icon: Icons.lock_outline_rounded, text: 'قیمت خرید یا سود در فرم کالا ثبت نمی‌شود؛ محاسبه قیمت فروش باید از سرور انجام شود.'),
          ])))),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            if (!(key.currentState?.validate() ?? false)) return;
            setDialog(() => busy = true);
            try {
              final minimum = double.parse(min.text.replaceAll(',', ''));
              final body = <String, dynamic>{
                'code': code.text.trim(), 'name': name.text.trim(), 'base_unit_name': unit.text.trim(),
                'min_stock': minimum, 'is_active': true,
              };
              if (selectedGroupId != null && selectedGroupId!.isNotEmpty) body['product_group_id'] = selectedGroupId;
              await ref.read(businessRepositoryProvider).saveRecord('products', body);
              if (context.mounted) Navigator.pop(dialogContext);
              _reload();
              _toast('کالا با موفقیت ثبت شد.');
            } catch (error) {
              if (context.mounted) _toast('$error');
              setDialog(() => busy = false);
            }
          }, child: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ذخیره'))],
        )));
    code.dispose(); name.dispose(); unit.dispose(); min.dispose();
  }

  Future<void> _addUnit(BuildContext context, Product product) async {
    final name = TextEditingController();
    final factor = TextEditingController(text: '1');
    var sellable = true;
    var busy = false;
    final key = GlobalKey<FormState>();
    final version = product.units.fold<int>(0, (max, unit) => unit.version > max ? unit.version : max) + 1;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
          title: Text('واحد تازه · ${product.name}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          content: SizedBox(width: 380, child: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'نام واحد'), validator: (v) => v == null || v.trim().isEmpty ? 'نام واحد را وارد کنید.' : null),
            TextFormField(controller: factor, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'ضریب تبدیل به واحد پایه'), validator: (v) { final number = double.tryParse(v ?? ''); return number == null || number <= 0 ? 'ضریب باید عددی بزرگ‌تر از صفر باشد.' : null; }),
            SwitchListTile(title: const Text('قابل فروش', style: TextStyle(fontSize: 11)), value: sellable, onChanged: (value) => setDialog(() => sellable = value)),
            Align(alignment: Alignment.centerRight, child: Text('نسخه ${persianDigits(version)}؛ نسخه‌های قبلی تغییر نمی‌کنند.', style: const TextStyle(fontSize: 9, color: Color(0xFF858FA3)))),
          ]))),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: busy ? null : () async {
            if (!(key.currentState?.validate() ?? false)) return;
            setDialog(() => busy = true);
            try {
              await ref.read(businessRepositoryProvider).saveRecord('product_units', {
                'product_id': product.id, 'unit_name': name.text.trim(), 'conversion_factor': double.parse(factor.text),
                'version_number': version, 'is_sellable': sellable, 'is_base': false,
              });
              if (context.mounted) Navigator.pop(dialogContext);
              _reload();
              _toast('نسخه تازه واحد ثبت شد.');
            } catch (error) {
              if (context.mounted) _toast('$error');
              setDialog(() => busy = false);
            }
          }, child: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ثبت نسخه'))],
        )));
    name.dispose(); factor.dispose();
  }

  String? _numberValidator(String? value) => double.tryParse((value ?? '').replaceAll(',', '')) == null ? 'عدد معتبر وارد کنید.' : null;
  void _toast(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.icon, this.alert = false});
  final String label, value;
  final IconData icon;
  final bool alert;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12), child: Row(children: [CircleAvatar(radius: 17, backgroundColor: alert ? const Color(0xFFFFF3E8) : const Color(0xFFF0EFFF), child: Icon(icon, size: 16, color: alert ? const Color(0xFFCC823D) : pagePurple)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF))), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))]))])));
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.stock, required this.showStock, required this.canSeeSalePrice, required this.isAdmin, required this.onUnits, required this.onInventory});
  final Product product;
  final double stock;
  final bool showStock;
  final bool canSeeSalePrice, isAdmin;
  final VoidCallback onUnits, onInventory;

  @override
  Widget build(BuildContext context) {
    final low = showStock && stock <= product.minStock;
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        CircleAvatar(radius: 18, backgroundColor: const Color(0xFFF0EFFF), child: const Icon(Icons.inventory_2_outlined, size: 17, color: pagePurple)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: pageInk)), Text('${product.code} · ${product.groupName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF)))])),
        StatusBadge(low ? 'pending' : 'active', label: low ? 'موجودی کم' : 'فعال'),
      ]),
      const Divider(height: 22),
      if (showStock)
        Row(children: [Expanded(child: _ProductValue(label: 'موجودی پایه', value: '${persianDigits(stock.toStringAsFixed(stock % 1 == 0 ? 0 : 3))} ${product.baseUnitName}')), Expanded(child: _ProductValue(label: 'حداقل موجودی', value: '${persianDigits(product.minStock)} ${product.baseUnitName}'))])
      else
        const Text('برای استعلام موجودی با واحد فروش تماس بگیرید.', style: TextStyle(fontSize: 9, color: Color(0xFF929CAF))),
      if (canSeeSalePrice) ...[const SizedBox(height: 9), _ProductValue(label: 'قیمت فروش نمایشی', value: product.demoSellPriceToman > 0 ? formatToman(product.demoSellPriceToman) : 'از موتور قیمت‌گذاری سرور')],
      const SizedBox(height: 8),
      Wrap(spacing: 5, runSpacing: 5, children: product.sellableUnits.map((unit) => Chip(label: Text('${unit.name} · ×${persianDigits(unit.factor)} · v${persianDigits(unit.version)}', style: const TextStyle(fontSize: 8)), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero)).toList()),
      Row(children: [
        if (isAdmin) TextButton.icon(onPressed: onUnits, icon: const Icon(Icons.add_rounded, size: 15), label: const Text('واحد نسخه‌دار', style: TextStyle(fontSize: 8))),
        const Spacer(),
        if (showStock) IconButton(tooltip: 'گردش انبار', onPressed: onInventory, icon: const Icon(Icons.swap_horiz_rounded, size: 18)),
      ]),
      if (isAdmin) const Text('هزینه خرید و سود فقط در ماژول امن مالی قابل دسترسی است.', style: TextStyle(fontSize: 8, color: Color(0xFF9A8BC9))),
    ])));
  }
}

extension _ProductFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _ProductValue extends StatelessWidget {
  const _ProductValue({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF))), const SizedBox(height: 3), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pageInk))]);
}
