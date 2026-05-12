import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:smart_meds_v2/features/inventory/data/models/inventory_item_model.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_snapshot.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_sync_repository.dart';

class InventorySyncRepositoryImpl implements InventorySyncRepository {
  final InventoryRepository _localRepository;
  final InventoryRemoteDataSource _remoteDataSource;
  final LocalStorageService _storage;

  static const String _versionKey = 'inventory_last_synced_version';
  static const String _dateKey = 'inventory_last_synced_at';

  InventorySyncRepositoryImpl(
    this._localRepository, 
    this._remoteDataSource,
    this._storage,
  );

  @override
  Future<List<InventoryItem>> getLocalInventory() async {
    return _localRepository.getUserInventory();
  }

  @override
  Future<InventorySnapshot> fetchRemoteSnapshot() async {
    final data = await _remoteDataSource.fetchInventorySnapshot();
    final List<InventoryItemModel> models = data['items'];
    
    return InventorySnapshot(
      items: models.map((m) => m.toDomain()).toList(),
      version: data['version'] as int,
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      updatedByDeviceId: data['updatedByDeviceId'] as String,
    );
  }

  @override
  Future<void> saveLocalSnapshot(InventorySnapshot snapshot) async {
    await _localRepository.saveAllInventory(snapshot.items);
    await setLastSyncedMetadata(
      version: snapshot.version,
      syncedAt: snapshot.updatedAt,
    );
  }

  @override
  Future<void> pushRemoteInventoryWithVersion({
    required List<InventoryItem> items,
    required int baseVersion,
  }) async {
    final models = items.map((i) => InventoryItemModel.fromDomain(i)).toList();
    await _remoteDataSource.pushInventory(models, baseVersion: baseVersion);
  }

  @override
  Future<void> pushRemoteInventoryForce(List<InventoryItem> items) async {
    final models = items.map((i) => InventoryItemModel.fromDomain(i)).toList();
    await _remoteDataSource.pushInventory(models, force: true);
  }

  @override
  Future<int?> getLastSyncedVersion() async {
    final stored = _storage.readString(_versionKey);
    return stored != null ? int.tryParse(stored) : null;
  }

  @override
  Future<DateTime?> getLastSyncedAt() async {
    final stored = _storage.readString(_dateKey);
    return stored != null ? DateTime.tryParse(stored) : null;
  }

  @override
  Future<void> setLastSyncedMetadata({
    required int version,
    required DateTime syncedAt,
  }) async {
    await _storage.writeString(_versionKey, version.toString());
    await _storage.writeString(_dateKey, syncedAt.toIso8601String());
  }
}
