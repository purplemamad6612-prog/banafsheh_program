import 'package:pocketbase/pocketbase.dart';

import '../models/product.dart';
import '../models/user_session.dart';

class PocketBaseGateway {
  PocketBaseGateway(String baseUrl)
      : _baseUrl = baseUrl.trim(),
        _client = baseUrl.trim().isEmpty ? null : PocketBase(baseUrl.trim());

  final String _baseUrl;
  final PocketBase? _client;

  bool get isConfigured => _client != null;
  bool get isAuthenticated => _client?.authStore.isValid ?? false;
  String get baseUrl => _baseUrl;

  Future<UserSession> signIn(String identity, String password) async {
    final client = _requireClient();
    final auth = await client.collection('users').authWithPassword(identity, password);
    return UserSession.fromRecord(Map<String, dynamic>.from(auth.record.data), auth.token);
  }

  void signOut() => _client?.authStore.clear();

  Future<void> checkHealth() async {
    await _requireClient().send('/api/health', method: 'GET');
  }

  Future<List<JsonMap>> listRecords(String collection, {int perPage = 200}) async {
    final records = await _requireClient().collection(collection).getFullList(batch: perPage);
    return records.map((record) => Map<String, dynamic>.from(record.data)).toList();
  }

  Future<Map<String, double>> stockSummary() async {
    final response = Map<String, dynamic>.from(await _requireClient().send('/api/benafsheh/stock-summary', method: 'GET') as Map);
    final rows = response['stocks'];
    if (rows is! List) return <String, double>{};
    return {
      for (final row in rows.whereType<Map>())
        asString(row['product_id']): asDouble(row['stock_base']),
    };
  }

  Future<JsonMap> createRecord(String collection, JsonMap body) async {
    final record = await _requireClient().collection(collection).create(body: body);
    return Map<String, dynamic>.from(record.data);
  }

  Future<JsonMap> updateRecord(String collection, String id, JsonMap body) async {
    final record = await _requireClient().collection(collection).update(id, body: body);
    return Map<String, dynamic>.from(record.data);
  }

  Future<void> deleteRecord(String collection, String id) async {
    await _requireClient().collection(collection).delete(id);
  }

  Future<JsonMap> calculateQuote({
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
  }) async => Map<String, dynamic>.from(await _requireClient().send(
        '/api/benafsheh/invoices/quote',
        method: 'POST',
        body: {
          'customer_id': customerId,
          'warehouse_id': warehouseId,
          'invoice_type': invoiceType,
          'invoice_number': invoiceNumber,
          'invoice_date_jalali': dateJalali,
          'sale_mode': saleMode,
          if (investorId.isNotEmpty) 'investor_id': investorId,
          'discount_scope': discountScope,
          'cheque_duration_days': chequeDurationDays,
          'lines': lines,
          'notes': notes,
        },
      ) as Map);

  Future<JsonMap> reviseDraftInvoice(String invoiceId, JsonMap body) async =>
      Map<String, dynamic>.from(await _requireClient().send(
        '/api/benafsheh/invoices/$invoiceId/revise',
        method: 'POST',
        body: body,
      ) as Map);

  Future<JsonMap> confirmInvoice(String invoiceId) async =>
      Map<String, dynamic>.from(await _requireClient().send(
        '/api/benafsheh/invoices/$invoiceId/confirm',
        method: 'POST',
        body: const <String, dynamic>{},
      ) as Map);

  Future<JsonMap> createCheque(JsonMap body) => createRecord('cheques', body);

  Future<JsonMap> createSettlement(JsonMap body) => createRecord('investor_settlements', body);

  Future<JsonMap?> findOfflineMovement(String syncId) async {
    final page = await _requireClient().collection('sync_queue').getList(
          page: 1,
          perPage: 1,
          filter: "sync_id = '$syncId'",
        );
    if (page.items.isEmpty) return null;
    return Map<String, dynamic>.from(page.items.first.data);
  }

  Future<JsonMap> submitOfflineMovement({
    required String userId,
    required String deviceId,
    required JsonMap movement,
  }) async {
    return createRecord('sync_queue', {
      'device_id': deviceId,
      'user_id': userId,
      'entity_type': 'stock_movement',
      'entity_id': asString(movement['id']),
      'action': 'create',
      'payload': movement,
      'sync_id': asString(movement['syncId']),
      'synced_at': '',
    });
  }

  Future<JsonMap> retryOfflineMovement(String queueRecordId) async =>
      Map<String, dynamic>.from(await _requireClient().send(
        '/api/benafsheh/sync-queue/$queueRecordId/retry',
        method: 'POST',
        body: const <String, dynamic>{},
      ) as Map);

  PocketBase _requireClient() => _client ??
      (throw StateError('نشانی PocketBase را در تنظیمات وارد کنید.'));
}
