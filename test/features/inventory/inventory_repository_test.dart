import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/data/fakes/fake_inventory_repository.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late FakeInventoryRepository repository;
  late FakeLocalStorageService storage;

  setUp(() {
    storage = FakeLocalStorageService();
    repository = FakeInventoryRepository(storage);
  });

  group('FakeInventoryRepository Tests', () {
    test('addInventoryItem combines quantities for same catalogMedicationId and expiration', () async {
      final expiration = DateTime.now().add(const Duration(days: 100));
      final item1 = InventoryItem(
        id: '1',
        catalogMedicationId: 'cat_1',
        name: 'Med 1',
        expirationDate: expiration,
        quantity: 2,
      );
      final item2 = InventoryItem(
        id: '2',
        catalogMedicationId: 'cat_1',
        name: 'Med 1',
        expirationDate: expiration,
        quantity: 3,
      );

      await repository.addInventoryItem(item1);
      await repository.addInventoryItem(item2);

      final items = await repository.getUserInventory();
      // Initially there are 2 seeded items, plus these 2 combined = 3 total?
      // Let's check how many items are in the seed.
      // Seed has 'inv_1' (cat_1) and 'inv_2' (cat_2).
      // 'inv_1' has cat_1 but different expiration probably.
      
      final cat1Items = items.where((i) => i.catalogMedicationId == 'cat_1').toList();
      
      // If expiration matches exactly, it should combine.
      // My item1/item2 have exact same expiration.
      expect(cat1Items.any((i) => i.quantity == 5), isTrue);
    });

    test('addInventoryItem combines quantities for unknown medication with same normalized name', () async {
      final expiration = DateTime.now().add(const Duration(days: 100));
      final item1 = InventoryItem(
        id: '1',
        catalogMedicationId: 'desconocido',
        name: 'Aspirina',
        expirationDate: expiration,
        quantity: 1,
      );
      final item2 = InventoryItem(
        id: '2',
        catalogMedicationId: 'desconocido',
        name: ' aspirína ', // Normalized should match 'aspirina'
        expirationDate: expiration,
        quantity: 4,
      );

      await repository.addInventoryItem(item1);
      await repository.addInventoryItem(item2);

      final items = await repository.getUserInventory();
      final unknownItems = items.where((i) => i.catalogMedicationId == 'desconocido').toList();
      
      expect(unknownItems.any((i) => i.quantity == 5), isTrue);
    });

    test('addInventoryItem throws exception for invalid data', () async {
      final item = InventoryItem(
        id: '1',
        catalogMedicationId: 'cat_1',
        name: '', // Invalid empty name
        expirationDate: DateTime.now().add(const Duration(days: 100)),
        quantity: 1,
      );

      expect(() => repository.addInventoryItem(item), throwsException);
    });
  });
}
