import 'package:smart_meds_v2/features/catalog/data/datasources/catalog_remote_datasource.dart';
import 'package:smart_meds_v2/features/catalog/domain/entities/catalog_medication.dart';
import 'package:smart_meds_v2/features/catalog/domain/repositories/catalog_repository.dart';

class RemoteCatalogRepository implements CatalogRepository {
  final CatalogRemoteDataSource _remoteDataSource;

  RemoteCatalogRepository(this._remoteDataSource);

  @override
  Future<List<CatalogMedication>> searchMedications(String query) async {
    final models = await _remoteDataSource.getMedications(query: query);
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<CatalogMedication?> getMedicationById(String id) async {
    try {
      final model = await _remoteDataSource.getMedicationById(id);
      return model.toDomain();
    } catch (e) {
      return null;
    }
  }
}
