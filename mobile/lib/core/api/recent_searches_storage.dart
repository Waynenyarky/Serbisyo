import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _keyRecentSearches = 'recent_search_queries';
const _maxRecentSearches = 10;

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

/// Returns the list of recent search queries (most recent first).
Future<List<String>> getRecentSearches() async {
  final p = await _prefs();
  final json = p.getString(_keyRecentSearches);
  if (json == null || json.isEmpty) return [];
  try {
    final list = jsonDecode(json) as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => e.toString().trim()).where((q) => q.isNotEmpty).toList();
  } catch (_) {
    return [];
  }
}

/// Records a search query. Puts [query] at the front and keeps order, max [_maxRecentSearches].
Future<void> addRecentSearch(String query) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return;
  final list = await getRecentSearches();
  final updated = [
    trimmed,
    ...list.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
  ].take(_maxRecentSearches).toList();
  final p = await _prefs();
  await p.setString(_keyRecentSearches, jsonEncode(updated));
}

/// Removes a query from recent searches.
Future<void> removeRecentSearch(String query) async {
  final list = await getRecentSearches();
  final updated = list.where((q) => q != query).toList();
  final p = await _prefs();
  await p.setString(_keyRecentSearches, jsonEncode(updated));
}

/// Clears all recent searches.
Future<void> clearRecentSearches() async {
  final p = await _prefs();
  await p.remove(_keyRecentSearches);
}
