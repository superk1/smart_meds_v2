import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/core/notifications/notification_initializer.dart';
import 'package:smart_meds_v2/features/inventory/data/services/local_notification_service.dart';
import 'package:smart_meds_v2/features/inventory/data/repositories/local_reminder_repository_impl.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/reminder_repository.dart';
import 'package:smart_meds_v2/features/inventory/domain/services/notification_service.dart';
import 'package:smart_meds_v2/core/models/notification_preferences.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/notification_preferences_provider.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return LocalReminderRepositoryImpl(ref.watch(localStorageServiceProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService(NotificationInitializer.plugin);
});

class ReminderNotifier extends AsyncNotifier<List<InventoryReminder>> {
  @override
  Future<List<InventoryReminder>> build() async {
    return ref.watch(reminderRepositoryProvider).getAll();
  }

  Future<void> addReminder(InventoryReminder reminder) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(reminderRepositoryProvider).save(reminder);
      final prefs = ref.read(notificationPreferencesProvider);
      if (reminder.isActive && _isNotificationTypeEnabled(prefs, reminder)) {
        final itemName = _getItemName(reminder.inventoryItemId);
        await ref.read(notificationServiceProvider).scheduleReminder(reminder, itemName);
      }
      return ref.read(reminderRepositoryProvider).getAll();
    });
  }

  Future<void> toggleReminder(InventoryReminder reminder) async {
    final updated = reminder.copyWith(isActive: !reminder.isActive);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(reminderRepositoryProvider).update(updated);
      final prefs = ref.read(notificationPreferencesProvider);
      if (updated.isActive && _isNotificationTypeEnabled(prefs, updated)) {
        final itemName = _getItemName(updated.inventoryItemId);
        await ref.read(notificationServiceProvider).scheduleReminder(updated, itemName);
      } else {
        await ref.read(notificationServiceProvider).cancelReminder(updated.id);
      }
      return ref.read(reminderRepositoryProvider).getAll();
    });
  }

  bool _isNotificationTypeEnabled(NotificationPreferences prefs, InventoryReminder reminder) {
    if (reminder.type == ReminderType.expiration && !prefs.expirationAlertsEnabled) {
      return false;
    }
    if (reminder.type == ReminderType.stock && !prefs.stockAlertsEnabled) {
      return false;
    }
    return true;
  }

  String _getItemName(String itemId) {
    final inventory = ref.read(inventoryListProvider).value ?? [];
    return inventory.where((i) => i.id == itemId).firstOrNull?.name ?? 'Medicamento';
  }

  Future<void> deleteReminder(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(notificationServiceProvider).cancelReminder(id);
      await ref.read(reminderRepositoryProvider).delete(id);
      return ref.read(reminderRepositoryProvider).getAll();
    });
  }
}

final reminderListProvider = AsyncNotifierProvider<ReminderNotifier, List<InventoryReminder>>(() {
  return ReminderNotifier();
});

final remindersForItemProvider = Provider.family<List<InventoryReminder>, String>((ref, itemId) {
  final allReminders = ref.watch(reminderListProvider).value ?? [];
  return allReminders.where((r) => r.inventoryItemId == itemId).toList();
});

/// Identifica qué recordatorios deberían disparar una alerta visual en la app HOY.
final activeAlertsProvider = Provider<List<InventoryReminder>>((ref) {
  final reminders = ref.watch(reminderListProvider).value ?? [];
  final inventory = ref.watch(inventoryListProvider).value ?? [];
  if (reminders.isEmpty) return [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return reminders.where((r) {
    if (!r.isActive) return false;

    // Buscar el item relacionado para ver su estado actual
    final item = inventory.where((i) => i.id == r.inventoryItemId).firstOrNull;
    if (item == null) return false;

    if (r.type == ReminderType.expiration && r.targetDate != null) {
      final target = DateTime(r.targetDate!.year, r.targetDate!.month, r.targetDate!.day);
      return today.isAtSameMomentAs(target) || today.isAfter(target);
    }

    if (r.type == ReminderType.stock && r.targetQuantity != null) {
      return item.quantity <= r.targetQuantity!;
    }

    return false; 
  }).toList();
});
