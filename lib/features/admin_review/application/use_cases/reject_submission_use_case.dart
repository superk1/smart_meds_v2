import 'package:smart_meds_v2/features/admin_review/domain/repositories/pending_submission_repository.dart';

class RejectSubmissionUseCase {
  final PendingSubmissionRepository _repository;

  RejectSubmissionUseCase(this._repository);

  Future<void> execute(String id) {
    return _repository.rejectSubmission(id);
  }
}
