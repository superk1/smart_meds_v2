abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Sin conexión a internet'])
      : super(code: 'NETWORK_ERROR');
}

class ServerException extends AppException {
  const ServerException([super.message = 'Error en el servidor', String? code])
      : super(code: code ?? 'SERVER_ERROR');
}

class ClientException extends AppException {
  const ClientException([super.message = 'Petición inválida', String? code])
      : super(code: code ?? 'CLIENT_ERROR');
}

class DataParsingException extends AppException {
  const DataParsingException([super.message = 'Error al procesar los datos'])
      : super(code: 'PARSING_ERROR');
}

class AuthException extends AppException {
  const AuthException([super.message = 'Sesión expirada o no autorizada.', String? code])
      : super(code: code ?? 'AUTH_ERROR');
}

class InventoryConflictException extends AppException {
  const InventoryConflictException([super.message = 'Conflicto de sincronización: el inventario en la nube ha cambiado.'])
      : super(code: 'SYNC_CONFLICT');
}
