import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';

abstract class ReminderRepository {
  Future<List<InventoryReminder>> getAll();
  Future<void> save(InventoryReminder reminder);
  Future<void> update(InventoryReminder reminder);
  Future<void> delete(String id);
}
