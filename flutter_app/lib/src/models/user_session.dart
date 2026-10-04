import 'app_enums.dart';
import 'product.dart';

class UserSession {
  const UserSession({
    required this.recordId,
    required this.name,
    required this.role,
    required this.token,
    this.customerId = '',
    this.investorId = '',
  });

  final String recordId;
  final String name;
  final AppRole role;
  final String token;
  final String customerId;
  final String investorId;

  factory UserSession.fromRecord(JsonMap data, String token) => UserSession(
        recordId: asString(data['id']),
        name: asString(data['name'], fallback: asString(data['username'], fallback: 'کاربر')),
        role: AppRoleLabel.parse(data['role']),
        token: token,
        customerId: asString(data['customer_id']),
        investorId: asString(data['investor_id']),
      );
}
