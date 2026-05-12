import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_snapshot.dart';

abstract class InventorySyncRepository {
  Future<List<InventoryItem>> getLocalInventory();
  
  Future<InventorySnapshot> fetchRemoteSnapshot();
  Future<void> saveLocalSnapshot(InventorySnapshot snapshot);

  Future<void> pushRemoteInventoryWithVersion({
    required List<InventoryItem> items,
    required int baseVersion,
  });

  Future<void> pushRemoteInventoryForce(List<InventoryItem> items);

  Future<int?> getLastSyncedVersion();
  Future<DateTime?> getLastSyncedAt();
  Future<void> setLastSyncedMetadata({
    required int version,
    required DateTime syncedAt,
  });
}
