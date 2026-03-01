import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _keyRecentlyViewed = 'recently_viewed_service_ids';
const _maxRecentlyViewed = 20;

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

/// Returns the list of recently viewed service IDs (most recent first).
Future<List<String>> getRecentlyViewedIds() async {
  final p = await _prefs();
  final json = p.getString(_keyRecentlyViewed);
  if (json == null || json.isEmpty) return [];
  try {
    final list = jsonDecode(json) as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
  } catch (_) {
    return [];
  }
}

/// Records a service view. Puts [serviceId] at the front and keeps order, max [_maxRecentlyViewed].
Future<void> addRecentlyViewed(String serviceId) async {
  if (serviceId.isEmpty) return;
  final list = await getRecentlyViewedIds();
  final updated = [serviceId, ...list.where((id) => id != serviceId)].take(_maxRecentlyViewed).toList();
  final p = await _prefs();
  await p.setString(_keyRecentlyViewed, jsonEncode(updated));
}
