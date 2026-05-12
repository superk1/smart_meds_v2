import 'dart:convert';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/inventory/data/models/inventory_item_model.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_backup.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_backup_repository.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryBackupRepositoryImpl implements InventoryBackupRepository {
  final LocalStorageService _storage;
  final InventoryRepository _inventoryRepository;
  
  static const String _backupKey = 'inventory_last_backup';

  InventoryBackupRepositoryImpl(this._storage, this._inventoryRepository);

  @override
  Future<void> saveBackup(List<InventoryItem> items, {required String reason}) async {
    final backup = {
      'items': items.map((i) => InventoryItemModel.fromDomain(i).toMap()).toList(),
      'createdAt': DateTime.now().toIso8601String(),
      'reason': reason,
      'itemCount': items.length,
    };

    final String encoded = jsonEncode(backup);
    await _storage.writeString(_backupKey, encoded);
  }

  @override
  Future<InventoryBackup?> loadBackup() async {
    final String? storedData = _storage.readString(_backupKey);
    if (storedData == null) return null;

    try {
      final Map<String, dynamic> decoded = jsonDecode(storedData);
      final List<dynamic> itemsData = decoded['items'];
      
      final items = itemsData
          .map((m) => InventoryItemModel.fromMap(m as Map<String, dynamic>).toDomain())
          .toList();

      return InventoryBackup(
        items: items,
        createdAt: DateTime.parse(decoded['createdAt']),
        reason: decoded['reason'] as String,
        itemCount: decoded['itemCount'] as int,
      );
    } catch (e) {
      // If backup is corrupted, clear it and return null
      await clearBackup();
      return null;
    }
  }

  @override
  Future<void> restoreBackup() async {
    final backup = await loadBackup();
    if (backup == null) {
      throw Exception('No hay respaldo disponible para restaurar');
    }

    await _inventoryRepository.saveAllInventory(backup.items);
  }

  @override
  Future<void> clearBackup() async {
    await _storage.remove(_backupKey);
  }
}
