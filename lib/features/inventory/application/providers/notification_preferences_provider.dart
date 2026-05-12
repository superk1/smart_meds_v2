import 'package:smart_meds_v2/core/models/notification_preferences.dart';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPreferencesNotifier extends Notifier<NotificationPreferences> {
  bool _hasUserModifiedState = false;

  @override
  NotificationPreferences build() {
    // Initial state before async load completes
    _loadPreferences();
    return const NotificationPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await ref.read(localStorageServiceProvider).loadNotificationPreferences();
    if (!_hasUserModifiedState) {
      state = prefs;
    }
  }

  Future<void> setExpirationEnabled(bool value) async {
    _hasUserModifiedState = true;
    final newPrefs = NotificationPreferences(
      expirationAlertsEnabled: value,
      stockAlertsEnabled: state.stockAlertsEnabled,
    );
    state = newPrefs;
    await ref.read(localStorageServiceProvider).saveNotificationPreferences(newPrefs);
  }

  Future<void> setStockEnabled(bool value) async {
    _hasUserModifiedState = true;
    final newPrefs = NotificationPreferences(
      expirationAlertsEnabled: state.expirationAlertsEnabled,
      stockAlertsEnabled: value,
    );
    state = newPrefs;
    await ref.read(localStorageServiceProvider).saveNotificationPreferences(newPrefs);
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(() {
  return NotificationPreferencesNotifier();
});
