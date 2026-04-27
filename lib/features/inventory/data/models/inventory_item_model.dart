import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';

class InventoryItemModel {
  final String id;
  final String catalogMedicationId;
  final String name;
  final DateTime expirationDate;
  final int quantity;

  InventoryItemModel({
    required this.id,
    required this.catalogMedicationId,
    required this.name,
    required this.expirationDate,
    required this.quantity,
  });

  factory InventoryItemModel.fromDomain(InventoryItem entity) {
    return InventoryItemModel(
      id: entity.id,
      catalogMedicationId: entity.catalogMedicationId,
      name: entity.name,
      expirationDate: entity.expirationDate,
      quantity: entity.quantity,
    );
  }

  InventoryItem toDomain() {
    return InventoryItem(
      id: id,
      catalogMedicationId: catalogMedicationId,
      name: name,
      expirationDate: expirationDate,
      quantity: quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'catalogMedicationId': catalogMedicationId,
      'name': name,
      'expirationDate': expirationDate.toIso8601String(),
      'quantity': quantity,
    };
  }

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryItemModel(
      id: map['id'] as String,
      catalogMedicationId: map['catalogMedicationId'] as String,
      name: map['name'] as String,
      expirationDate: DateTime.parse(map['expirationDate'] as String),
      quantity: map['quantity'] as int,
    );
  }
}
