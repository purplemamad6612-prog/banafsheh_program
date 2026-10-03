import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/app_config.dart';
import '../models/app_enums.dart';
import '../models/product.dart';
import '../models/user_session.dart';
import '../services/business_repository.dart';
import '../services/offline_store.dart';
import '../services/pocketbase_gateway.dart';

final offlineStoreProvider = Provider<OfflineStore>((ref) => OfflineStore(Hive.box<String>('benafsheh')));

final pocketBaseUrlProvider = StateProvider<String>((ref) {
  final saved = ref.read(offlineStoreProvider).savedPocketBaseUrl;
  return saved.isNotEmpty ? saved : AppConfig.initialPocketBaseUrl;
});

final sessionProvider = StateProvider<UserSession?>((ref) => null);
final demoRoleProvider = StateProvider<AppRole>((ref) => AppRole.admin);
final activePageProvider = StateProvider<AppPage>((ref) => AppPage.dashboard);

final activeRoleProvider = Provider<AppRole>(
  (ref) => ref.watch(sessionProvider)?.role ?? ref.watch(demoRoleProvider),
);

final pocketBaseGatewayProvider = Provider<PocketBaseGateway>((ref) {
  final url = AppConfig.sanitizeUrl(ref.watch(pocketBaseUrlProvider));
  return PocketBaseGateway(url);
});

final businessRepositoryProvider = Provider<BusinessRepository>((ref) => BusinessRepository(
      gateway: ref.watch(pocketBaseGatewayProvider),
      offlineStore: ref.watch(offlineStoreProvider),
      role: ref.watch(activeRoleProvider),
      session: ref.watch(sessionProvider),
    ));

final recordsProvider = FutureProvider.family<List<JsonMap>, String>((ref, collection) async =>
    ref.watch(businessRepositoryProvider).records(collection));

final stockSummaryProvider = FutureProvider<Map<String, double>>((ref) async =>
    ref.watch(businessRepositoryProvider).stockSummary());

final movementQueueProvider = Provider<List<JsonMap>>((ref) => ref.watch(offlineStoreProvider).readMovementQueue());

void refreshCollection(WidgetRef ref, String collection) => ref.invalidate(recordsProvider(collection));
