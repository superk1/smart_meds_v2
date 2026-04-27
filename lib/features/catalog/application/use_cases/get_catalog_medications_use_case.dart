import 'package:smart_meds_v2/features/catalog/domain/entities/catalog_medication.dart';
import 'package:smart_meds_v2/features/catalog/domain/repositories/catalog_repository.dart';

class GetCatalogMedicationsUseCase {
  final CatalogRepository _repository;

  GetCatalogMedicationsUseCase(this._repository);

  Future<List<CatalogMedication>> execute() {
    return _repository.searchMedications('');
  }
}
