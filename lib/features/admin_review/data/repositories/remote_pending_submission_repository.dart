import 'package:smart_meds_v2/features/admin_review/data/datasources/admin_review_remote_datasource.dart';
import 'package:smart_meds_v2/features/admin_review/data/models/pending_medication_submission_model.dart';
import 'package:smart_meds_v2/features/admin_review/domain/entities/pending_medication_submission.dart';
import 'package:smart_meds_v2/features/admin_review/domain/repositories/pending_submission_repository.dart';

class RemotePendingSubmissionRepository implements PendingSubmissionRepository {
  final AdminReviewRemoteDataSource _dataSource;

  RemotePendingSubmissionRepository(this._dataSource);

  @override
  Future<List<PendingMedicationSubmission>> getPendingSubmissions() async {
    final models = await _dataSource.getPendingSubmissions();
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<void> submitForReview(PendingMedicationSubmission submission) async {
    final model = PendingMedicationSubmissionModel.fromDomain(submission);
    await _dataSource.submitForReview(model);
  }

  @override
  Future<void> approveSubmission(String id) async {
    // This would typically call a DELETE or a PUT endpoint in backend
    // For now, we simulate success as approval logic is usually backend-side
    // TODO: Implement actual approval endpoint if available
  }

  @override
  Future<void> rejectSubmission(String id) async {
    // TODO: Implement actual rejection endpoint
  }
}
