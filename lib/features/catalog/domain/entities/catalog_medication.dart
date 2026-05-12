/// Representa un medicamento validado en el catálogo maestro.
/// 
/// Pertenece al **Dominio Global**.
class CatalogMedication {
  /// Identificador único en el catálogo global.
  final String id;

  /// Nombre comercial o genérico estandarizado.
  final String name;

  /// Compuesto químico principal.
  final String activeIngredient;

  const CatalogMedication({
    required this.id,
    required this.name,
    required this.activeIngredient,
  });
}
