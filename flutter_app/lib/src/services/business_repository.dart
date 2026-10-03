import '../models/app_enums.dart';
import '../models/product.dart';
import '../models/user_session.dart';
import 'demo_data.dart';
import 'offline_store.dart';
import 'pocketbase_gateway.dart';

class BusinessRepository {
  const BusinessRepository({
    required this.gateway,
    required this.offlineStore,
    required this.role,
    this.session,
  });

  final PocketBaseGateway gateway;
  final OfflineStore offlineStore;
  final AppRole role;
  final UserSession? session;

  bool get isRemoteReady => gateway.isConfigured && gateway.isAuthenticated;

  Future<List<JsonMap>> records(String collection) async {
    if (isRemoteReady) return gateway.listRecords(collection);
    return DemoData.records(collection, role);
  }

  Future<Map<String, double>> stockSummary() async {
    if (role == AppRole.customer || role == AppRole.investor) return <String, double>{};
    final stocks = isRemoteReady
        ? await gateway.stockSummary()
        : <String, double>{
            for (final product in DemoData.records('products', role))
              asString(product['id']): asDouble(product['stock_base']),
          };

    // Pending offline receipts, issues and adjustments are reflected immediately.
    // Transfers are omitted here because their global net stock impact is zero.
    for (final movement in offlineStore.readMovementQueue()) {
      final type = asString(movement['type'] ?? movement['movement_type']);
      if (type == 'transfer_in' || type == 'transfer_out') continue;
      final productId = asString(movement['productId'] ?? movement['product_id']);
      if (productId.isEmpty) continue;
      final amount = asDouble(movement['quantityBase'] ?? movement['quantity_in_base_unit']);
      if (type == 'purchase_in') {
        stocks[productId] = (stocks[productId] ?? 0) + amount;
      } else if (type == 'sale_out') {
        stocks[productId] = (stocks[productId] ?? 0) - amount;
      } else if (type == 'adjustment') {
        final decrease = asString(movement['direction']) == 'decrease';
        stocks[productId] = (stocks[productId] ?? 0) + (decrease ? -amount : amount);
      }
    }
    return stocks;
  }

  Future<JsonMap> saveRecord(String collection, JsonMap body) async {
    if (!isRemoteReady) throw StateError('برای ثبت روی سرور، ابتدا به PocketBase وارد شوید.');
    return gateway.createRecord(collection, body);
  }

  Future<JsonMap> updateRecord(String collection, String id, JsonMap body) async {
    if (!isRemoteReady) throw StateError('برای ویرایش روی سرور، ابتدا به PocketBase وارد شوید.');
    return gateway.updateRecord(collection, id, body);
  }

  Future<JsonMap> quoteAndCreateDraft({
    required String customerId,
    required String warehouseId,
    required String invoiceType,
    required String invoiceNumber,
    required String dateJalali,
    required String saleMode,
    String investorId = '',
    required String discountScope,
    required int chequeDurationDays,
    required List<JsonMap> lines,
    String notes = '',
  }) {
    if (!isRemoteReady) throw StateError('محاسبه نهایی قیمت باید به موتور امن قیمت‌گذاری PocketBase متصل باشد.');
    final user = session;
    if (user == null) throw StateError('نشست معتبر کاربر پیدا نشد.');
    return gateway.calculateQuote(
      customerId: customerId,
      createdBy: user.recordId,
      warehouseId: warehouseId,
      invoiceType: invoiceType,
      invoiceNumber: invoiceNumber,
      dateJalali: dateJalali,
      saleMode: saleMode,
      investorId: investorId,
      discountScope: discountScope,
      chequeDurationDays: chequeDurationDays,
      lines: lines,
      notes: notes,
    );
  }

  Future<JsonMap> confirmInvoice(String invoiceId) {
    if (!isRemoteReady) throw StateError('تأیید نهایی فاکتور فقط با اتصال به سرور انجام می‌شود.');
    return gateway.confirmInvoice(invoiceId);
  }

  Future<void> recordOfflineMovement(JsonMap movement) async {
    await offlineStore.addMovement(movement);
    if (!isRemoteReady || session == null) return;
    await syncPendingMovements();
  }

  Future<int> syncPendingMovements() async {
    if (!isRemoteReady || session == null) return 0;
    var synced = 0;
    final pending = offlineStore.readMovementQueue();
    for (final movement in pending) {
      final syncId = asString(movement['syncId']);
      try {
        var queue = await gateway.findOfflineMovement(syncId);
        queue ??= await gateway.submitOfflineMovement(
          userId: session!.recordId,
          deviceId: offlineStore.deviceId,
          movement: movement,
        );
        if (asString(queue['synced_at']).isNotEmpty) {
          await offlineStore.removeMovement(syncId);
          synced++;
          continue;
        }
        final queueId = asString(queue['id']);
        if (queueId.isNotEmpty) {
          final retry = await gateway.retryOfflineMovement(queueId);
          if (asString(retry['synced_at']).isNotEmpty) {
            await offlineStore.removeMovement(syncId);
            synced++;
          }
        }
      } catch (_) {
        // Network errors and conflicts never discard local warehouse work.
      }
    }
    return synced;
  }
}
