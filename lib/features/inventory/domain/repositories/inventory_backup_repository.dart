import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_backup.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';

abstract class InventoryBackupRepository {
  /// Guarda una lista de ítems como el respaldo más reciente.
  Future<void> saveBackup(List<InventoryItem> items, {required String reason});

  /// Carga el respaldo más reciente si existe.
  Future<InventoryBackup?> loadBackup();

  /// Sobrescribe el inventario local actual con el contenido del último respaldo.
  Future<void> restoreBackup();

  /// Elimina el respaldo guardado (opcional).
  Future<void> clearBackup();
}
