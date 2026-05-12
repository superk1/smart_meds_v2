import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_meds_v2/core/services/secure_storage_service.dart';
import 'package:smart_meds_v2/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smart_meds_v2/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:smart_meds_v2/features/auth/domain/entities/auth_session.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemote;
  late MockSecureStorageService mockSecureStorage;

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockSecureStorage = MockSecureStorageService();
    repository = AuthRepositoryImpl(mockRemote, mockSecureStorage);
  });

  group('AuthRepositoryImpl Tests', () {
    final session = AuthSession(
      userId: '123',
      email: 'test@test.com',
      token: 'abc'
    );

    test('login calls remote and persists session', () async {
      when(() => mockRemote.login(any(), any())).thenAnswer((_) async => session);
      when(() => mockSecureStorage.write(any(), any())).thenAnswer((_) async {});

      final result = await repository.login('test@test.com', 'pass');

      expect(result, session);
      verify(() => mockRemote.login('test@test.com', 'pass')).called(1);
      verify(() => mockSecureStorage.write('auth_session', any())).called(1);
    });

    test('loadSession returns session if stored', () async {
      const storedJson = '{"userId":"123","email":"test@test.com","token":"abc"}';
      when(() => mockSecureStorage.read('auth_session')).thenAnswer((_) async => storedJson);

      final result = await repository.loadSession();

      expect(result?.userId, '123');
      expect(result?.token, 'abc');
    });

    test('clearSession deletes from secure storage', () async {
      when(() => mockSecureStorage.delete('auth_session')).thenAnswer((_) async {});

      await repository.clearSession();

      verify(() => mockSecureStorage.delete('auth_session')).called(1);
    });
  });
}
