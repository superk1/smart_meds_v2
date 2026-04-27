import 'package:smart_meds_v2/features/catalog/domain/entities/catalog_medication.dart';

class CatalogMedicationModel {
  final String id;
  final String name;
  final String activeIngredient;

  CatalogMedicationModel({
    required this.id,
    required this.name,
    required this.activeIngredient,
  });

  factory CatalogMedicationModel.fromDomain(CatalogMedication entity) {
    return CatalogMedicationModel(
      id: entity.id,
      name: entity.name,
      activeIngredient: entity.activeIngredient,
    );
  }

  CatalogMedication toDomain() {
    return CatalogMedication(
      id: id,
      name: name,
      activeIngredient: activeIngredient,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'activeIngredient': activeIngredient,
    };
  }

  factory CatalogMedicationModel.fromMap(Map<String, dynamic> map) {
    return CatalogMedicationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      activeIngredient: map['activeIngredient'] as String,
    );
  }
}
