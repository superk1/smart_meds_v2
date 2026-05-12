import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/core/services/secure_storage_service.dart';
import 'package:smart_meds_v2/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smart_meds_v2/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:smart_meds_v2/features/auth/domain/entities/auth_session.dart';
import 'package:smart_meds_v2/features/auth/domain/repositories/auth_repository.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return InsecureSecureStorageService(ref.watch(localStorageServiceProvider));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

class AuthState {
  final bool isAuthenticated;
  final AuthSession? session;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.session,
    this.isLoading = false,
    this.errorMessage,
  });

  static const _unset = Object();

  AuthState copyWith({
    bool? isAuthenticated,
    Object? session = _unset,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      session: identical(session, _unset) ? this.session : session as AuthSession?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Attempt to load session at startup.
    Future.microtask(() => _init());
    return const AuthState(isLoading: true);
  }

  Future<void> _init() async {
    final repo = ref.read(authRepositoryProvider);
    final session = await repo.loadSession();

    try {
      if (session != null) {
        state = AuthState(
          isAuthenticated: true,
          session: session,
          isLoading: false,
        );
      } else {
        state = const AuthState(isAuthenticated: false, isLoading: false);
      }
    } catch (_) {
      // Notifier was disposed before async init completed; safe to ignore.
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.login(email, password);
      state = state.copyWith(
        isAuthenticated: true,
        session: session,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.register(email, password);
      state = state.copyWith(
        isAuthenticated: true,
        session: session,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await ref.read(authRepositoryProvider).clearSession();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});
