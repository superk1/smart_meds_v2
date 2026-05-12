import 'package:smart_meds_v2/features/admin_review/domain/entities/pending_medication_submission.dart';

abstract class PendingSubmissionRepository {
  Future<List<PendingMedicationSubmission>> getPendingSubmissions();
  Future<void> submitForReview(PendingMedicationSubmission submission);
  Future<void> approveSubmission(String id);
  Future<void> rejectSubmission(String id);
}
