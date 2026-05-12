import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/core/errors/app_exception.dart';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/auth/application/providers/auth_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_backup_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/reminder_providers.dart';
import 'package:smart_meds_v2/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:smart_meds_v2/features/inventory/data/repositories/inventory_sync_repository_impl.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_snapshot.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_sync_repository.dart';

final inventoryRemoteDataSourceProvider = Provider<InventoryRemoteDataSource>((ref) {
  final authState = ref.watch(authControllerProvider);
  final token = authState.session?.token;
  
  return InventoryRemoteDataSource(token: token);
});

final inventorySyncRepositoryProvider = Provider<InventorySyncRepository>((ref) {
  return InventorySyncRepositoryImpl(
    ref.watch(inventoryRepositoryProvider),
    ref.watch(inventoryRemoteDataSourceProvider),
    ref.watch(localStorageServiceProvider),
  );
});

final lastSyncedVersionProvider = FutureProvider<int?>((ref) {
  return ref.watch(inventorySyncRepositoryProvider).getLastSyncedVersion();
});

final lastSyncedAtProvider = FutureProvider<DateTime?>((ref) {
  return ref.watch(inventorySyncRepositoryProvider).getLastSyncedAt();
});

class InventorySyncState {
  final bool isSyncing;
  final String? lastErrorMessage;
  final String? lastSuccessMessage;
  final bool hasConflict;
  final InventorySnapshot? pendingRemoteSnapshot;
  final String? conflictMessage;

  const InventorySyncState({
    this.isSyncing = false,
    this.lastErrorMessage,
    this.lastSuccessMessage,
    this.hasConflict = false,
    this.pendingRemoteSnapshot,
    this.conflictMessage,
  });

  static const _unset = Object();

  InventorySyncState copyWith({
    bool? isSyncing,
    Object? lastErrorMessage = _unset,
    Object? lastSuccessMessage = _unset,
    bool? hasConflict,
    Object? pendingRemoteSnapshot = _unset,
    Object? conflictMessage = _unset,
  }) {
    return InventorySyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastErrorMessage: identical(lastErrorMessage, _unset)
          ? this.lastErrorMessage
          : lastErrorMessage as String?,
      lastSuccessMessage: identical(lastSuccessMessage, _unset)
          ? this.lastSuccessMessage
          : lastSuccessMessage as String?,
      hasConflict: hasConflict ?? this.hasConflict,
      pendingRemoteSnapshot: identical(pendingRemoteSnapshot, _unset)
          ? this.pendingRemoteSnapshot
          : pendingRemoteSnapshot as InventorySnapshot?,
      conflictMessage: identical(conflictMessage, _unset)
          ? this.conflictMessage
          : conflictMessage as String?,
    );
  }
}

class InventorySyncController extends Notifier<InventorySyncState> {
  @override
  InventorySyncState build() {
    return InventorySyncState();
  }

  Future<void> syncFromRemote() async {
    state = state.copyWith(isSyncing: true);
    try {
      final repository = ref.read(inventorySyncRepositoryProvider);
      final backupRepo = ref.read(inventoryBackupRepositoryProvider);

      // 1. Create local backup before download
      try {
        final currentItems = await repository.getLocalInventory();
        if (!ref.mounted) return;
        await backupRepo.saveBackup(currentItems, reason: 'before_download');
      } catch (e) {
        if (!ref.mounted) return;
        state = state.copyWith(
          isSyncing: false,
          lastErrorMessage: 'No se pudo crear respaldo previo a la descarga: ${e.toString()}',
        );
        return;
      }

      // 2. Fetch remote snapshot and save
      final snapshot = await repository.fetchRemoteSnapshot();
      if (!ref.mounted) return;
      await repository.saveLocalSnapshot(snapshot);
      if (!ref.mounted) return;
      
      // Refresh inventory list
      ref.invalidate(inventoryListProvider);
      
      await _rescheduleReminders();
      
      state = state.copyWith(
        isSyncing: false,
        lastSuccessMessage: 'Inventario descargado correctamente (v${snapshot.version}). Recordatorios de vencimiento actualizados.',
      );
    } on AuthException {
      try {
        if (!ref.mounted) return;
        ref.read(authControllerProvider.notifier).logout();
        state = state.copyWith(
          isSyncing: false,
          lastErrorMessage: 'Sesión expirada. Inicia sesión de nuevo para sincronizar tu inventario.',
        );
      } catch (_) {}
    } catch (e) {
      try {
        if (!ref.mounted) return;
        state = state.copyWith(
          isSyncing: false,
          lastErrorMessage: 'Error al descargar inventario: ${e.toString()}',
        );
      } catch (_) {}
    }
  }

