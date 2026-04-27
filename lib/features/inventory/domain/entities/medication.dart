/// Entidad de dominio que representa un medicamento en el inventario.
class Medication {
  final String id;
  final String name;
  final String dose;

  const Medication({
    required this.id,
    required this.name,
    required this.dose,
  });

  /// Crea una copia de la entidad con los campos indicados modificados.
  Medication copyWith({
    String? id,
    String? name,
    String? dose,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Medication &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          dose == other.dose;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ dose.hashCode;

  @override
  String toString() => 'Medication(id: $id, name: $name, dose: $dose)';
}
