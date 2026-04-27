import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to abstract local storage operations.
class LocalStorageService {
  final SharedPreferences _prefs;

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
}

/// Provider for the LocalStorageService.
/// Note: Since SharedPreferences.getInstance() is async, this needs to be initialized.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('localStorageServiceProvider must be overridden in ProviderScope');
});
