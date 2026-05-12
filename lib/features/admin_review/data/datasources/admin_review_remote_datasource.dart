import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_meds_v2/core/config/app_config.dart';
import 'package:smart_meds_v2/core/errors/app_exception.dart';
import 'package:smart_meds_v2/features/admin_review/data/models/pending_medication_submission_model.dart';

class AdminReviewRemoteDataSource {
  final http.Client _client;
  final String? _token;

  AdminReviewRemoteDataSource({http.Client? client, String? token})
      : _client = client ?? http.Client(),
        _token = token;

  Map<String, String> get _headers {
    if (_token == null) {
      throw const AuthException('Usuario no autenticado para esta operación.');
    }
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> submitForReview(PendingMedicationSubmissionModel submission) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/moderation/submissions');

    try {
      final response = await _client.post(
        url,
        body: jsonEncode(submission.toMap()),
        headers: _headers,
      ).timeout(const Duration(seconds: AppConfig.networkTimeoutSeconds));

      _handleResponse(response, (_) => null);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al enviar propuesta.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error inesperado al enviar propuesta: $e');
    }
  }

  Future<List<PendingMedicationSubmissionModel>> getPendingSubmissions() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/moderation/submissions');

    try {
      final response = await _client.get(
        url,
        headers: _headers,
      ).timeout(
        const Duration(seconds: AppConfig.networkTimeoutSeconds),
      );

      return _handleResponse<List<PendingMedicationSubmissionModel>>(
        response,
        (body) {
          final List<dynamic> data = jsonDecode(body);
          return data.map((m) => PendingMedicationSubmissionModel.fromMap(m as Map<String, dynamic>)).toList();
        },
      );
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al cargar revisiones.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error al obtener revisiones: $e');
    }
  }

  T _handleResponse<T>(http.Response response, T Function(String body) mapper) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return mapper(response.body);
      } catch (e) {
        throw const DataParsingException();
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException('Sesión expirada o no autorizada.', 'AUTH_ERROR');
    }

    if (response.statusCode >= 400 && response.statusCode < 500) {
      throw ClientException(
        'Petición rechazada (${response.statusCode})',
        'MODERATION_CLIENT_ERROR',
      );
    }

    throw ServerException(
      'Error del servidor de moderación (${response.statusCode})',
      'MODERATION_SERVER_ERROR',
    );
  }
}
