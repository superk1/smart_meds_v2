import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/reminder_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/reminder_repository.dart';
import 'package:smart_meds_v2/features/inventory/domain/services/notification_service.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/core/models/notification_preferences.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/notification_preferences_provider.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}
class MockNotificationService extends Mock implements NotificationService {}
class MockInventoryNotifier extends InventoryNotifier with Mock {
  @override
  Future<List<InventoryItem>> build() async => [];
}
class MockNotificationPreferencesNotifier extends NotificationPreferencesNotifier {
  @override
  NotificationPreferences build() => const NotificationPreferences();
}

void main() {
  late MockReminderRepository mockRepo;
  late MockNotificationService mockNotif;

  setUp(() {
    mockRepo = MockReminderRepository();
    mockNotif = MockNotificationService();
    
    // Register fallback for mocktail
    registerFallbackValue(InventoryReminder(
      id: '',
      inventoryItemId: '',
      type: ReminderType.stock,
      createdAt: DateTime.now(),
    ));
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        reminderRepositoryProvider.overrideWithValue(mockRepo),
        notificationServiceProvider.overrideWithValue(mockNotif),
        inventoryListProvider.overrideWith(() => MockInventoryNotifier()),
        notificationPreferencesProvider.overrideWith(() => MockNotificationPreferencesNotifier()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ReminderNotifier Tests', () {
    test('addReminder calls repository and schedules notification', () async {
      when(() => mockRepo.save(any())).thenAnswer((_) async => {});
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockNotif.scheduleReminder(any(), any())).thenAnswer((_) async => {});

      final container = createContainer();
      final reminder = InventoryReminder(
        id: '1',
        inventoryItemId: 'item1',
        type: ReminderType.expiration,
        createdAt: DateTime.now(),
        targetDate: DateTime.now().add(const Duration(days: 7)),
      );

      await container.read(reminderListProvider.notifier).addReminder(reminder);

      verify(() => mockRepo.save(reminder)).called(1);
      verify(() => mockNotif.scheduleReminder(reminder, any())).called(1);
    });

    test('deleteReminder cancels notification and removes from repo', () async {
      when(() => mockNotif.cancelReminder(any())).thenAnswer((_) async => {});
      when(() => mockRepo.delete(any())).thenAnswer((_) async => {});
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);

      final container = createContainer();
      await container.read(reminderListProvider.notifier).deleteReminder('1');

      verify(() => mockNotif.cancelReminder('1')).called(1);
      verify(() => mockRepo.delete('1')).called(1);
    });
  });
}
