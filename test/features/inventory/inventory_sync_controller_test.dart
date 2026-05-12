import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_meds_v2/core/errors/app_exception.dart';
import 'package:smart_meds_v2/features/auth/application/providers/auth_providers.dart';
import 'package:smart_meds_v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_backup_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_sync_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_snapshot.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_backup_repository.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_sync_repository.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/reminder_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/reminder_repository.dart';
import 'package:smart_meds_v2/features/inventory/domain/services/notification_service.dart';

import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';

class MockInventorySyncRepository extends Mock implements InventorySyncRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockInventoryBackupRepository extends Mock implements InventoryBackupRepository {}
class MockNotificationService extends Mock implements NotificationService {}
class MockReminderRepository extends Mock implements ReminderRepository {}
class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late ProviderContainer container;
  late MockInventorySyncRepository mockRepo;
  late MockAuthRepository mockAuthRepo;
  late MockInventoryBackupRepository mockBackupRepo;
  late MockNotificationService mockNotificationService;
  late MockReminderRepository mockReminderRepo;
  late MockInventoryRepository mockInventoryRepo;

  setUp(() {
    mockRepo = MockInventorySyncRepository();
    mockAuthRepo = MockAuthRepository();
    mockBackupRepo = MockInventoryBackupRepository();
    mockNotificationService = MockNotificationService();
    mockReminderRepo = MockReminderRepository();
    mockInventoryRepo = MockInventoryRepository();
    
    container = ProviderContainer(
      overrides: [
        inventorySyncRepositoryProvider.overrideWithValue(mockRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        inventoryBackupRepositoryProvider.overrideWithValue(mockBackupRepo),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
        reminderRepositoryProvider.overrideWithValue(mockReminderRepo),
        inventoryRepositoryProvider.overrideWithValue(mockInventoryRepo),
      ],
    );

    // Default stubs
    registerFallbackValue(InventorySnapshot(
      items: [],
      version: 0,
      updatedAt: DateTime.now(),
      updatedByDeviceId: '',
    ));
    
    when(() => mockBackupRepo.saveBackup(any(), reason: any(named: 'reason')))
        .thenAnswer((_) async {});
    when(() => mockBackupRepo.loadBackup()).thenAnswer((_) async => null);
    when(() => mockRepo.getLocalInventory()).thenAnswer((_) async => []);
    when(() => mockReminderRepo.getAll()).thenAnswer((_) async => []);
    when(() => mockInventoryRepo.getUserInventory()).thenAnswer((_) async => []);
    when(() => mockNotificationService.rescheduleAll(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() {
    container.dispose();
  });

  group('InventorySyncController Tests - Phase 18 Conflict Resolution', () {
    test('syncToRemote sets conflict state on InventoryConflictException', () async {
      final remoteSnapshot = InventorySnapshot(
        items: [],
        version: 10,
        updatedAt: DateTime.now(),
        updatedByDeviceId: 'device_2',
      );

      when(() => mockRepo.getLastSyncedVersion()).thenAnswer((_) async => 3);
      when(() => mockRepo.pushRemoteInventoryWithVersion(
        items: any(named: 'items'),
        baseVersion: any(named: 'baseVersion'),
      )).thenThrow(const InventoryConflictException());
      when(() => mockRepo.fetchRemoteSnapshot()).thenAnswer((_) async => remoteSnapshot);

      final controller = container.read(inventorySyncControllerProvider.notifier);
      await controller.syncToRemote();

      final state = container.read(inventorySyncControllerProvider);
      expect(state.hasConflict, true);
      expect(state.pendingRemoteSnapshot, remoteSnapshot);
      expect(state.conflictMessage, contains('Otro dispositivo cambió tu inventario en la nube'));
    });

    test('resolveConflictByDownloadingRemote saves snapshot and clears conflict', () async {
      final snapshot = InventorySnapshot(
        items: [
          InventoryItem(
            id: 'rem_1',
            catalogMedicationId: 'cat_1',
            name: 'Remote Med',
            expirationDate: DateTime.now(),
            quantity: 1,
          )
        ],
        version: 10,
        updatedAt: DateTime.now(),
        updatedByDeviceId: 'device_2',
      );

      // Setup initial conflict state
      when(() => mockRepo.getLastSyncedVersion()).thenAnswer((_) async => 3);
      when(() => mockRepo.pushRemoteInventoryWithVersion(
        items: any(named: 'items'),
        baseVersion: any(named: 'baseVersion'),
      )).thenThrow(const InventoryConflictException());
      when(() => mockRepo.fetchRemoteSnapshot()).thenAnswer((_) async => snapshot);
      when(() => mockRepo.saveLocalSnapshot(any())).thenAnswer((_) async {});

      final controller = container.read(inventorySyncControllerProvider.notifier);
      await controller.syncToRemote();
      
      // Resolve
      await controller.resolveConflictByDownloadingRemote();

      final state = container.read(inventorySyncControllerProvider);
      expect(state.hasConflict, false);
      expect(state.pendingRemoteSnapshot, null);
      expect(state.lastSuccessMessage, contains('descargó el inventario remoto más reciente'));
      verify(() => mockRepo.saveLocalSnapshot(snapshot)).called(1);
      verify(() => mockNotificationService.rescheduleAll(any(), any())).called(1);
    });

    test('resolveConflictByForceUploadingLocal pushes local and clears conflict', () async {
      final currentLocal = [
        InventoryItem(
          id: 'loc_1',
          catalogMedicationId: 'cat_1',
          name: 'Local Med',
          expirationDate: DateTime.now(),
          quantity: 5,
        )
      ];
      final newSnapshotAfterForce = InventorySnapshot(
        items: currentLocal,
        version: 11,
        updatedAt: DateTime.now(),
        updatedByDeviceId: 'my_device',
      );

      when(() => mockRepo.getLocalInventory()).thenAnswer((_) async => currentLocal);
      when(() => mockRepo.pushRemoteInventoryForce(any())).thenAnswer((_) async {});
      when(() => mockRepo.fetchRemoteSnapshot()).thenAnswer((_) async => newSnapshotAfterForce);
      when(() => mockRepo.saveLocalSnapshot(any())).thenAnswer((_) async {});

      final controller = container.read(inventorySyncControllerProvider.notifier);
      // Manually set conflict state for the test
      // Actually, easier to just call the method if logic is independent of current state except for pendingRemoteSnapshot (which is used in download but not force upload)
      
      await controller.resolveConflictByForceUploadingLocal();

      final state = container.read(inventorySyncControllerProvider);
      expect(state.hasConflict, false);
      expect(state.lastSuccessMessage, contains('subido forzadamente'));
      
      verify(() => mockBackupRepo.saveBackup(currentLocal, reason: 'before_force_upload')).called(1);
      verify(() => mockRepo.pushRemoteInventoryForce(currentLocal)).called(1);
      verify(() => mockRepo.saveLocalSnapshot(newSnapshotAfterForce)).called(1);
      verify(() => mockNotificationService.rescheduleAll(any(), any())).called(1);
    });

    test('dismissConflict clears conflict state without actions', () async {
      when(() => mockRepo.getLastSyncedVersion()).thenAnswer((_) async => 3);
      when(() => mockRepo.pushRemoteInventoryWithVersion(
        items: any(named: 'items'),
        baseVersion: any(named: 'baseVersion'),
      )).thenThrow(const InventoryConflictException());
      when(() => mockRepo.fetchRemoteSnapshot()).thenAnswer((_) async => InventorySnapshot(
        items: [], version: 10, updatedAt: DateTime.now(), updatedByDeviceId: 'dev'
      ));

      final controller = container.read(inventorySyncControllerProvider.notifier);
      await controller.syncToRemote();
      
      controller.dismissConflict();

      final state = container.read(inventorySyncControllerProvider);
      expect(state.hasConflict, false);
      expect(state.pendingRemoteSnapshot, null);
      expect(state.conflictMessage, null);
    });
  });
}
