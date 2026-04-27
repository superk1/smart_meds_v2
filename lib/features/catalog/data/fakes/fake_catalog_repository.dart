import 'package:smart_meds_v2/features/catalog/domain/entities/catalog_medication.dart';
import 'package:smart_meds_v2/features/catalog/domain/repositories/catalog_repository.dart';

class FakeCatalogRepository implements CatalogRepository {
  final List<CatalogMedication> _medications = const [
    CatalogMedication(
      id: 'cat_1',
      name: 'Paracetamol 500mg',
      activeIngredient: 'Paracetamol',
    ),
    CatalogMedication(
      id: 'cat_2',
      name: 'Ibuprofeno 400mg',
      activeIngredient: 'Ibuprofeno',
    ),
    CatalogMedication(
      id: 'cat_3',
      name: 'Loratadina 10mg',
      activeIngredient: 'Loratadina',
    ),
    CatalogMedication(
      id: 'cat_4',
      name: 'Omeprazol 20mg',
      activeIngredient: 'Omeprazol',
    ),
    CatalogMedication(
      id: 'cat_5',
      name: 'Amoxicilina 500mg',
      activeIngredient: 'Amoxicilina',
    ),
  ];

  @override
  Future<List<CatalogMedication>> searchMedications(String query) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
    if (query.isEmpty) {
      return _medications;
    }
    final lowerQuery = query.toLowerCase();
    return _medications.where((med) {
      return med.name.toLowerCase().contains(lowerQuery) ||
          med.activeIngredient.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<CatalogMedication?> getMedicationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _medications.firstWhere((med) => med.id == id);
    } catch (e) {
      return null;
    }
  }
}
