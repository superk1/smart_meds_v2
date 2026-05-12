import 'package:smart_meds_v2/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login(String email, String password);
  Future<AuthSession> register(String email, String password);
  Future<void> persistSession(AuthSession session);
  Future<AuthSession?> loadSession();
  Future<void> clearSession();
}
