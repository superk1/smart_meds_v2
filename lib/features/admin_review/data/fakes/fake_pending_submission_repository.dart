import 'package:smart_meds_v2/features/admin_review/domain/entities/pending_medication_submission.dart';
import 'package:smart_meds_v2/features/admin_review/domain/repositories/pending_submission_repository.dart';

class FakePendingSubmissionRepository implements PendingSubmissionRepository {
  final List<PendingMedicationSubmission> _submissions = [
    const PendingMedicationSubmission(
      id: 'sub_1',
      proposedName: 'Aspirina 500mg',
      proposedActiveIngredient: 'Ácido Acetilsalicílico',
      userId: 'user_123',
    ),
    const PendingMedicationSubmission(
      id: 'sub_2',
      proposedName: 'Tempra Forte',
      proposedActiveIngredient: 'Paracetamol',
      userId: 'user_456',
    ),
  ];

  @override
  Future<List<PendingMedicationSubmission>> getPendingSubmissions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_submissions);
  }

  @override
  Future<void> approveSubmission(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _submissions.removeWhere((sub) => sub.id == id);
  }

  @override
  Future<void> rejectSubmission(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _submissions.removeWhere((sub) => sub.id == id);
  }
}
