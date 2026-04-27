import 'package:smart_meds_v2/features/catalog/domain/entities/catalog_medication.dart';

abstract class CatalogRepository {
  Future<List<CatalogMedication>> searchMedications(String query);
  Future<CatalogMedication?> getMedicationById(String id);
}
