import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/reminder_providers.dart';
import 'package:smart_meds_v2/features/inventory/data/repositories/inventory_backup_repository_impl.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_backup.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_backup_repository.dart';

final inventoryBackupRepositoryProvider = Provider<InventoryBackupRepository>((ref) {
  return InventoryBackupRepositoryImpl(
    ref.watch(localStorageServiceProvider),
    ref.watch(inventoryRepositoryProvider),
  );
});

class InventoryBackupState {
  final InventoryBackup? lastBackup;
  final bool isRestoring;
  final String? lastErrorMessage;
  final String? lastSuccessMessage;

  const InventoryBackupState({
    this.lastBackup,
    this.isRestoring = false,
    this.lastErrorMessage,
    this.lastSuccessMessage,
  });

  InventoryBackupState copyWith({
    InventoryBackup? lastBackup,
    bool? isRestoring,
    String? lastErrorMessage,
    String? lastSuccessMessage,
  }) {
    return InventoryBackupState(
      lastBackup: lastBackup ?? this.lastBackup,
      isRestoring: isRestoring ?? this.isRestoring,
      lastErrorMessage: lastErrorMessage,
      lastSuccessMessage: lastSuccessMessage,
    );
  }
}

class InventoryBackupController extends Notifier<InventoryBackupState> {
  @override
  InventoryBackupState build() {
    // Load last backup info on startup
    Future.microtask(() => loadLastBackupInfo());
    return const InventoryBackupState();
  }

  Future<void> loadLastBackupInfo() async {
    try {
      if (!ref.mounted) return;
      final repo = ref.read(inventoryBackupRepositoryProvider);
      final backup = await repo.loadBackup();
      if (!ref.mounted) return;
      state = state.copyWith(lastBackup: backup);
    } catch (e) {
      // Si el provider se dispone durante la carga asíncrona, ignoramos el error
    }
  }

  Future<void> createManualBackup() async {
    try {
      final inventoryRepo = ref.read(inventoryRepositoryProvider);
      final items = await inventoryRepo.getUserInventory();
      if (!ref.mounted) return;
      
      final backupRepo = ref.read(inventoryBackupRepositoryProvider);
      await backupRepo.saveBackup(items, reason: 'manual');
      if (!ref.mounted) return;
      
      final newBackup = await backupRepo.loadBackup();
      if (!ref.mounted) return;
      state = state.copyWith(
        lastBackup: newBackup,
        lastSuccessMessage: 'Respaldo manual creado correctamente.',
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        lastErrorMessage: 'Error al crear el respaldo manual: ${e.toString()}',
      );
    }
  }

  Future<void> restoreLastBackup() async {
    if (state.lastBackup == null) {
      state = state.copyWith(lastErrorMessage: 'No hay ningún respaldo para restaurar.');
      return;
    }

    state = state.copyWith(isRestoring: true);
    try {
      final repo = ref.read(inventoryBackupRepositoryProvider);
      await repo.restoreBackup();
      if (!ref.mounted) return;
      
      // Refresh inventory list
      ref.invalidate(inventoryListProvider);
      
      await _rescheduleReminders();

      state = state.copyWith(
        isRestoring: false,
        lastSuccessMessage: 'Inventario restaurado correctamente. Recordatorios de vencimiento ajustados al respaldo.',
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isRestoring: false,
        lastErrorMessage: 'Error al restaurar el respaldo: ${e.toString()}',
      );
    }
  }

  Future<void> _rescheduleReminders() async {
    try {
      final reminders = await ref.read(reminderRepositoryProvider).getAll();
      final items = await ref.read(inventoryRepositoryProvider).getUserInventory();
      await ref.read(notificationServiceProvider).rescheduleAll(reminders, items);
    } catch (e) {
      // Ignore
    }
  }

  void clearMessages() {
    state = state.copyWith(
      lastErrorMessage: null,
      lastSuccessMessage: null,
    );
  }
}

final inventoryBackupControllerProvider = 
    NotifierProvider<InventoryBackupController, InventoryBackupState>(() {
  return InventoryBackupController();
});
