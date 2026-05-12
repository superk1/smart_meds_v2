import 'dart:convert';
import 'package:smart_meds_v2/core/services/secure_storage_service.dart';
import 'package:smart_meds_v2/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smart_meds_v2/features/auth/domain/entities/auth_session.dart';
import 'package:smart_meds_v2/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final SecureStorageService _secureStorage;

  static const _sessionKey = 'auth_session';

  AuthRepositoryImpl(this._remote, this._secureStorage);

  @override
  Future<AuthSession> login(String email, String password) async {
    final session = await _remote.login(email, password);
    await persistSession(session);
    return session;
  }

  @override
  Future<AuthSession> register(String email, String password) async {
    final session = await _remote.register(email, password);
    await persistSession(session);
    return session;
  }

  @override
  Future<void> persistSession(AuthSession session) async {
    final String encoded = jsonEncode(session.toMap());
    await _secureStorage.write(_sessionKey, encoded);
  }

  @override
  Future<AuthSession?> loadSession() async {
    final String? stored = await _secureStorage.read(_sessionKey);
    if (stored == null) return null;
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(stored);
      return AuthSession.fromMap(decoded);
    } catch (e) {
      // If corrupted, clear it
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    await _secureStorage.delete(_sessionKey);
  }
}
