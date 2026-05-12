import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_meds_v2/core/errors/app_exception.dart';
import 'package:smart_meds_v2/features/inventory/data/datasources/inventory_remote_datasource.dart';

void main() {
  group('InventoryRemoteDataSource Tests', () {
    test('fetchInventorySnapshot returns data map with items and version on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test_token');
        final response = {
          'items': [
            {
              'id': '1',
              'catalogMedicationId': 'cat_1',
              'name': 'Med 1',
              'expirationDate': '2025-01-01T00:00:00.000',
              'quantity': 5
            },
          ],
          'version': 10,
          'updatedAt': '2025-01-01T10:00:00.000Z',
          'updatedByDeviceId': 'dev_1'
        };
        return http.Response(jsonEncode(response), 200);
      });

      final dataSource = InventoryRemoteDataSource(client: mockClient, token: 'test_token');
      final result = await dataSource.fetchInventorySnapshot();

      expect(result['items'].length, 1);
      expect(result['version'], 10);
      expect(result['updatedByDeviceId'], 'dev_1');
    });

    test('fetchInventorySnapshot throws AuthException when token is null', () async {
      final dataSource = InventoryRemoteDataSource(token: null);
      expect(() => dataSource.fetchInventorySnapshot(), throwsA(isA<AuthException>()));
    });

    test('fetchInventorySnapshot throws AuthException on 401/403', () async {
      final client401 = MockClient((_) async => http.Response('Unauthorized', 401));
      final dataSource401 = InventoryRemoteDataSource(client: client401, token: 'token');
      expect(() => dataSource401.fetchInventorySnapshot(), throwsA(isA<AuthException>()));

      final client403 = MockClient((_) async => http.Response('Forbidden', 403));
      final dataSource403 = InventoryRemoteDataSource(client: client403, token: 'token');
      expect(() => dataSource403.fetchInventorySnapshot(), throwsA(isA<AuthException>()));
    });

    test('pushInventory sends baseVersion correctly', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['baseVersion'], 5);
        expect(body['force'], isNull);
        return http.Response('', 204);
      });

      final dataSource = InventoryRemoteDataSource(client: mockClient, token: 'test_token');
      await dataSource.pushInventory([], baseVersion: 5);
    });

    test('pushInventory sends force flag correctly', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['force'], true);
        return http.Response('', 204);
      });

      final dataSource = InventoryRemoteDataSource(client: mockClient, token: 'test_token');
      await dataSource.pushInventory([], force: true);
    });

    test('pushInventory throws InventoryConflictException on 409', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Conflict', 409);
      });

      final dataSource = InventoryRemoteDataSource(client: mockClient, token: 'token');
      expect(() => dataSource.pushInventory([], baseVersion: 5), throwsA(isA<InventoryConflictException>()));
    });

    test('pushInventory throws AuthException on 401/403', () async {
      final client401 = MockClient((_) async => http.Response('Unauthorized', 401));
      final dataSource401 = InventoryRemoteDataSource(client: client401, token: 'token');
      expect(() => dataSource401.pushInventory([]), throwsA(isA<AuthException>()));

      final client403 = MockClient((_) async => http.Response('Forbidden', 403));
      final dataSource403 = InventoryRemoteDataSource(client: client403, token: 'token');
      expect(() => dataSource403.pushInventory([]), throwsA(isA<AuthException>()));
    });

    test('pushInventory handles server errors (500)', () async {
      final mockClient = MockClient((_) async => http.Response('Internal Server Error', 500));
      final dataSource = InventoryRemoteDataSource(client: mockClient, token: 'token');
      expect(() => dataSource.pushInventory([]), throwsA(isA<ServerException>()));
    });
  });
}
