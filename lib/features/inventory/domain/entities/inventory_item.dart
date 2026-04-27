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

class InventoryItem {
  final String id;
  final String catalogMedicationId;
  final String name;
  final DateTime expirationDate;
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
    } else if (quantity == 1) {
      return StockState.lowStock;
    } else {
      return StockState.inStock;
    }
  }
}
