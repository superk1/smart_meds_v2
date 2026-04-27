class PendingMedicationSubmission {
  final String id;
  final String proposedName;
  final String proposedActiveIngredient;
  final String userId;

  const PendingMedicationSubmission({
    required this.id,
    required this.proposedName,
    required this.proposedActiveIngredient,
    required this.userId,
  });
}
