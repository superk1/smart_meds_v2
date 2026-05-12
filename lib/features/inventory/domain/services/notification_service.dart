import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';

import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';

abstract class NotificationService {
  Future<void> scheduleReminder(InventoryReminder reminder, String itemName);
  Future<void> cancelReminder(String reminderId);
  Future<void> rescheduleAll(List<InventoryReminder> reminders, List<InventoryItem> items);
}

class StubNotificationService implements NotificationService {
  @override
  Future<void> scheduleReminder(InventoryReminder reminder, String itemName) async {
    // ignore: avoid_print
    print('STUB: Scheduling reminder ${reminder.id} for $itemName');
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    // ignore: avoid_print
    print('STUB: Canceling reminder $reminderId');
  }

  @override
  Future<void> rescheduleAll(List<InventoryReminder> reminders, List<InventoryItem> items) async {
    // ignore: avoid_print
    print('STUB: Rescheduling all reminders');
  }
}
