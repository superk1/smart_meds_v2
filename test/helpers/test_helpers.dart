import 'dart:convert';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/core/models/notification_preferences.dart';

class FakeLocalStorageService implements LocalStorageService {
  final Map<String, String> _data = {};

  @override
  String? readString(String key) => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<NotificationPreferences> loadNotificationPreferences() async {
    final str = readString(LocalStorageService.notificationPrefsKey);
    if (str == null || str.isEmpty) return const NotificationPreferences();
    try {
      final json = jsonDecode(str) as Map<String, dynamic>;
      return NotificationPreferences.fromJson(json);
    } catch (e) {
      return const NotificationPreferences();
    }
  }

  @override
  Future<void> saveNotificationPreferences(NotificationPreferences prefs) async {
    await writeString(LocalStorageService.notificationPrefsKey, jsonEncode(prefs.toJson()));
  }
}
