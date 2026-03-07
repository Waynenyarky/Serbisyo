import 'package:shared_preferences/shared_preferences.dart';

const _modePrefix = 'experience_mode_';

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

String _keyForUser(String userId) => '$_modePrefix$userId';

/// Saves preferred app experience mode for a user.
/// Supported values: 'customer' | 'host'.
Future<void> saveExperienceMode(String userId, String mode) async {
  final normalized = mode.trim().toLowerCase();
  if (normalized != 'customer' && normalized != 'host') return;
  final p = await _prefs();
  await p.setString(_keyForUser(userId), normalized);
}

/// Returns preferred app experience mode for a user, if any.
Future<String?> getExperienceMode(String userId) async {
  final p = await _prefs();
  final value = p.getString(_keyForUser(userId))?.trim().toLowerCase();
  if (value == 'customer' || value == 'host') return value;
  return null;
}

Future<void> clearExperienceMode(String userId) async {
  final p = await _prefs();
  await p.remove(_keyForUser(userId));
}
