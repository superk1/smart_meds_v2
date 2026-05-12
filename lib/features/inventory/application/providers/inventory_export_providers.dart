import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/reminder_providers.dart';
import 'package:smart_meds_v2/features/inventory/data/datasources/inventory_export_datasource.dart';

final inventoryExportDataSourceProvider = Provider<InventoryExportDataSource>((ref) {
  return InventoryExportDataSource();
});

class InventoryExportImportState {
  final bool isProcessing;
  final String? lastErrorMessage;
  final String? lastSuccessMessage;

  const InventoryExportImportState({
    this.isProcessing = false,
    this.lastErrorMessage,
    this.lastSuccessMessage,
  });

  InventoryExportImportState copyWith({
    bool? isProcessing,
    String? lastErrorMessage,
    String? lastSuccessMessage,
  }) {
    return InventoryExportImportState(
      isProcessing: isProcessing ?? this.isProcessing,
      lastErrorMessage: lastErrorMessage,
      lastSuccessMessage: lastSuccessMessage,
    );
  }
}

class InventoryExportImportController extends Notifier<InventoryExportImportState> {
  @override
  InventoryExportImportState build() {
    return const InventoryExportImportState();
  }

  Future<void> exportInventory() async {
    state = state.copyWith(isProcessing: true, lastErrorMessage: null, lastSuccessMessage: null);
    try {
      final items = await ref.read(inventoryRepositoryProvider).getUserInventory();
      final json = await ref.read(inventoryExportDataSourceProvider).exportToJSON(items);
      await ref.read(inventoryExportDataSourceProvider).shareExportFile(json);
      
      state = state.copyWith(
        isProcessing: false,
        lastSuccessMessage: 'Respaldo generado y compartido correctamente.',
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        lastErrorMessage: 'Error al exportar: ${e.toString()}',
      );
    }
  }

  Future<void> importInventory() async {
    state = state.copyWith(isProcessing: true, lastErrorMessage: null, lastSuccessMessage: null);
    try {
      final items = await ref.read(inventoryExportDataSourceProvider).pickAndParseJSON();
      
      if (items == null) {
        state = state.copyWith(isProcessing: false);
        return;
      }

      await ref.read(inventoryRepositoryProvider).saveAllInventory(items);
      
      // Refresh UI and reschedule notifications
      ref.invalidate(inventoryListProvider);
      
      // We also need to reschedule reminders based on the new items
      final reminders = await ref.read(reminderRepositoryProvider).getAll();
      await ref.read(notificationServiceProvider).rescheduleAll(reminders, items);

      state = state.copyWith(
        isProcessing: false,
        lastSuccessMessage: 'Importación exitosa. Se han cargado ${items.length} medicamentos.',
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        lastErrorMessage: 'Error al importar: ${e.toString()}',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(lastErrorMessage: null, lastSuccessMessage: null);
  }
}

final inventoryExportImportControllerProvider = 
    NotifierProvider<InventoryExportImportController, InventoryExportImportState>(() {
  return InventoryExportImportController();
});
