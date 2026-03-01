import 'package:shared_preferences/shared_preferences.dart';

const _keyDecadeBorn = 'profile_decade_born';
const _keyWhereAlwaysWanted = 'profile_where_always_wanted';
const _keyPhone = 'profile_phone';
const _keyAddress = 'profile_address';
const _keyBio = 'profile_bio';

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

Future<void> saveProfileExtended({
  String? decadeBorn,
  String? whereAlwaysWanted,
  String? phone,
  String? address,
  String? bio,
}) async {
  final p = await _prefs();
  if (decadeBorn != null) await p.setString(_keyDecadeBorn, decadeBorn);
  if (whereAlwaysWanted != null) await p.setString(_keyWhereAlwaysWanted, whereAlwaysWanted);
  if (phone != null) await p.setString(_keyPhone, phone);
  if (address != null) await p.setString(_keyAddress, address);
  if (bio != null) await p.setString(_keyBio, bio);
}

Future<String?> getDecadeBorn() async {
  final p = await _prefs();
  return p.getString(_keyDecadeBorn);
}

Future<String?> getWhereAlwaysWanted() async {
  final p = await _prefs();
  return p.getString(_keyWhereAlwaysWanted);
}

Future<String?> getProfilePhone() async {
  final p = await _prefs();
  return p.getString(_keyPhone);
}

Future<String?> getProfileAddress() async {
  final p = await _prefs();
  return p.getString(_keyAddress);
}

Future<String?> getProfileBio() async {
  final p = await _prefs();
  return p.getString(_keyBio);
}

Future<Map<String, String>> getProfileExtendedMap() async {
  final p = await _prefs();
  return {
    'decadeBorn': p.getString(_keyDecadeBorn) ?? '',
    'whereAlwaysWanted': p.getString(_keyWhereAlwaysWanted) ?? '',
    'phone': p.getString(_keyPhone) ?? '',
    'address': p.getString(_keyAddress) ?? '',
    'bio': p.getString(_keyBio) ?? '',
  };
}

Future<void> clearProfileExtended() async {
  final p = await _prefs();
  await p.remove(_keyDecadeBorn);
  await p.remove(_keyWhereAlwaysWanted);
  await p.remove(_keyPhone);
  await p.remove(_keyAddress);
  await p.remove(_keyBio);
}
