import 'package:smart_meds_v2/features/admin_review/domain/entities/pending_medication_submission.dart';

class PendingMedicationSubmissionModel {
  final String id;
  final String proposedName;
  final String proposedActiveIngredient;
  final String userId;

  PendingMedicationSubmissionModel({
    required this.id,
    required this.proposedName,
    required this.proposedActiveIngredient,
    required this.userId,
  });

  factory PendingMedicationSubmissionModel.fromDomain(PendingMedicationSubmission entity) {
    return PendingMedicationSubmissionModel(
      id: entity.id,
      proposedName: entity.proposedName,
      proposedActiveIngredient: entity.proposedActiveIngredient,
      userId: entity.userId,
    );
  }

  PendingMedicationSubmission toDomain() {
    return PendingMedicationSubmission(
      id: id,
      proposedName: proposedName,
      proposedActiveIngredient: proposedActiveIngredient,
      userId: userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proposedName': proposedName,
      'proposedActiveIngredient': proposedActiveIngredient,
      'userId': userId,
    };
  }

  factory PendingMedicationSubmissionModel.fromMap(Map<String, dynamic> map) {
    return PendingMedicationSubmissionModel(
      id: map['id'] as String,
      proposedName: map['proposedName'] as String,
      proposedActiveIngredient: map['proposedActiveIngredient'] as String,
      userId: map['userId'] as String,
    );
  }
}
