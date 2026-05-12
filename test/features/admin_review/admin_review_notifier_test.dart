import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_meds_v2/core/errors/app_exception.dart';
import 'package:smart_meds_v2/features/admin_review/application/providers/admin_review_providers.dart';
import 'package:smart_meds_v2/features/admin_review/domain/entities/pending_medication_submission.dart';
import 'package:smart_meds_v2/features/admin_review/domain/repositories/pending_submission_repository.dart';
import 'package:smart_meds_v2/features/auth/application/providers/auth_providers.dart';
import 'package:smart_meds_v2/features/auth/domain/repositories/auth_repository.dart';

class MockPendingSubmissionRepository extends Mock implements PendingSubmissionRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ProviderContainer container;
  late MockPendingSubmissionRepository mockRepo;
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockRepo = MockPendingSubmissionRepository();
    mockAuthRepo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        pendingSubmissionRepositoryProvider.overrideWithValue(mockRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
    );
    // Default stub for auth init
    when(() => mockAuthRepo.loadSession()).thenAnswer((_) async => null);
  });

  tearDown(() {
    container.dispose();
  });

  group('AdminReviewNotifier Tests', () {
    test('build returns list of submissions on success', () async {
      final submissions = [
        PendingMedicationSubmission(
          id: '1',
          proposedName: 'Test Med',
          proposedActiveIngredient: 'Ingredient A',
          userId: 'user_1',
        ),
      ];

      when(() => mockRepo.getPendingSubmissions()).thenAnswer((_) async => submissions);

      final result = await container.read(pendingSubmissionsListProvider.future);
      expect(result.length, 1);
      expect(result[0].proposedName, 'Test Med');
    });

    test('build handles AuthException and triggers logout', () async {
      when(() => mockRepo.getPendingSubmissions()).thenThrow(const AuthException());
      when(() => mockAuthRepo.clearSession()).thenAnswer((_) async {});

      // Let the provider attempt to build
      final asyncState = container.read(pendingSubmissionsListProvider);

      // Wait for the future to settle
      await asyncState.whenOrNull(
        data: (_) {},
        error: (e, st) {},
      );

      // Give time for the async build to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final finalState = container.read(pendingSubmissionsListProvider);
      expect(finalState.hasError, true);
      expect(finalState.error, isA<AuthException>());
      
      // Verify logout was triggered
      verify(() => mockAuthRepo.clearSession()).called(1);
    });

    test('approve handles AuthException with session-expired error', () async {
      // First load succeeds
      when(() => mockRepo.getPendingSubmissions()).thenAnswer((_) async => []);
      await container.read(pendingSubmissionsListProvider.future);

      // Approve throws AuthException
      when(() => mockRepo.approveSubmission('1')).thenThrow(const AuthException());
      when(() => mockAuthRepo.clearSession()).thenAnswer((_) async {});

      final notifier = container.read(pendingSubmissionsListProvider.notifier);
      await notifier.approve('1');

      final asyncState = container.read(pendingSubmissionsListProvider);
      expect(asyncState.hasError, true);
      expect(asyncState.error, isA<AuthException>());

      // Verify logout was triggered
      verify(() => mockAuthRepo.clearSession()).called(1);
    });
  });
}
