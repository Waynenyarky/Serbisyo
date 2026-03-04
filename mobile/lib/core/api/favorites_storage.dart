import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _keyFavorites = 'favorites_service_ids';
const _keyFavoriteNames = 'favorites_names';
const _keyFavoriteListName = 'favorite_list_name';
const _keyFavoritesMigrated = 'favorites_migrated_backend';

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

/// Name of the current favorite list (one list per app). Null until user creates one.
Future<String?> getFavoriteListName() async {
  final p = await _prefs();
  final s = p.getString(_keyFavoriteListName);
  return s?.trim().isEmpty == true ? null : s;
}

Future<void> setFavoriteListName(String name) async {
  final p = await _prefs();
  await p.setString(_keyFavoriteListName, name.trim());
}

/// True if user has not yet created a favorite list (no name and no saved services).
Future<bool> hasNoFavoriteListYet() async {
  final name = await getFavoriteListName();
  final ids = await getFavoriteServiceIds();
  return (name == null || name.isEmpty) && ids.isEmpty;
}

Future<Map<String, String>> getFavoriteNames() async {
  final p = await _prefs();
  final json = p.getString(_keyFavoriteNames);
  if (json == null || json.isEmpty) return {};
  try {
    final map = jsonDecode(json) as Map<String, dynamic>?;
    if (map == null) return {};
    return map.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  } catch (_) {
    return {};
  }
}

Future<void> setFavoriteName(String serviceId, String name) async {
  final map = await getFavoriteNames();
  map[serviceId] = name;
  final p = await _prefs();
  await p.setString(_keyFavoriteNames, jsonEncode(map));
}

Future<String?> getFavoriteName(String serviceId) async {
  final map = await getFavoriteNames();
  return map[serviceId];
}

Future<void> removeFavoriteName(String serviceId) async {
  final map = await getFavoriteNames();
  map.remove(serviceId);
  final p = await _prefs();
  await p.setString(_keyFavoriteNames, jsonEncode(map));
}

Future<Set<String>> getFavoriteServiceIds() async {
  final p = await _prefs();
  final json = p.getString(_keyFavorites);
  if (json == null || json.isEmpty) return {};
  try {
    final list = jsonDecode(json) as List<dynamic>?;
    if (list == null) return {};
    return list.map((e) => e.toString()).where((id) => id.isNotEmpty).toSet();
  } catch (_) {
    return {};
  }
}

Future<void> setFavoriteServiceIds(Set<String> ids) async {
  final p = await _prefs();
  await p.setString(_keyFavorites, jsonEncode(ids.toList()));
}

Future<void> addFavorite(String serviceId, {String? name}) async {
  final ids = await getFavoriteServiceIds();
  ids.add(serviceId);
  await setFavoriteServiceIds(ids);
  if (name != null && name.trim().isNotEmpty) {
    await setFavoriteListName(name.trim());
    await setFavoriteName(serviceId, name.trim());
  }
}

Future<void> removeFavorite(String serviceId) async {
  final ids = await getFavoriteServiceIds();
  ids.remove(serviceId);
  await setFavoriteServiceIds(ids);
  await removeFavoriteName(serviceId);
}

Future<void> toggleFavorite(String serviceId) async {
  final ids = await getFavoriteServiceIds();
  if (ids.contains(serviceId)) {
    ids.remove(serviceId);
  } else {
    ids.add(serviceId);
  }
  await setFavoriteServiceIds(ids);
}

Future<bool> isFavorite(String serviceId) async {
  final ids = await getFavoriteServiceIds();
  return ids.contains(serviceId);
}

/// Whether local favorites have been migrated to the backend for this device.
Future<bool> hasMigratedFavoritesToBackend() async {
  final p = await _prefs();
  return p.getBool(_keyFavoritesMigrated) ?? false;
}

Future<void> markFavoritesMigratedToBackend() async {
  final p = await _prefs();
  await p.setBool(_keyFavoritesMigrated, true);
}
