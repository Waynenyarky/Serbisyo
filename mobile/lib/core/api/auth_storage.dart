import 'package:shared_preferences/shared_preferences.dart';

const _keyToken = 'auth_token';
const _keyUserId = 'auth_user_id';
const _keyUserEmail = 'auth_user_email';
const _keyUserName = 'auth_user_name';
const _keyUserRole = 'auth_user_role';

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

Future<void> saveAuth({
  required String token,
  required String userId,
  required String email,
  required String fullName,
  String? role,
}) async {
  final p = await _prefs();
  await p.setString(_keyToken, token);
  await p.setString(_keyUserId, userId);
  await p.setString(_keyUserEmail, email);
  await p.setString(_keyUserName, fullName);
  if (role != null) await p.setString(_keyUserRole, role);
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

Future<void> clearAuth() async {
  final p = await _prefs();
  await p.remove(_keyToken);
  await p.remove(_keyUserId);
  await p.remove(_keyUserEmail);
  await p.remove(_keyUserName);
  await p.remove(_keyUserRole);
}