  Future<void> syncToRemote() async {
    state = state.copyWith(isSyncing: true);
    try {
      final repository = ref.read(inventorySyncRepositoryProvider);
      final backupRepo = ref.read(inventoryBackupRepositoryProvider);

      // 0. Check base version
      final baseVersion = await repository.getLastSyncedVersion();
      if (!ref.mounted) return;
      if (baseVersion == null) {
        state = state.copyWith(
          isSyncing: false,
          lastErrorMessage: 'No se puede subir porque nunca se ha descargado el inventario remoto. Descarga primero para evitar conflictos.',
        );
        return;
      }

      // 1. Create local backup before upload
      try {
        final currentItems = await repository.getLocalInventory();
        if (!ref.mounted) return;
        await backupRepo.saveBackup(currentItems, reason: 'before_upload');
      } catch (e) {
        if (!ref.mounted) return;
        state = state.copyWith(
          isSyncing: false,
          lastErrorMessage: 'No se pudo crear respaldo previo a la subida: ${e.toString()}',
        );
        return;
      }

      // 2. Push remote inventory with version
      final localItems = await repository.getLocalInventory();
      if (!ref.mounted) return;
      await repository.pushRemoteInventoryWithVersion(
        items: localItems,
        baseVersion: baseVersion,
      );
      if (!ref.mounted) return;

      // 3. Post-push sync to get final server version
      final snapshot = await repository.fetchRemoteSnapshot();
      if (!ref.mounted) return;
      await repository.saveLocalSnapshot(snapshot);
      if (!ref.mounted) return;

      ref.invalidate(inventoryListProvider);
      
      await _rescheduleReminders();
      
      state = state.copyWith(
        isSyncing: false,
        lastSuccessMessage: 'Inventario subido correctamente (v${snapshot.version}). Tus cambios ya están en la nube. Recordatorios actualizados.',
      );
    } on InventoryConflictException {
      if (!ref.mounted) return;
      try {
        final repository = ref.read(inventorySyncRepositoryProvider);
        final remoteSnapshot = await repository.fetchRemoteSnapshot();
        if (!ref.mounted) return;
        
        state = state.copyWith(
          isSyncing: false,
          hasConflict: true,
          pendingRemoteSnapshot: remoteSnapshot,
          conflictMessage: 'Otro dispositivo cambió tu inventario en la nube. Elige si mantener la versión de la nube o la de este dispositivo.',
        );
      } catch (e) {
        if (!ref.mounted) return;
        state = state.copyWith(
          isSyncing: false,
          lastErrorMessage: 'Error al obtener estado remoto tras conflicto: ${e.toString()}',
        );
      }
    } on AuthException {
      if (!ref.mounted) return;
      ref.read(authControllerProvider.notifier).logout();
      state = state.copyWith(
        isSyncing: false,
        lastErrorMessage: 'Sesión expirada. Inicia sesión de nuevo para sincronizar tu inventario.',
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isSyncing: false,
        lastErrorMessage: 'Error al subir inventario: ${e.toString()}',
      );
    }
  }

  Future<void> resolveConflictByDownloadingRemote() async {
    final snapshot = state.pendingRemoteSnapshot;
    if (snapshot == null) return;

    state = state.copyWith(isSyncing: true);
    try {
      final repository = ref.read(inventorySyncRepositoryProvider);
      await repository.saveLocalSnapshot(snapshot);
      if (!ref.mounted) return;

      ref.invalidate(inventoryListProvider);

      await _rescheduleReminders();

      state = state.copyWith(
        isSyncing: false,
        hasConflict: false,
        pendingRemoteSnapshot: null,
        conflictMessage: null,
        lastSuccessMessage: 'Se descargó el inventario remoto más reciente (v${snapshot.version}) y se resolvió el conflicto. Recordatorios actualizados.',
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isSyncing: false,
        lastErrorMessage: 'Error al resolver conflicto descargando: ${e.toString()}',
      );
    }
  }

  Future<void> resolveConflictByForceUploadingLocal() async {
    state = state.copyWith(isSyncing: true);
    try {
      final repository = ref.read(inventorySyncRepositoryProvider);
      final backupRepo = ref.read(inventoryBackupRepositoryProvider);

      // 1. Backup before force push
      final currentItems = await repository.getLocalInventory();
      if (!ref.mounted) return;
      await backupRepo.saveBackup(currentItems, reason: 'before_force_upload');
      if (!ref.mounted) return;

      // 2. Force push
      await repository.pushRemoteInventoryForce(currentItems);
      if (!ref.mounted) return;

      // 3. Fetch remote snapshot to update metadata (new version)
      final newSnapshot = await repository.fetchRemoteSnapshot();
      if (!ref.mounted) return;
      await repository.saveLocalSnapshot(newSnapshot);
      if (!ref.mounted) return;

      ref.invalidate(inventoryListProvider);

      await _rescheduleReminders();

      state = state.copyWith(
        isSyncing: false,
        hasConflict: false,
        pendingRemoteSnapshot: null,
        conflictMessage: null,
        lastSuccessMessage: 'Inventario local subido forzadamente. Se ha sobrescrito el inventario remoto (v${newSnapshot.version}). Recordatorios actualizados.',
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isSyncing: false,
        lastErrorMessage: 'Error al resolver conflicto subiendo forzadamente: ${e.toString()}',
      );
    }
  }

  void dismissConflict() {
    state = state.copyWith(
      hasConflict: false,
      pendingRemoteSnapshot: null,
      conflictMessage: null,
    );
  }

  Future<void> _rescheduleReminders() async {
    try {
      final reminders = await ref.read(reminderRepositoryProvider).getAll();
      final items = await ref.read(inventoryRepositoryProvider).getUserInventory();
      await ref.read(notificationServiceProvider).rescheduleAll(reminders, items);
    } catch (e) {
      // Ignore errors so it doesn't break the sync flow
    }
  }

  void clearMessages() {
    state = state.copyWith(
      lastErrorMessage: null,
      lastSuccessMessage: null,
    );
  }
}

final inventorySyncControllerProvider = NotifierProvider<InventorySyncController, InventorySyncState>(() {
  return InventorySyncController();
});
