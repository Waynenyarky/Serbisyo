import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyToken = 'auth_token';
const _keyUserId = 'auth_user_id';
const _keyUserEmail = 'auth_user_email';
const _keyUserName = 'auth_user_name';
const _keyUserRole = 'auth_user_role';
const _keyIsCustomer = 'auth_user_is_customer';
const _keyIsProvider = 'auth_user_is_provider';
const _keyIsAdmin = 'auth_user_is_admin';
const _keyAdminRole = 'auth_user_admin_role';

const FlutterSecureStorage _storage = FlutterSecureStorage();

String _boolToString(bool value) => value ? 'true' : 'false';

bool? _stringToBool(String? value) {
  if (value == null) return null;
  final normalized = value.trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

Future<void> saveAuth({
  required String token,
  required String userId,
  required String email,
  required String fullName,
  String? role,
  bool? isCustomer,
  bool? isProvider,
  bool? isAdmin,
  String? adminRole,
}) async {
  await _storage.write(key: _keyToken, value: token);
  await _storage.write(key: _keyUserId, value: userId);
  await _storage.write(key: _keyUserEmail, value: email);
  await _storage.write(key: _keyUserName, value: fullName);
  if (role != null) {
    await _storage.write(key: _keyUserRole, value: role);
  } else {
    await _storage.delete(key: _keyUserRole);
  }
  if (isCustomer != null) {
    await _storage.write(key: _keyIsCustomer, value: _boolToString(isCustomer));
  } else {
    await _storage.delete(key: _keyIsCustomer);
  }
  if (isProvider != null) {
    await _storage.write(key: _keyIsProvider, value: _boolToString(isProvider));
  } else {
    await _storage.delete(key: _keyIsProvider);
  }
  if (isAdmin != null) {
    await _storage.write(key: _keyIsAdmin, value: _boolToString(isAdmin));
  } else {
    await _storage.delete(key: _keyIsAdmin);
  }
  if (adminRole != null && adminRole.isNotEmpty) {
    await _storage.write(key: _keyAdminRole, value: adminRole);
  } else {
    await _storage.delete(key: _keyAdminRole);
  }
}

Future<String?> getToken() async {
  return _storage.read(key: _keyToken);
}

Future<String?> getUserId() async {
  return _storage.read(key: _keyUserId);
}

Future<String?> getUserEmail() async {
  return _storage.read(key: _keyUserEmail);
}

Future<String?> getUserName() async {
  return _storage.read(key: _keyUserName);
}

Future<String?> getUserRole() async {
  return _storage.read(key: _keyUserRole);
}

Future<bool?> getUserIsCustomer() async {
  return _stringToBool(await _storage.read(key: _keyIsCustomer));
}

Future<bool?> getUserIsProvider() async {
  return _stringToBool(await _storage.read(key: _keyIsProvider));
}

Future<bool?> getUserIsAdmin() async {
  return _stringToBool(await _storage.read(key: _keyIsAdmin));
}

Future<String?> getUserAdminRole() async {
  return _storage.read(key: _keyAdminRole);
}

Future<void> clearAuth() async {
  await _storage.delete(key: _keyToken);
  await _storage.delete(key: _keyUserId);
  await _storage.delete(key: _keyUserEmail);
  await _storage.delete(key: _keyUserName);
  await _storage.delete(key: _keyUserRole);
  await _storage.delete(key: _keyIsCustomer);
  await _storage.delete(key: _keyIsProvider);
  await _storage.delete(key: _keyIsAdmin);
  await _storage.delete(key: _keyAdminRole);
}
