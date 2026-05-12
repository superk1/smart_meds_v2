import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_backup_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_backup.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_backup_repository.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/reminder_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/reminder_repository.dart';
import 'package:smart_meds_v2/features/inventory/domain/services/notification_service.dart';

class MockInventoryBackupRepository extends Mock implements InventoryBackupRepository {}
class MockInventoryRepository extends Mock implements InventoryRepository {}
class MockNotificationService extends Mock implements NotificationService {}
class MockReminderRepository extends Mock implements ReminderRepository {}

void main() {
  late ProviderContainer container;
  late MockInventoryBackupRepository mockBackupRepo;
  late MockInventoryRepository mockInventoryRepo;
  late MockNotificationService mockNotificationService;
  late MockReminderRepository mockReminderRepo;

  setUp(() {
    mockBackupRepo = MockInventoryBackupRepository();
    mockInventoryRepo = MockInventoryRepository();
    mockNotificationService = MockNotificationService();
    mockReminderRepo = MockReminderRepository();
    container = ProviderContainer(
      overrides: [
        inventoryBackupRepositoryProvider.overrideWithValue(mockBackupRepo),
        inventoryRepositoryProvider.overrideWithValue(mockInventoryRepo),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
        reminderRepositoryProvider.overrideWithValue(mockReminderRepo),
      ],
    );

    // Default stubs
    when(() => mockBackupRepo.loadBackup()).thenAnswer((_) async => null);
    when(() => mockInventoryRepo.getUserInventory()).thenAnswer((_) async => []);
    when(() => mockReminderRepo.getAll()).thenAnswer((_) async => []);
    when(() => mockNotificationService.rescheduleAll(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() {
    container.dispose();
  });

  group('InventoryBackupController Tests', () {
    test('loadLastBackupInfo updates state with backup from repo', () async {
      final backup = InventoryBackup(
        items: [],
        createdAt: DateTime.now(),
        reason: 'manual',
        itemCount: 0,
      );
      when(() => mockBackupRepo.loadBackup()).thenAnswer((_) async => backup);

      final controller = container.read(inventoryBackupControllerProvider.notifier);
      await controller.loadLastBackupInfo();

      final state = container.read(inventoryBackupControllerProvider);
      expect(state.lastBackup, backup);
    });

    test('createManualBackup saves current inventory and updates state', () async {
      final items = [
        InventoryItem(
          id: '1',
          catalogMedicationId: 'cat_1',
          name: 'Test Med',
          expirationDate: DateTime.now(),
          quantity: 5,
        ),
      ];
      final backup = InventoryBackup(
        items: items,
        createdAt: DateTime.now(),
        reason: 'manual',
        itemCount: 1,
      );

      when(() => mockInventoryRepo.getUserInventory()).thenAnswer((_) async => items);
      when(() => mockBackupRepo.saveBackup(items, reason: 'manual')).thenAnswer((_) async {});
      when(() => mockBackupRepo.loadBackup()).thenAnswer((_) async => backup);

      final controller = container.read(inventoryBackupControllerProvider.notifier);
      await controller.createManualBackup();

      final state = container.read(inventoryBackupControllerProvider);
      expect(state.lastBackup, backup);
      expect(state.lastSuccessMessage, contains('creado correctamente'));
      
      verify(() => mockBackupRepo.saveBackup(items, reason: 'manual')).called(1);
    });

    test('restoreLastBackup restores inventory and invalidates provider', () async {
      final backup = InventoryBackup(
        items: [],
        createdAt: DateTime.now(),
        reason: 'manual',
        itemCount: 0,
      );
      
      // Setup state with a backup
      when(() => mockBackupRepo.loadBackup()).thenAnswer((_) async => backup);
      final controller = container.read(inventoryBackupControllerProvider.notifier);
      await controller.loadLastBackupInfo();

      when(() => mockBackupRepo.restoreBackup()).thenAnswer((_) async {});

      await controller.restoreLastBackup();

      final state = container.read(inventoryBackupControllerProvider);
      expect(state.lastSuccessMessage, contains('restaurado correctamente'));
      expect(state.isRestoring, false);
      
      verify(() => mockBackupRepo.restoreBackup()).called(1);
      verify(() => mockNotificationService.rescheduleAll(any(), any())).called(1);
    });

    test('restoreLastBackup handles failure if no backup exists', () async {
      final controller = container.read(inventoryBackupControllerProvider.notifier);
      // No backup loaded in state
      
      await controller.restoreLastBackup();

      final state = container.read(inventoryBackupControllerProvider);
      expect(state.lastErrorMessage, contains('No hay ningún respaldo'));
      verifyNever(() => mockBackupRepo.restoreBackup());
    });
  });
}
