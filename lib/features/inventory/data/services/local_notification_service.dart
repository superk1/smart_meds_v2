import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';
import 'package:smart_meds_v2/features/inventory/domain/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  LocalNotificationService(this._plugin);

  /// TODO (Fase Futura - Snooze):
  /// Para implementar "Posponer" u otras acciones interactivas:
  /// 1. Configurar `actions` dentro de `AndroidNotificationDetails` / `DarwinNotificationDetails`.
  /// 2. En `NotificationInitializer`, manejar `onDidReceiveNotificationResponse` para detectar el actionId (ej. "snooze_action").
  /// 3. Leer el payload (que se puede extender a `action|type|itemId|originalDate`).
  /// 4. Reprogramar llamando a `zonedSchedule` sumando +1 hora o el tiempo deseado.
  @override
  Future<void> scheduleReminder(InventoryReminder reminder, String itemName) async {
    final int id = reminder.id.hashCode;
    final String payload = '${reminder.type.name}|${reminder.inventoryItemId}';

    if (reminder.type == ReminderType.expiration && reminder.targetDate != null) {
      final scheduledDate = tz.TZDateTime.from(reminder.targetDate!, tz.local);
      
      // If the date is in the past, don't schedule
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        return; 
      }

      await _plugin.zonedSchedule(
        id,
        'Vencimiento Próximo',
        'Tu medicamento "$itemName" está próximo a vencer. Por favor, revisa tu botiquín.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'meds_reminders',
            'Recordatorios de Medicamentos',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } else if (reminder.type == ReminderType.stock) {
      final qtyText = reminder.targetQuantity != null ? ' (${reminder.targetQuantity} o menos)' : '';
      await _plugin.show(
        id,
        'Stock Bajo',
        'Quedan pocas unidades$qtyText de "$itemName". Considera reponer tu stock.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'meds_reminders',
            'Recordatorios de Medicamentos',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    }
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    await _plugin.cancel(reminderId.hashCode);
  }

  /// Reprograma todos los recordatorios activos de tipo vencimiento.
  /// Útil para sincronizaciones o cambios globales.
  @override
  Future<void> rescheduleAll(
    List<InventoryReminder> reminders,
    List<InventoryItem> items,
  ) async {
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    for (final reminder in reminders) {
      if (!reminder.isActive) continue;
      if (reminder.type != ReminderType.expiration) continue;
      if (reminder.targetDate == null) continue;

      final item = items.where((i) => i.id == reminder.inventoryItemId).firstOrNull;
      if (item == null) continue;

      final scheduledDate = tz.TZDateTime.from(reminder.targetDate!, tz.local);
      if (scheduledDate.isBefore(now)) continue;

      await scheduleReminder(reminder, item.name);
    }
  }

  /// Utility for testing
  Future<void> showTestNotification() async {
    await _plugin.show(
      999,
      'Prueba de Smart Meds',
      '¡Las notificaciones están funcionando correctamente!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meds_reminders',
          'Recordatorios de Medicamentos',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
