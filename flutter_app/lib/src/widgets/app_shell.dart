import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../core/formatters.dart';
import '../models/app_enums.dart';
import '../providers/app_providers.dart';
import '../screens/cheques_screen.dart';
import '../screens/customer_ledger_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/invoice_screen.dart';
import '../screens/investor_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/products_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/suppliers_screen.dart';

const _deepNavy = Color(0xFF111D3A);
const _purple = Color(0xFF776EE8);

const Map<AppRole, List<AppPage>> _rolePages = {
  AppRole.admin: AppPage.values,
  AppRole.accountant: [AppPage.dashboard, AppPage.invoices, AppPage.customers, AppPage.suppliers, AppPage.cheques, AppPage.investors, AppPage.reports, AppPage.settings],
  AppRole.warehouse: [AppPage.dashboard, AppPage.products, AppPage.inventory, AppPage.settings],
  AppRole.sales: [AppPage.dashboard, AppPage.invoices, AppPage.products, AppPage.customers, AppPage.settings],
  AppRole.investor: [AppPage.dashboard, AppPage.investors, AppPage.cheques, AppPage.settings],
  AppRole.customer: [AppPage.dashboard, AppPage.products, AppPage.invoices, AppPage.customers, AppPage.settings],
};

String pageTitle(AppPage page) => switch (page) {
      AppPage.dashboard => 'نمای کلی',
      AppPage.invoices => 'فاکتورها و پیش‌فاکتورها',
      AppPage.products => 'کالاها و قیمت‌گذاری',
      AppPage.customers => 'مشتریان و حساب‌ها',
      AppPage.suppliers => 'تأمین‌کنندگان',
      AppPage.inventory => 'انبار و گردش کالا',
      AppPage.cheques => 'مدیریت چک‌ها',
      AppPage.investors => 'سرمایه‌گذاران',
      AppPage.reports => 'گزارش‌ها',
      AppPage.settings => 'تنظیمات',
    };

IconData pageIcon(AppPage page) => switch (page) {
      AppPage.dashboard => Icons.dashboard_rounded,
      AppPage.invoices => Icons.receipt_long_rounded,
      AppPage.products => Icons.inventory_2_rounded,
      AppPage.customers => Icons.groups_rounded,
      AppPage.suppliers => Icons.local_shipping_rounded,
      AppPage.inventory => Icons.home_work_rounded,
      AppPage.cheques => Icons.account_balance_rounded,
      AppPage.investors => Icons.trending_up_rounded,
      AppPage.reports => Icons.bar_chart_rounded,
      AppPage.settings => Icons.settings_rounded,
    };

