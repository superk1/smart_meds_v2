import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_repository.dart';

class UpdateInventoryItemUseCase {
  final InventoryRepository repository;

  UpdateInventoryItemUseCase(this.repository);

  Future<void> execute(InventoryItem item) async {
    return repository.updateInventoryItem(item);
  }
}
