enum ReminderType {
  expiration,
  stock,
}

/// Representa un recordatorio configurado por el usuario para un medicamento.
/// 
/// Pertenece al **Dominio Privado**.
class InventoryReminder {
  final String id;
  final String inventoryItemId;
  final ReminderType type;
  final DateTime createdAt;

  /// Para tipo expiration: Fecha exacta en la que debe dispararse el aviso.
  /// Se calcula como [item.expirationDate - N días].
  final DateTime? targetDate;

  /// Para tipo stock: Cantidad mínima que dispara el aviso.
  final int? targetQuantity;

  final bool isActive;

  const InventoryReminder({
    required this.id,
    required this.inventoryItemId,
    required this.type,
    required this.createdAt,
    this.targetDate,
    this.targetQuantity,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventoryItemId': inventoryItemId,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'targetQuantity': targetQuantity,
      'isActive': isActive,
    };
  }

  factory InventoryReminder.fromJson(Map<String, dynamic> json) {
    return InventoryReminder(
      id: json['id'],
      inventoryItemId: json['inventoryItemId'],
      type: ReminderType.values.byName(json['type']),
      createdAt: DateTime.parse(json['createdAt']),
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
      targetQuantity: json['targetQuantity'],
      isActive: json['isActive'] ?? true,
    );
  }

  InventoryReminder copyWith({
    String? id,
    String? inventoryItemId,
    ReminderType? type,
    DateTime? createdAt,
    DateTime? targetDate,
    int? targetQuantity,
    bool? isActive,
  }) {
    return InventoryReminder(
      id: id ?? this.id,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      targetQuantity: targetQuantity ?? this.targetQuantity,
      isActive: isActive ?? this.isActive,
    );
  }
}
