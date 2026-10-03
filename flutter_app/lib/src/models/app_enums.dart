enum AppRole { admin, accountant, warehouse, sales, investor, customer }

enum AppPage { dashboard, invoices, products, customers, suppliers, inventory, cheques, investors, reports, settings }

enum SaleMode { cash, chequeDirect, investor }

extension AppRoleLabel on AppRole {
  String get label => switch (this) {
        AppRole.admin => 'مدیر',
        AppRole.accountant => 'حسابدار',
        AppRole.warehouse => 'انباردار',
        AppRole.sales => 'فروشنده',
        AppRole.investor => 'سرمایه‌گذار',
        AppRole.customer => 'مشتری',
      };

  String get wireValue => name;

  static AppRole parse(Object? value) => AppRole.values.firstWhere(
        (role) => role.name == value,
        orElse: () => AppRole.sales,
      );
}

extension SaleModeData on SaleMode {
  String get wireValue => switch (this) {
        SaleMode.cash => 'cash',
        SaleMode.chequeDirect => 'cheque_direct',
        SaleMode.investor => 'investor',
      };

  String get label => switch (this) {
        SaleMode.cash => 'نقدی',
        SaleMode.chequeDirect => 'چک مستقیم',
        SaleMode.investor => 'سرمایه‌گذار',
      };
}
