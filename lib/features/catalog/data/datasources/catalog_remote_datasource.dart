import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_meds_v2/core/config/app_config.dart';
import 'package:smart_meds_v2/core/errors/app_exception.dart';
import 'package:smart_meds_v2/features/catalog/data/models/catalog_medication_model.dart';

class CatalogRemoteDataSource {
  final http.Client _client;

  CatalogRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<List<CatalogMedicationModel>> getMedications({String? query}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/catalog').replace(
      queryParameters: query != null && query.isNotEmpty ? {'q': query} : null,
    );

    try {
      final response = await _client.get(url).timeout(
        const Duration(seconds: AppConfig.networkTimeoutSeconds),
      );

      return _handleResponse<List<CatalogMedicationModel>>(
        response,
        (body) {
          final List<dynamic> data = jsonDecode(body);
          return data.map((m) => CatalogMedicationModel.fromMap(m as Map<String, dynamic>)).toList();
        },
      );
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado. Reintenta.');
    } on FormatException {
      throw const DataParsingException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error inesperado: $e');
    }
  }

  Future<CatalogMedicationModel> getMedicationById(String id) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/catalog/$id');

    try {
      final response = await _client.get(url).timeout(
        const Duration(seconds: AppConfig.networkTimeoutSeconds),
      );

      return _handleResponse<CatalogMedicationModel>(
        response,
        (body) => CatalogMedicationModel.fromMap(jsonDecode(body)),
      );
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error al buscar medicamento: $e');
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
      if (response.statusCode == 404) {
        throw const ClientException('Medicamento no encontrado', 'NOT_FOUND');
      }
      throw ClientException('Petición inválida (${response.statusCode})', 'CLIENT_ERROR');
    } else {
      throw ServerException('Error del servidor (${response.statusCode})', 'SERVER_ERROR');
    }
  }
}
