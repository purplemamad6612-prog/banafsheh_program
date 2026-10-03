import 'dart:convert';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/product.dart';

class OfflineStore {
  OfflineStore(this._box);
  final Box<String> _box;

  static const _queueKey = 'offline_stock_queue_v1';
  static const _deviceKey = 'device_id_v1';
  static const _settingsKey = 'settings_v1';

  String get deviceId {
    final existing = _box.get(_deviceKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final created = 'device-${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 32)}';
    _box.put(_deviceKey, created);
    return created;
  }

  String get savedPocketBaseUrl {
    final raw = _box.get(_settingsKey);
    if (raw == null) return '';
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return asString(map['pocketBaseUrl']);
    } catch (_) {
      return '';
    }
  }

  Future<void> savePocketBaseUrl(String url) async {
    await _box.put(_settingsKey, jsonEncode({'pocketBaseUrl': url}));
  }

  List<JsonMap> readMovementQueue() {
    final raw = _box.get(_queueKey);
    if (raw == null) return <JsonMap>[];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return <JsonMap>[];
    }
  }

  Future<void> addMovement(JsonMap movement) async {
    final queue = readMovementQueue();
    if (queue.any((item) => item['syncId'] == movement['syncId'])) return;
    queue.add(Map<String, dynamic>.from(movement));
    await _box.put(_queueKey, jsonEncode(queue));
  }

  Future<void> removeMovement(String syncId) async {
    final queue = readMovementQueue()..removeWhere((item) => item['syncId'] == syncId);
    await _box.put(_queueKey, jsonEncode(queue));
  }

  Future<void> clearQueue() => _box.delete(_queueKey);
}
