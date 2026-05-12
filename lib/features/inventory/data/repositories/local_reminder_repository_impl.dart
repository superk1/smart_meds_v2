import 'dart:convert';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/reminder_repository.dart';

class LocalReminderRepositoryImpl implements ReminderRepository {
  final LocalStorageService _storage;
  static const String _key = 'inventory_reminders';

  LocalReminderRepositoryImpl(this._storage);

  @override
  Future<List<InventoryReminder>> getAll() async {
    final data = _storage.readString(_key);
    if (data == null) return [];

    try {
      final List<dynamic> list = jsonDecode(data);
      return list.map((json) => InventoryReminder.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> save(InventoryReminder reminder) async {
    final reminders = await getAll();
    reminders.add(reminder);
    await _saveAll(reminders);
  }

  @override
  Future<void> update(InventoryReminder reminder) async {
    final reminders = await getAll();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      reminders[index] = reminder;
      await _saveAll(reminders);
    }
  }

  @override
  Future<void> delete(String id) async {
    final reminders = await getAll();
    reminders.removeWhere((r) => r.id == id);
    await _saveAll(reminders);
  }

  Future<void> _saveAll(List<InventoryReminder> reminders) async {
    final data = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await _storage.writeString(_key, data);
  }
}
