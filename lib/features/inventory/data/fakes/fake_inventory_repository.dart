import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_repository.dart';

class FakeInventoryRepository implements InventoryRepository {
  final List<InventoryItem> _items = [
    InventoryItem(
      id: 'inv_1',
      catalogMedicationId: 'cat_1', // Paracetamol
      name: 'Paracetamol 500mg',
      expirationDate: DateTime.now().add(const Duration(days: 365)),
      quantity: 2,
    ),
    InventoryItem(
      id: 'inv_2',
      catalogMedicationId: 'cat_2', // Ibuprofeno
      name: 'Ibuprofeno 400mg',
      expirationDate: DateTime.now().add(const Duration(days: 180)),
      quantity: 1,
    ),
  ];

  @override
  Future<List<InventoryItem>> getUserInventory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_items);
  }

  @override
  Future<void> addInventoryItem(InventoryItem item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _items.add(item);
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
  }

  @override
  Future<void> removeInventoryItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _items.removeWhere((item) => item.id == id);
  }
}
