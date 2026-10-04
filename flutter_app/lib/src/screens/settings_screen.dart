import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_config.dart';
import '../core/formatters.dart';
import '../models/app_enums.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../services/pocketbase_gateway.dart';
import '../widgets/page_components.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _url = TextEditingController();
  bool _initialized = false;
  bool _busy = false;
  String? _connectionMessage;
  bool _connected = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configuredUrl = ref.watch(pocketBaseUrlProvider);
    if (!_initialized) {
      _url.text = configuredUrl;
      _initialized = true;
    }
    final session = ref.watch(sessionProvider);
    final role = ref.watch(activeRoleProvider);
    final queue = ref.watch(movementQueueProvider);

    return ListView(padding: const EdgeInsets.fromLTRB(22, 20, 22, 36), children: [
      const PageHeading(title: 'تنظیمات و اتصال', subtitle: 'تنظیم نشانی PocketBase، وضعیت دستگاه و حریم دسترسی نقش‌ها'),
      if (kIsWeb)
        const InfoPanel(icon: Icons.language_rounded, text: 'در نسخه وب، نشانی localhost یا 127.0.0.1 قابل دسترسی نیست. آدرس عمومی سرور یا نشانی پروکسی هم‌مبدأ را وارد کنید.', color: Color(0xFFFFF6E9)),
      const SizedBox(height: 12),
      FormCard(
        title: 'اتصال به PocketBase',
        icon: Icons.cloud_outlined,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _url, keyboardType: TextInputType.url, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'نشانی سرور', hintText: 'https://pb.example.com', prefixIcon: Icon(Icons.link_rounded))),
          const SizedBox(height: 6),
          Text('مقدار فعلی: ${configuredUrl.isEmpty ? 'تنظیم نشده' : configuredUrl}', textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 8, color: Color(0xFF929CAF))),
          if (kIsWeb)
            const Padding(padding: EdgeInsets.only(top: 7), child: Text('مرورگر هرگز به 127.0.0.1 یا localhost پیش‌فرض وصل نمی‌شود.', style: TextStyle(fontSize: 9, color: Color(0xFFB07135)))),
          if (!kIsWeb)
            const Padding(padding: EdgeInsets.only(top: 7), child: Text('پیش‌فرض بومی: http://127.0.0.1:8090 (قابل تنظیم برای سرور شبکه)', textDirection: TextDirection.ltr, style: TextStyle(fontSize: 8, color: Color(0xFF929CAF)))),
          const SizedBox(height: 11),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(onPressed: _busy ? null : _saveUrl, icon: const Icon(Icons.save_outlined, size: 16), label: Text(_busy ? 'در حال ذخیره…' : 'ذخیره نشانی')),
            OutlinedButton.icon(onPressed: _busy ? null : _testConnection, icon: const Icon(Icons.network_check_rounded, size: 16), label: const Text('آزمون اتصال')),
          ]),
          if (_connectionMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Row(children: [
                Icon(_connected ? Icons.check_circle_outline : Icons.info_outline, size: 16, color: _connected ? const Color(0xFF25866E) : const Color(0xFFB07135)),
                const SizedBox(width: 6),
                Expanded(child: Text(_connectionMessage!, style: TextStyle(fontSize: 9, color: _connected ? const Color(0xFF25866E) : const Color(0xFFB07135)))),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final offline = FormCard(title: 'دستگاه و عملیات آفلاین', icon: Icons.wifi_off_rounded, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SettingRow(label: 'شناسه دستگاه', value: ref.read(offlineStoreProvider).deviceId),
          _SettingRow(label: 'گردش ذخیره‌شده محلی', value: persianDigits(queue.length)),
          const SizedBox(height: 8),
          const Text('ثبت گردش انبار ابتدا به‌صورت پایدار روی دستگاه نگهداری می‌شود؛ خطای شبکه یا تعارض باعث حذف آن نمی‌شود.', style: TextStyle(fontSize: 9, color: Color(0xFF758097))),
          const SizedBox(height: 9),
          OutlinedButton.icon(onPressed: _busy || queue.isEmpty ? null : _syncQueue, icon: const Icon(Icons.sync_rounded, size: 16), label: const Text('تلاش دوباره برای همگام‌سازی')),
        ]));
        final account = FormCard(title: 'نشست و نقش کاربری', icon: Icons.admin_panel_settings_outlined, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SettingRow(label: 'وضعیت ورود', value: session == null ? 'بدون نشست سرور' : 'متصل و احراز هویت‌شده'),
          _SettingRow(label: 'نقش فعال', value: role.label),
          if (session != null) _SettingRow(label: 'کاربر', value: session.name),
          const SizedBox(height: 8),
          const Text('نقش‌های نمایشی برای پیش‌نمایش رابط کاربری‌اند و مجوز امنیتی ایجاد نمی‌کنند. مجوز قطعی باید در قوانین PocketBase اعمال شود.', style: TextStyle(fontSize: 9, color: Color(0xFF758097))),
          if (session == null) const Padding(padding: EdgeInsets.only(top: 7), child: Text('برای ورود، دکمهٔ ورود در نوار بالا را انتخاب کنید.', style: TextStyle(fontSize: 9, color: Color(0xFF776EE8)))),
          if (role == AppRole.admin) const Padding(padding: EdgeInsets.only(top: 8), child: InfoPanel(icon: Icons.privacy_tip_outlined, text: 'هزینه خرید و رکوردهای خصوصی سود فقط برای نقش مدیر تعریف شده‌اند.')),
        ]));
        if (constraints.maxWidth < 800) return Column(children: [offline, const SizedBox(height: 10), account]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: offline), const SizedBox(width: 10), Expanded(child: account)]);
      }),
      const SizedBox(height: 12),
      FormCard(title: 'ساختار داده و سازگاری', icon: Icons.schema_outlined, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('مجموعه‌های کسب‌وکار پشتیبانی‌شده', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: const [
            'warehouses', 'product_groups', 'products', 'product_units', 'customer_price_groups', 'customers', 'suppliers', 'pricing_profiles', 'volume_discount_tiers', 'cheque_surcharge_rules', 'stock_movements', 'investors', 'invoices', 'invoice_items', 'payments', 'cheques', 'investor_deals', 'investor_settlements', 'settings',
          ].map((name) => Chip(label: Text(name, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 7)), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero)).toList(),
        ),
        const SizedBox(height: 7),
        const Text('سامانه احراز هویت به users نیاز دارد. صف آفلاین sync_queue و مجموعه‌های محرمانه بهای تمام‌شده باید در PocketBase به‌صورت کنترل‌شده نصب شوند؛ آن‌ها جزو ۱۹ مجموعه کاری نیستند.', style: TextStyle(fontSize: 9, color: Color(0xFF758097))),
      ])),
    ]);
  }

  Future<void> _saveUrl() async {
    setState(() {
      _busy = true;
      _connectionMessage = null;
    });
    try {
      final safe = AppConfig.sanitizeUrl(_url.text);
      await ref.read(offlineStoreProvider).savePocketBaseUrl(safe);
      ref.read(pocketBaseUrlProvider.notifier).state = safe;
      ref.read(pocketBaseGatewayProvider).signOut();
      ref.read(sessionProvider.notifier).state = null;
      for (final collection in _collections) {
        ref.invalidate(recordsProvider(collection));
      }
      ref.invalidate(stockSummaryProvider);
      setState(() {
        _connectionMessage = 'نشانی به‌صورت محلی ذخیره شد.';
        _connected = true;
      });
    } catch (error) {
      setState(() {
        _connectionMessage = error.toString();
        _connected = false;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _busy = true;
      _connectionMessage = null;
    });
    try {
      final url = AppConfig.sanitizeUrl(_url.text);
      if (url.isEmpty) throw StateError('ابتدا نشانی PocketBase را وارد کنید.');
      await PocketBaseGateway(url).checkHealth();
      setState(() {
        _connectionMessage = 'PocketBase در دسترس است.';
        _connected = true;
      });
    } catch (error) {
      setState(() {
        _connectionMessage = 'اتصال برقرار نشد: $error';
        _connected = false;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncQueue() async {
    setState(() => _busy = true);
    final count = await ref.read(businessRepositoryProvider).syncPendingMovements();
    ref.invalidate(movementQueueProvider);
    ref.invalidate(stockSummaryProvider);
    ref.invalidate(recordsProvider('stock_movements'));
    if (mounted) {
      setState(() => _busy = false);
      _toast(count > 0 ? '${persianDigits(count)} گردش همگام شد.' : 'اتصالی برقرار نشد؛ گردش‌های محلی حفظ شده‌اند.');
    }
  }

  static const _collections = [
    'warehouses', 'product_groups', 'products', 'product_units', 'customer_price_groups', 'customers', 'suppliers', 'pricing_profiles', 'volume_discount_tiers', 'cheque_surcharge_rules', 'stock_movements', 'investors', 'invoices', 'invoice_items', 'payments', 'cheques', 'investor_deals', 'investor_settlements', 'settings', 'users', 'sync_queue', 'product_costs', 'invoice_item_costs', 'investor_deal_costs',
  ];

  void _toast(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF929CAF)))),
          Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
        ]),
      );
}
