import 'package:smart_meds_v2/features/catalog/domain/entities/catalog_medication.dart';
import 'package:smart_meds_v2/features/catalog/domain/repositories/catalog_repository.dart';

class SearchCatalogMedicationsUseCase {
  final CatalogRepository _repository;

  SearchCatalogMedicationsUseCase(this._repository);

  Future<List<CatalogMedication>> execute(String query) {
    return _repository.searchMedications(query);
  }
}
