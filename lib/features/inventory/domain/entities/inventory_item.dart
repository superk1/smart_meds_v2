enum ExpirationState {
  valid,
  expiringSoon,
  expired,
}

enum StockState {
  inStock,
  lowStock,
  outOfStock,
}

/// Representa un medicamento físico dentro del botiquín privado del usuario.
/// 
/// Pertenece al **Dominio Privado**.
class InventoryItem {
  /// Identificador único del registro en el inventario local.
  final String id;

  /// Referencia al ID del catálogo global. 
  /// Si no hay match, debe ser [CatalogConstants.unknownId].
  final String catalogMedicationId;

  /// Nombre legible para el usuario.
  final String name;

  /// Fecha de vencimiento del lote específico.
  final DateTime expirationDate;

  /// Unidades disponibles en el botiquín.
  final int quantity;

  const InventoryItem({
    required this.id,
    required this.catalogMedicationId,
    required this.name,
    required this.expirationDate,
    required this.quantity,
  });

  ExpirationState get expirationState {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expDate = DateTime(expirationDate.year, expirationDate.month, expirationDate.day);
    
    if (expDate.isBefore(today)) {
      return ExpirationState.expired;
    }
    
    final difference = expDate.difference(today).inDays;
    if (difference <= 30) {
      return ExpirationState.expiringSoon;
    }
    
    return ExpirationState.valid;
  }

  StockState get stockState {
    if (quantity <= 0) {
      return StockState.outOfStock;
    } else if (quantity <= 2) {
      return StockState.lowStock;
    } else {
      return StockState.inStock;
    }
  }
}
