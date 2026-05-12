import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';

/// Representa un punto de restauración local del inventario.
class InventoryBackup {
  /// Lista de medicamentos respaldados.
  final List<InventoryItem> items;

  /// Fecha y hora en que se creó el respaldo.
  final DateTime createdAt;

  /// Motivo del respaldo (before_download, before_upload, manual).
  final String reason;

  /// Cantidad total de ítems en el respaldo.
  final int itemCount;

  const InventoryBackup({
    required this.items,
    required this.createdAt,
    required this.reason,
    required this.itemCount,
  });
}
