import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_meds_v2/core/errors/app_exception.dart';
import 'package:smart_meds_v2/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smart_meds_v2/features/auth/domain/entities/auth_session.dart';

void main() {
  group('AuthRemoteDataSource Tests', () {
    test('login returns AuthSession on 200', () async {
      final mockClient = MockClient((request) async {
        final response = {
          'userId': 'user_123',
          'email': 'test@example.com',
          'token': 'valid_token'
        };
        return http.Response(jsonEncode(response), 200);
      });

      final dataSource = AuthRemoteDataSource(client: mockClient);
      final result = await dataSource.login('test@example.com', 'password');

      expect(result, isA<AuthSession>());
      expect(result.userId, 'user_123');
      expect(result.token, 'valid_token');
    });

    test('login throws ClientException on 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final dataSource = AuthRemoteDataSource(client: mockClient);
      expect(
        () => dataSource.login('test@example.com', 'wrong_password'),
        throwsA(isA<ClientException>()),
      );
    });

    test('register returns AuthSession on 201', () async {
      final mockClient = MockClient((request) async {
        final response = {
          'userId': 'user_new',
          'email': 'new@example.com',
          'token': 'new_token'
        };
        return http.Response(jsonEncode(response), 201);
      });

      final dataSource = AuthRemoteDataSource(client: mockClient);
      final result = await dataSource.register('new@example.com', 'password');

      expect(result.userId, 'user_new');
    });
  });
}
