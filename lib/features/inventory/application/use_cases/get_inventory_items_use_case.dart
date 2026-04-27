import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_repository.dart';

class GetInventoryItemsUseCase {
  final InventoryRepository _repository;

  GetInventoryItemsUseCase(this._repository);

  Future<List<InventoryItem>> execute() {
    return _repository.getUserInventory();
  }
}
