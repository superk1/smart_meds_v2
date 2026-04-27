import 'package:smart_meds_v2/core/services/local_storage_service.dart';

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
}
