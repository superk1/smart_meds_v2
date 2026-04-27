import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_repository.dart';

class RemoveInventoryItemUseCase {
  final InventoryRepository repository;

  RemoveInventoryItemUseCase(this.repository);

  Future<void> execute(String id) async {
    return repository.removeInventoryItem(id);
  }
}
