import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/core/errors/app_exception.dart';
import 'package:smart_meds_v2/features/admin_review/application/use_cases/approve_submission_use_case.dart';
import 'package:smart_meds_v2/features/admin_review/application/use_cases/get_pending_submissions_use_case.dart';
import 'package:smart_meds_v2/features/admin_review/application/use_cases/reject_submission_use_case.dart';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/admin_review/data/datasources/admin_review_remote_datasource.dart';
import 'package:smart_meds_v2/features/admin_review/data/repositories/remote_pending_submission_repository.dart';
import 'package:smart_meds_v2/features/admin_review/data/fakes/fake_pending_submission_repository.dart';
import 'package:smart_meds_v2/features/admin_review/domain/entities/pending_medication_submission.dart';
import 'package:smart_meds_v2/features/admin_review/domain/repositories/pending_submission_repository.dart';
import 'package:smart_meds_v2/features/auth/application/providers/auth_providers.dart';

final adminReviewRemoteDataSourceProvider = Provider<AdminReviewRemoteDataSource>((ref) {
  final authState = ref.watch(authControllerProvider);
  final token = authState.session?.token;
  
  return AdminReviewRemoteDataSource(token: token);
});

final pendingSubmissionRepositoryProvider = Provider<PendingSubmissionRepository>((ref) {
  const useFake = bool.fromEnvironment('USE_FAKE_ADMIN', defaultValue: false);
  
  if (useFake) {
    return FakePendingSubmissionRepository(ref.watch(localStorageServiceProvider));
  }
  
  return RemotePendingSubmissionRepository(ref.watch(adminReviewRemoteDataSourceProvider));
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
    try {
      return await ref.watch(getPendingSubmissionsUseCaseProvider).execute();
    } on AuthException {
      // Defer logout to avoid modifying providers during build
      Future.microtask(() => ref.read(authControllerProvider.notifier).logout());
      throw const AuthException('Tu sesión expiró. Inicia sesión para continuar con la revisión.');
    }
  }

  Future<void> approve(String id) async {
    state = const AsyncLoading();
    try {
      await ref.read(approveSubmissionUseCaseProvider).execute(id);
      final list = await ref.read(getPendingSubmissionsUseCaseProvider).execute();
      state = AsyncData(list);
    } on AuthException {
      ref.read(authControllerProvider.notifier).logout();
      state = AsyncError(
        const AuthException('Tu sesión expiró. Inicia sesión para continuar con la revisión.'),
        StackTrace.current,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reject(String id) async {
    state = const AsyncLoading();
    try {
      await ref.read(rejectSubmissionUseCaseProvider).execute(id);
      final list = await ref.read(getPendingSubmissionsUseCaseProvider).execute();
      state = AsyncData(list);
    } on AuthException {
      ref.read(authControllerProvider.notifier).logout();
      state = AsyncError(
        const AuthException('Tu sesión expiró. Inicia sesión para continuar con la revisión.'),
        StackTrace.current,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final pendingSubmissionsListProvider = AsyncNotifierProvider<AdminReviewNotifier, List<PendingMedicationSubmission>>(() {
  return AdminReviewNotifier();
});