class BenafshehHomeShell extends ConsumerWidget {
  const BenafshehHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(activePageProvider);
    final role = ref.watch(activeRoleProvider);
    final session = ref.watch(sessionProvider);
    final allowed = _rolePages[role] ?? const [AppPage.dashboard];
    if (!allowed.contains(page)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(activePageProvider.notifier).state = AppPage.dashboard);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 820;
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          titleSpacing: compact ? 8 : 26,
          leading: compact
              ? Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => Scaffold.of(context).openDrawer()))
              : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pageTitle(page), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              if (!compact) const Text('سامانه یکپارچه بنفشه', style: TextStyle(fontSize: 9, color: Color(0xFF929CAF))),
            ],
          ),
          actions: [
            if (!compact) const _JalaliToday(),
            IconButton(
              tooltip: session == null ? 'ورود به PocketBase' : 'خروج از حساب',
              onPressed: () => session == null ? _showLoginDialog(context) : _logout(ref),
              icon: Icon(session == null ? Icons.login_rounded : Icons.logout_rounded),
            ),
            if (session == null)
              PopupMenuButton<AppRole>(
                tooltip: 'نقش نمایشی',
                onSelected: (value) {
                  ref.read(demoRoleProvider.notifier).state = value;
                  ref.read(activePageProvider.notifier).state = AppPage.dashboard;
                },
                itemBuilder: (context) => AppRole.values.map((value) => PopupMenuItem(value: value, child: Text(value.label))).toList(),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6, end: 16),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(radius: 15, backgroundColor: const Color(0xFFF0EFFF), child: Text(role.label.substring(0, 1), style: const TextStyle(color: _purple, fontWeight: FontWeight.bold))),
                    if (!compact) ...[const SizedBox(width: 7), Text(role.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)), const Icon(Icons.keyboard_arrow_down_rounded, size: 17)],
                  ]),
                ),
              )
            else
              Padding(padding: const EdgeInsetsDirectional.only(start: 8, end: 18), child: Center(child: Text(session.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)))),
          ],
        ),
        drawer: compact
            ? Drawer(
                width: 275,
                child: _NavigationPanel(
                  role: role,
                  current: page,
                  pages: allowed,
                  onSelect: (value) {
                    ref.read(activePageProvider.notifier).state = value;
                    Navigator.pop(context);
                  },
                ),
              )
            : null,
        body: Row(children: [
          if (!compact)
            _NavigationPanel(
              role: role,
              current: page,
              pages: allowed,
              onSelect: (value) => ref.read(activePageProvider.notifier).state = value,
            ),
          Expanded(child: _pageBody(page)),
        ]),
      );
    });
  }

  Widget _pageBody(AppPage page) => switch (page) {
        AppPage.dashboard => const DashboardScreen(),
        AppPage.invoices => const InvoiceScreen(),
        AppPage.products => const ProductsScreen(),
        AppPage.customers => const CustomerLedgerScreen(),
        AppPage.suppliers => const SuppliersScreen(),
        AppPage.inventory => const InventoryScreen(),
        AppPage.cheques => const ChequesScreen(),
        AppPage.investors => const InvestorScreen(),
        AppPage.reports => const ReportsScreen(),
        AppPage.settings => const SettingsScreen(),
      };
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({required this.role, required this.current, required this.pages, required this.onSelect});
  final AppRole role;
  final AppPage current;
  final List<AppPage> pages;
  final ValueChanged<AppPage> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        width: 244,
        color: _deepNavy,
        padding: const EdgeInsets.fromLTRB(13, 19, 13, 15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.storefront_rounded, color: Colors.white)),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('بنفشه', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('فروش و انبار UPVC', style: TextStyle(color: Color(0xFFA7B1C8), fontSize: 9)),
            ]),
          ]),
          const SizedBox(height: 26),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 11), child: Text('منوی اصلی', style: TextStyle(color: Color(0xFF7D8AA7), fontSize: 9))),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              for (final page in pages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Material(
                    color: page == current ? const Color(0xFF2A3455) : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      onTap: () => onSelect(page),
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        height: 43,
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        decoration: page == current ? const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFF948DFF), width: 3))) : null,
                        child: Row(children: [
                          Icon(pageIcon(page), size: 18, color: page == current ? const Color(0xFFA7A0FF) : const Color(0xFFB4BED2)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(pageTitle(page), style: TextStyle(color: page == current ? Colors.white : const Color(0xFFB4BED2), fontSize: 10, fontWeight: page == current ? FontWeight.w700 : FontWeight.w500))),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.055), border: Border.all(color: Colors.white.withOpacity(.08)), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.cloud_done_outlined, color: Color(0xFF5AD2AE), size: 16),
              const SizedBox(width: 7),
              Expanded(child: Text('${role.label} · داده محلی/سرور', style: const TextStyle(color: Color(0xFFD8DFEF), fontSize: 9))),
            ]),
          ),
        ]),
      );
}

class _JalaliToday extends StatelessWidget {
  const _JalaliToday();
  @override
  Widget build(BuildContext context) {
    final now = Jalali.now();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE9EDF4)), borderRadius: BorderRadius.circular(9)),
      child: Row(children: [
        const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF929CAF)),
        const SizedBox(width: 6),
        Text(formatJalaliLong(now), style: const TextStyle(fontSize: 9, color: Color(0xFF66718A))),
      ]),
    );
  }
}

Future<void> _showLoginDialog(BuildContext context) async {
  await showDialog<void>(context: context, builder: (_) => const _LoginDialog());
}

void _logout(WidgetRef ref) {
  ref.read(pocketBaseGatewayProvider).signOut();
  ref.read(sessionProvider.notifier).state = null;
  ref.read(activePageProvider.notifier).state = AppPage.dashboard;
}

class _LoginDialog extends ConsumerStatefulWidget {
  const _LoginDialog();
  @override
  ConsumerState<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends ConsumerState<_LoginDialog> {
  final _identity = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _busy = true; _error = null; });
    try {
      final session = await ref.read(pocketBaseGatewayProvider).signIn(_identity.text.trim(), _password.text);
      ref.read(sessionProvider.notifier).state = session;
      ref.read(demoRoleProvider.notifier).state = session.role;
      ref.read(activePageProvider.notifier).state = AppPage.dashboard;
      if (mounted) Navigator.pop(context);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('ورود امن به PocketBase'),
        content: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _identity, decoration: const InputDecoration(labelText: 'نام کاربری یا شماره همراه')),
            const SizedBox(height: 10),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'گذرواژه')),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11))),
          ]),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton.icon(onPressed: _busy ? null : _login, icon: const Icon(Icons.login_rounded), label: Text(_busy ? 'در حال ورود…' : 'ورود')),
        ],
      );
}
