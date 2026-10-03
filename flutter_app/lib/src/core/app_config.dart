import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String _buildUrl = String.fromEnvironment('POCKETBASE_URL');

  /// Native builds can use the local Windows PocketBase service by default.
  /// Web builds intentionally start unconfigured: browser code must not call
  /// localhost/127.0.0.1 because the browser is not the sandbox/server host.
  static String get initialPocketBaseUrl {
    if (_buildUrl.trim().isNotEmpty) return sanitizeUrl(_buildUrl);
    return kIsWeb ? '' : 'http://127.0.0.1:8090';
  }

  static String sanitizeUrl(String input) {
    final value = input.trim().replaceFirst(RegExp(r'/+$'), '');
    if (value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('نشانی PocketBase معتبر نیست.');
    }
    if (kIsWeb && (uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1')) {
      throw const FormatException('در پیش‌نمایش وب از نشانی localhost استفاده نکنید؛ نشانی قابل دسترس سرور را وارد کنید.');
    }
    return value;
  }
}
