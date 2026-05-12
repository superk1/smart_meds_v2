import 'package:smart_meds_v2/core/services/local_storage_service.dart';

abstract class SecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

/// Implementation using SharedPreferences as a placeholder for real secure storage.
class InsecureSecureStorageService implements SecureStorageService {
  final LocalStorageService _localStorage;

  InsecureSecureStorageService(this._localStorage);

  @override
  Future<void> write(String key, String value) async {
    await _localStorage.writeString(key, value);
  }

  @override
  Future<String?> read(String key) async {
    return _localStorage.readString(key);
  }

  @override
  Future<void> delete(String key) async {
    await _localStorage.remove(key);
  }
}
