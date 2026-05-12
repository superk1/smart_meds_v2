import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getUserInventory();
  Future<void> addInventoryItem(InventoryItem item);
  Future<void> updateInventoryItem(InventoryItem item);
  Future<void> removeInventoryItem(String id);
  Future<void> saveAllInventory(List<InventoryItem> items);
}
