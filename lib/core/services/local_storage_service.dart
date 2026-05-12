import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/core/models/notification_preferences.dart';

/// Service to abstract local storage operations.
class LocalStorageService {
  final SharedPreferences _prefs;

  static const String notificationPrefsKey = 'notification_prefs';

  LocalStorageService(this._prefs);

  Future<void> writeString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? readString(String key) {
    return _prefs.getString(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<NotificationPreferences> loadNotificationPreferences() async {
    final str = readString(notificationPrefsKey);
    if (str == null || str.isEmpty) return const NotificationPreferences();
    try {
      final json = jsonDecode(str) as Map<String, dynamic>;
      return NotificationPreferences.fromJson(json);
    } catch (e) {
      return const NotificationPreferences();
    }
  }

  Future<void> saveNotificationPreferences(NotificationPreferences prefs) async {
    await writeString(notificationPrefsKey, jsonEncode(prefs.toJson()));
  }
}

/// Provider for the LocalStorageService.
/// Note: Since SharedPreferences.getInstance() is async, this needs to be initialized.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('localStorageServiceProvider must be overridden in ProviderScope');
});
