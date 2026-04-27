import 'dart:convert';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/catalog/data/models/catalog_medication_model.dart';
import 'package:smart_meds_v2/features/catalog/domain/entities/catalog_medication.dart';
import 'package:smart_meds_v2/features/catalog/domain/repositories/catalog_repository.dart';

class FakeCatalogRepository implements CatalogRepository {
  final LocalStorageService _storage;
  static const String _storageKey = 'catalog_medications';

  final List<CatalogMedication> _medications = [];
  bool _isInitialized = false;

  FakeCatalogRepository(this._storage);

  Future<void> _init() async {
    if (_isInitialized) return;

    final storedData = _storage.readString(_storageKey);
    if (storedData != null) {
      final List<dynamic> decoded = jsonDecode(storedData);
      _medications.clear();
      _medications.addAll(
        decoded.map((m) => CatalogMedicationModel.fromMap(m as Map<String, dynamic>).toDomain()),
      );
    } else {
      // Seed initial data
      _medications.addAll(const [
        CatalogMedication(id: 'cat_1', name: 'Paracetamol 500mg', activeIngredient: 'Paracetamol'),
        CatalogMedication(id: 'cat_2', name: 'Ibuprofeno 400mg', activeIngredient: 'Ibuprofeno'),
        CatalogMedication(id: 'cat_3', name: 'Loratadina 10mg', activeIngredient: 'Loratadina'),
        CatalogMedication(id: 'cat_4', name: 'Omeprazol 20mg', activeIngredient: 'Omeprazol'),
        CatalogMedication(id: 'cat_5', name: 'Amoxicilina 500mg', activeIngredient: 'Amoxicilina'),
      ]);
      await _save();
    }
    _isInitialized = true;
  }

  Future<void> _save() async {
    final String encoded = jsonEncode(
      _medications.map((m) => CatalogMedicationModel.fromDomain(m).toMap()).toList(),
    );
    await _storage.writeString(_storageKey, encoded);
  }

  @override
  Future<List<CatalogMedication>> searchMedications(String query) async {
    await _init();
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.isEmpty) {
      return List.unmodifiable(_medications);
    }
    final lowerQuery = query.toLowerCase();
    return _medications.where((med) {
      return med.name.toLowerCase().contains(lowerQuery) ||
          med.activeIngredient.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<CatalogMedication?> getMedicationById(String id) async {
    await _init();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _medications.firstWhere((med) => med.id == id);
    } catch (e) {
      return null;
    }
  }
}
