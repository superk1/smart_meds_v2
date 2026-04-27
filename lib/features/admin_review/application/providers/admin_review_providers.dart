import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/features/admin_review/application/use_cases/approve_submission_use_case.dart';
import 'package:smart_meds_v2/features/admin_review/application/use_cases/get_pending_submissions_use_case.dart';
import 'package:smart_meds_v2/features/admin_review/application/use_cases/reject_submission_use_case.dart';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/admin_review/data/fakes/fake_pending_submission_repository.dart';
import 'package:smart_meds_v2/features/admin_review/domain/entities/pending_medication_submission.dart';
import 'package:smart_meds_v2/features/admin_review/domain/repositories/pending_submission_repository.dart';

final pendingSubmissionRepositoryProvider = Provider<PendingSubmissionRepository>((ref) {
  return FakePendingSubmissionRepository(ref.watch(localStorageServiceProvider));
});

final getPendingSubmissionsUseCaseProvider = Provider<GetPendingSubmissionsUseCase>((ref) {
  return GetPendingSubmissionsUseCase(ref.watch(pendingSubmissionRepositoryProvider));
});

final approveSubmissionUseCaseProvider = Provider<ApproveSubmissionUseCase>((ref) {
  return ApproveSubmissionUseCase(ref.watch(pendingSubmissionRepositoryProvider));
});

final rejectSubmissionUseCaseProvider = Provider<RejectSubmissionUseCase>((ref) {
  return RejectSubmissionUseCase(ref.watch(pendingSubmissionRepositoryProvider));
});

class AdminReviewNotifier extends AsyncNotifier<List<PendingMedicationSubmission>> {
  @override
  Future<List<PendingMedicationSubmission>> build() async {
    return ref.watch(getPendingSubmissionsUseCaseProvider).execute();
  }

  Future<void> approve(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(approveSubmissionUseCaseProvider).execute(id);
      return ref.read(getPendingSubmissionsUseCaseProvider).execute();
    });
  }

  Future<void> reject(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(rejectSubmissionUseCaseProvider).execute(id);
      return ref.read(getPendingSubmissionsUseCaseProvider).execute();
    });
  }
}

final pendingSubmissionsListProvider = AsyncNotifierProvider<AdminReviewNotifier, List<PendingMedicationSubmission>>(() {
  return AdminReviewNotifier();
});
