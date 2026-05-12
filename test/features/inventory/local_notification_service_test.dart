import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_meds_v2/features/inventory/data/services/local_notification_service.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late LocalNotificationService service;
  late MockFlutterLocalNotificationsPlugin mockPlugin;

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = LocalNotificationService(mockPlugin);

    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(tz.TZDateTime.now(tz.local));
  });

  group('LocalNotificationService Tests', () {
    test('rescheduleAll cancels all and schedules only active future expiration reminders', () async {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 5));
      final pastDate = now.subtract(const Duration(days: 1));

      final List<InventoryItem> items = [
        InventoryItem(
          id: '1',
          name: 'Med 1',
          quantity: 10,
          catalogMedicationId: 'unknown',
          expirationDate: futureDate,
        ),
      ];

      final reminders = [
        InventoryReminder(
          id: 'r1',
          inventoryItemId: '1',
          type: ReminderType.expiration,
          createdAt: now,
          targetDate: futureDate,
          isActive: true,
        ),
        InventoryReminder(
          id: 'r2',
          inventoryItemId: '1',
          type: ReminderType.expiration,
          createdAt: now,
          targetDate: pastDate, // Pasado
          isActive: true,
        ),
        InventoryReminder(
          id: 'r3',
          inventoryItemId: '1',
          type: ReminderType.expiration,
          createdAt: now,
          targetDate: futureDate,
          isActive: false, // Inactivo
        ),
        InventoryReminder(
          id: 'r4',
          inventoryItemId: '1',
          type: ReminderType.stock, // No expiration
          createdAt: now,
          targetQuantity: 5,
          isActive: true,
        ),
      ];

      when(() => mockPlugin.cancelAll()).thenAnswer((_) async => {});
      when(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(named: 'uiLocalNotificationDateInterpretation'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => {});

      await service.rescheduleAll(reminders, items);

      verify(() => mockPlugin.cancelAll()).called(1);
      // Solo r1 debería programarse
      verify(() => mockPlugin.zonedSchedule(
            'r1'.hashCode,
            'Vencimiento Próximo',
            'Tu medicamento "Med 1" está próximo a vencer. Por favor, revisa tu botiquín.',
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(named: 'uiLocalNotificationDateInterpretation'),
            payload: 'expiration|1',
          )).called(1);
      
      // r2, r3, r4 no deben llamar a zonedSchedule
      verifyNever(() => mockPlugin.zonedSchedule(
            'r2'.hashCode,
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(named: 'uiLocalNotificationDateInterpretation'),
            payload: any(named: 'payload'),
          ));
    });
  });
}
