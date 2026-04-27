import 'package:smart_meds_v2/features/admin_review/domain/entities/pending_medication_submission.dart';
import 'package:smart_meds_v2/features/admin_review/domain/repositories/pending_submission_repository.dart';

class GetPendingSubmissionsUseCase {
  final PendingSubmissionRepository _repository;

  GetPendingSubmissionsUseCase(this._repository);

  Future<List<PendingMedicationSubmission>> execute() {
    return _repository.getPendingSubmissions();
  }
}
