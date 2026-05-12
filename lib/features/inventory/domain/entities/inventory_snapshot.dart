import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';

/// Representa el estado del inventario en un punto en el tiempo, 
/// incluyendo metadatos de versionado para el servidor.
class InventorySnapshot {
  /// Lista de medicamentos en este snapshot.
  final List<InventoryItem> items;

  /// Versión secuencial del inventario en el servidor.
  final int version;

  /// Fecha de la última actualización en el servidor.
  final DateTime updatedAt;

  /// ID del dispositivo que realizó la última actualización.
  final String updatedByDeviceId;

  const InventorySnapshot({
    required this.items,
    required this.version,
    required this.updatedAt,
    required this.updatedByDeviceId,
  });
}
