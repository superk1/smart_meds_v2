/// Representa una propuesta de nuevo medicamento enviada por un usuario.
/// 
/// Pertenece al **Dominio de Moderación**. Actúa como puente hacia el catálogo global.
class PendingMedicationSubmission {
  /// Identificador único de la propuesta.
  final String id;

  /// Nombre del medicamento propuesto por el usuario.
  final String proposedName;

  /// Sustancia activa propuesta por el usuario.
  final String proposedActiveIngredient;

  /// ID del usuario que realizó la propuesta.
  final String userId;

  const PendingMedicationSubmission({
    required this.id,
    required this.proposedName,
    required this.proposedActiveIngredient,
    required this.userId,
  });
}
