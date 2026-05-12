import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_meds_v2/core/config/app_config.dart';
import 'package:smart_meds_v2/core/errors/app_exception.dart';
import 'package:smart_meds_v2/features/auth/domain/entities/auth_session.dart';

class AuthRemoteDataSource {
  final http.Client _client;

  AuthRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<AuthSession> login(String email, String password) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/login');
    
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: AppConfig.networkTimeoutSeconds));

      return _handleResponse<AuthSession>(
        response,
        (body) => AuthSession.fromMap(jsonDecode(body)),
      );
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al iniciar sesión.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error inesperado en Auth: $e');
    }
  }

  Future<AuthSession> register(String email, String password) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/register');
    
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: AppConfig.networkTimeoutSeconds));

      return _handleResponse<AuthSession>(
        response,
        (body) => AuthSession.fromMap(jsonDecode(body)),
      );
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al registrarse.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error inesperado en Auth: $e');
    }
  }

  T _handleResponse<T>(http.Response response, T Function(String body) mapper) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return mapper(response.body);
      } catch (e) {
        throw const DataParsingException();
      }
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      throw const ClientException('Credenciales inválidas o petición rechazada', 'AUTH_CLIENT_ERROR');
    } else {
      throw const ServerException('Error del servidor de autenticación', 'AUTH_SERVER_ERROR');
    }
  }
}
