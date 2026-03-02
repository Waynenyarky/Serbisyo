import 'package:shared_preferences/shared_preferences.dart';

const _keyToken = 'auth_token';
const _keyUserId = 'auth_user_id';
const _keyUserEmail = 'auth_user_email';
const _keyUserName = 'auth_user_name';
const _keyUserRole = 'auth_user_role';
const _keyIsCustomer = 'auth_user_is_customer';
const _keyIsProvider = 'auth_user_is_provider';
const _keyIsAdmin = 'auth_user_is_admin';
const _keyAdminRole = 'auth_user_admin_role';

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

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
  final p = await _prefs();
  await p.setString(_keyToken, token);
  await p.setString(_keyUserId, userId);
  await p.setString(_keyUserEmail, email);
  await p.setString(_keyUserName, fullName);
  if (role != null) {
    await p.setString(_keyUserRole, role);
  } else {
    await p.remove(_keyUserRole);
  }
  if (isCustomer != null) {
    await p.setBool(_keyIsCustomer, isCustomer);
  } else {
    await p.remove(_keyIsCustomer);
  }
  if (isProvider != null) {
    await p.setBool(_keyIsProvider, isProvider);
  } else {
    await p.remove(_keyIsProvider);
  }
  if (isAdmin != null) {
    await p.setBool(_keyIsAdmin, isAdmin);
  } else {
    await p.remove(_keyIsAdmin);
  }
  if (adminRole != null && adminRole.isNotEmpty) {
    await p.setString(_keyAdminRole, adminRole);
  } else {
    await p.remove(_keyAdminRole);
  }
}

Future<String?> getToken() async {
  final p = await _prefs();
  return p.getString(_keyToken);
}

Future<String?> getUserId() async {
  final p = await _prefs();
  return p.getString(_keyUserId);
}

Future<String?> getUserEmail() async {
  final p = await _prefs();
  return p.getString(_keyUserEmail);
}

Future<String?> getUserName() async {
  final p = await _prefs();
  return p.getString(_keyUserName);
}

Future<String?> getUserRole() async {
  final p = await _prefs();
  return p.getString(_keyUserRole);
}

Future<bool?> getUserIsCustomer() async {
  final p = await _prefs();
  return p.containsKey(_keyIsCustomer) ? p.getBool(_keyIsCustomer) : null;
}

Future<bool?> getUserIsProvider() async {
  final p = await _prefs();
  return p.containsKey(_keyIsProvider) ? p.getBool(_keyIsProvider) : null;
}

Future<bool?> getUserIsAdmin() async {
  final p = await _prefs();
  return p.containsKey(_keyIsAdmin) ? p.getBool(_keyIsAdmin) : null;
}

Future<String?> getUserAdminRole() async {
  final p = await _prefs();
  return p.getString(_keyAdminRole);
}

Future<void> clearAuth() async {
  final p = await _prefs();
  await p.remove(_keyToken);
  await p.remove(_keyUserId);
  await p.remove(_keyUserEmail);
  await p.remove(_keyUserName);
  await p.remove(_keyUserRole);
  await p.remove(_keyIsCustomer);
  await p.remove(_keyIsProvider);
  await p.remove(_keyIsAdmin);
  await p.remove(_keyAdminRole);
}
