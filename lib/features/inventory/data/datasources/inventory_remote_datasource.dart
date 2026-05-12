import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_meds_v2/core/config/app_config.dart';
import 'package:smart_meds_v2/core/errors/app_exception.dart';
import 'package:smart_meds_v2/features/inventory/data/models/inventory_item_model.dart';

class InventoryRemoteDataSource {
  final http.Client _client;
  final String? _token;

  InventoryRemoteDataSource({http.Client? client, String? token})
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

  Future<Map<String, dynamic>> fetchInventorySnapshot() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/inventory');

    try {
      final response = await _client.get(
        url,
        headers: _headers,
      ).timeout(const Duration(seconds: AppConfig.networkTimeoutSeconds));

      return _handleResponse<Map<String, dynamic>>(
        response,
        (body) {
          final Map<String, dynamic> data = jsonDecode(body);
          final List<dynamic> itemsData = data['items'] ?? [];
          final items = itemsData.map((m) => InventoryItemModel.fromMap(m as Map<String, dynamic>)).toList();
          
          return {
            'items': items,
            'version': data['version'] ?? 0,
            'updatedAt': data['updatedAt'] ?? DateTime.now().toIso8601String(),
            'updatedByDeviceId': data['updatedByDeviceId'] ?? 'unknown',
          };
        },
      );
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al descargar inventario.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error inesperado al descargar inventario: $e');
    }
  }

  Future<void> pushInventory(List<InventoryItemModel> items, {int? baseVersion, bool force = false}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/inventory');

    try {
      final Map<String, dynamic> body = {
        'items': items.map((e) => e.toMap()).toList(),
      };
      if (baseVersion != null) body['baseVersion'] = baseVersion;
      if (force) body['force'] = true;

      final response = await _client.put(
        url,
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: AppConfig.networkTimeoutSeconds));

      _handleResponse(response, (_) => null);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al subir inventario.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error inesperado al subir inventario: $e');
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

    if (response.statusCode == 409) {
      throw const InventoryConflictException();
    }

    if (response.statusCode >= 400 && response.statusCode < 500) {
      throw ClientException(
        'Error de cliente en inventario (${response.statusCode})',
        'INVENTORY_CLIENT_ERROR',
      );
    }

    throw ServerException(
      'Error del servidor en inventario (${response.statusCode})',
      'INVENTORY_SERVER_ERROR',
    );
  }
}
