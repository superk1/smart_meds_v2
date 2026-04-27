import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/features/inventory/application/use_cases/add_inventory_item_use_case.dart';
import 'package:smart_meds_v2/features/inventory/application/use_cases/get_inventory_items_use_case.dart';
import 'package:smart_meds_v2/features/inventory/application/use_cases/remove_inventory_item_use_case.dart';
import 'package:smart_meds_v2/features/inventory/application/use_cases/update_inventory_item_use_case.dart';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/inventory/data/fakes/fake_inventory_repository.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return FakeInventoryRepository(ref.watch(localStorageServiceProvider));
});

final getInventoryItemsUseCaseProvider = Provider<GetInventoryItemsUseCase>((ref) {
  return GetInventoryItemsUseCase(ref.watch(inventoryRepositoryProvider));
});

final addInventoryItemUseCaseProvider = Provider<AddInventoryItemUseCase>((ref) {
  return AddInventoryItemUseCase(ref.watch(inventoryRepositoryProvider));
});

final updateInventoryItemUseCaseProvider = Provider<UpdateInventoryItemUseCase>((ref) {
  return UpdateInventoryItemUseCase(ref.watch(inventoryRepositoryProvider));
});

final removeInventoryItemUseCaseProvider = Provider<RemoveInventoryItemUseCase>((ref) {
  return RemoveInventoryItemUseCase(ref.watch(inventoryRepositoryProvider));
});

class InventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  @override
  Future<List<InventoryItem>> build() async {
    return ref.watch(getInventoryItemsUseCaseProvider).execute();
  }

  Future<void> addItem(InventoryItem item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(addInventoryItemUseCaseProvider).execute(item);
      return ref.read(getInventoryItemsUseCaseProvider).execute();
    });
  }

  Future<void> useItem(InventoryItem item) async {
    if (item.quantity <= 0) return;
    
    final updatedItem = InventoryItem(
      id: item.id,
      catalogMedicationId: item.catalogMedicationId,
      name: item.name,
      expirationDate: item.expirationDate,
      quantity: item.quantity - 1,
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(updateInventoryItemUseCaseProvider).execute(updatedItem);
      return ref.read(getInventoryItemsUseCaseProvider).execute();
    });
  }

  Future<void> restockItem(InventoryItem item) async {
    final updatedItem = InventoryItem(
      id: item.id,
      catalogMedicationId: item.catalogMedicationId,
      name: item.name,
      expirationDate: item.expirationDate,
      quantity: item.quantity + 1,
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(updateInventoryItemUseCaseProvider).execute(updatedItem);
      return ref.read(getInventoryItemsUseCaseProvider).execute();
    });
  }

  Future<void> discardItem(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(removeInventoryItemUseCaseProvider).execute(id);
      return ref.read(getInventoryItemsUseCaseProvider).execute();
    });
  }
}

final inventoryListProvider = AsyncNotifierProvider<InventoryNotifier, List<InventoryItem>>(() {
  return InventoryNotifier();
});

enum InventoryFilter {
  all,
  expiringSoon,
  expired,
  outOfStock,
}

class InventoryFilterNotifier extends Notifier<InventoryFilter> {
  @override
  InventoryFilter build() => InventoryFilter.all;

  void setFilter(InventoryFilter filter) {
    state = filter;
  }
}

final inventoryFilterProvider = NotifierProvider<InventoryFilterNotifier, InventoryFilter>(() {
  return InventoryFilterNotifier();
});

class InventorySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clearQuery() {
    state = '';
  }
}

final inventorySearchQueryProvider = NotifierProvider<InventorySearchQueryNotifier, String>(() {
  return InventorySearchQueryNotifier();
});

enum InventorySortCriteria {
  expirationDate,
  nameAZ,
  lowStock,
}

class InventorySortCriteriaNotifier extends Notifier<InventorySortCriteria> {
  @override
  InventorySortCriteria build() => InventorySortCriteria.expirationDate;

  void setSortCriteria(InventorySortCriteria criteria) {
    state = criteria;
  }
}

final inventorySortCriteriaProvider =
    NotifierProvider<InventorySortCriteriaNotifier, InventorySortCriteria>(() {
  return InventorySortCriteriaNotifier();
});

final inventorySummaryProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final inventoryAsync = ref.watch(inventoryListProvider);

  return inventoryAsync.whenData((items) {
    return {
      'total': items.length,
      'expiringSoon': items.where((i) => i.expirationState == ExpirationState.expiringSoon).length,
      'expired': items.where((i) => i.expirationState == ExpirationState.expired).length,
      'outOfStock': items.where((i) => i.stockState == StockState.outOfStock).length,
    };
  });
});

final filteredInventoryProvider = Provider<AsyncValue<List<InventoryItem>>>((ref) {
  final inventoryAsync = ref.watch(inventoryListProvider);
  final filter = ref.watch(inventoryFilterProvider);
  final query = ref.watch(inventorySearchQueryProvider).trim().toLowerCase();
  final sortCriteria = ref.watch(inventorySortCriteriaProvider);

  return inventoryAsync.whenData((items) {
    // 1. Filter by status
    final statusFiltered = switch (filter) {
      InventoryFilter.all => items,
      InventoryFilter.expiringSoon =>
        items.where((i) => i.expirationState == ExpirationState.expiringSoon).toList(),
      InventoryFilter.expired => items.where((i) => i.expirationState == ExpirationState.expired).toList(),
      InventoryFilter.outOfStock => items.where((i) => i.stockState == StockState.outOfStock).toList(),
    };

    // 2. Filter by search query
    final searchFiltered = query.isEmpty
        ? statusFiltered
        : statusFiltered.where((i) => i.name.toLowerCase().contains(query)).toList();

    // 3. Apply Sorting
    return List.of(searchFiltered)
      ..sort((a, b) {
        return switch (sortCriteria) {
          InventorySortCriteria.expirationDate => a.expirationDate.compareTo(b.expirationDate),
          InventorySortCriteria.nameAZ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          InventorySortCriteria.lowStock => a.quantity.compareTo(b.quantity),
        };
      });
  });
});
