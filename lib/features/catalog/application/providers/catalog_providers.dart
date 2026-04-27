import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/features/catalog/application/use_cases/get_catalog_medications_use_case.dart';
import 'package:smart_meds_v2/features/catalog/application/use_cases/search_catalog_medications_use_case.dart';
import 'package:smart_meds_v2/features/catalog/data/fakes/fake_catalog_repository.dart';
import 'package:smart_meds_v2/features/catalog/domain/entities/catalog_medication.dart';
import 'package:smart_meds_v2/features/catalog/domain/repositories/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return FakeCatalogRepository();
});

final getCatalogMedicationsUseCaseProvider = Provider<GetCatalogMedicationsUseCase>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return GetCatalogMedicationsUseCase(repository);
});

final searchCatalogMedicationsUseCaseProvider = Provider<SearchCatalogMedicationsUseCase>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return SearchCatalogMedicationsUseCase(repository);
});

class CatalogSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final catalogSearchQueryProvider = NotifierProvider<CatalogSearchQueryNotifier, String>(() {
  return CatalogSearchQueryNotifier();
});

final catalogListProvider = FutureProvider<List<CatalogMedication>>((ref) async {
  final query = ref.watch(catalogSearchQueryProvider);
  if (query.isEmpty) {
    return ref.watch(getCatalogMedicationsUseCaseProvider).execute();
  } else {
    return ref.watch(searchCatalogMedicationsUseCaseProvider).execute(query);
  }
});
