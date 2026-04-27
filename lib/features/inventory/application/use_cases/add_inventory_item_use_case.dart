import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_repository.dart';

class AddInventoryItemUseCase {
  final InventoryRepository _repository;

  AddInventoryItemUseCase(this._repository);

  Future<void> execute(InventoryItem item) {
    return _repository.addInventoryItem(item);
  }
}
