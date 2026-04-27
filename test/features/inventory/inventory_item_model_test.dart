import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/data/models/inventory_item_model.dart';

void main() {
  group('InventoryItemModel Tests', () {
    test('round trip: entity -> model -> map -> model -> entity', () {
      final expiration = DateTime(2025, 12, 31);
      final entity = InventoryItem(
        id: '1',
        catalogMedicationId: 'cat_1',
        name: 'Med 1',
        expirationDate: expiration,
        quantity: 5,
      );

      final model = InventoryItemModel.fromDomain(entity);
      final map = model.toMap();
      final fromMapModel = InventoryItemModel.fromMap(map);
      final fromMapEntity = fromMapModel.toDomain();

      expect(fromMapEntity.id, entity.id);
      expect(fromMapEntity.catalogMedicationId, entity.catalogMedicationId);
      expect(fromMapEntity.name, entity.name);
      expect(fromMapEntity.expirationDate, entity.expirationDate);
      expect(fromMapEntity.quantity, entity.quantity);
    });
  });
}
