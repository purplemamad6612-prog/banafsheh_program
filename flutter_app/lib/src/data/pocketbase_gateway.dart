import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

/// Supply the server URL at build time, e.g. --dart-define=POCKETBASE_URL=https://pb.example.ir
/// No loopback URL is baked into browser-facing code.
final pocketBaseUrlProvider = StateProvider<String>(
  (ref) => const String.fromEnvironment('POCKETBASE_URL'),
);

final pocketBaseProvider = Provider<PocketBase?>((ref) {
  final url = ref.watch(pocketBaseUrlProvider).trim();
  if (url.isEmpty) return null;
  return PocketBase(url);
});

final pocketBaseGatewayProvider = Provider<PocketBaseGateway>(
  (ref) => PocketBaseGateway(ref.watch(pocketBaseProvider)),
);

class PocketBaseGateway {
  const PocketBaseGateway(this._client);
  final PocketBase? _client;

  bool get isConfigured => _client != null;

  Future<RecordAuth> signIn(String identity, String password) async {
    final client = _requireClient();
    final response = await client.collection('users').authWithPassword(identity, password);
    return response;
  }

  /// Prices are calculated on the server from private product cost records.
  /// The client submits product/unit/quantity inputs only, never a sell price.
  Future<Map<String, dynamic>> calculateQuote({
    required String customerId,
    required String saleMode,
    required String discountScope,
    required int chequeDurationDays,
    required List<Map<String, dynamic>> lines,
  }) async {
    final result = await _requireClient().send(
      '/api/benafsheh/pricing/calculate',
      method: 'POST',
      body: {
        'customer_id': customerId,
        'sale_mode': saleMode,
        'discount_scope': discountScope,
        'cheque_duration_days': chequeDurationDays,
        'lines': lines,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> confirmInvoice(String invoiceId) async {
    final result = await _requireClient().send(
      '/api/benafsheh/invoices/$invoiceId/confirm',
      method: 'POST',
      body: const <String, dynamic>{},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> submitOfflineMovement(Map<String, dynamic> queueRecord) async {
    await _requireClient().collection('sync_queue').create(body: queueRecord);
  }

  PocketBase _requireClient() => _client ??
      (throw StateError('PocketBase URL is not configured. Set POCKETBASE_URL or use Settings.'));
}
