import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_meds_v2/features/catalog/data/datasources/catalog_remote_datasource.dart';
import 'package:smart_meds_v2/features/catalog/data/models/catalog_medication_model.dart';

import 'package:smart_meds_v2/core/errors/app_exception.dart';

void main() {
  group('CatalogRemoteDataSource Tests', () {
    test('getMedications returns list of models on 200', () async {
      final mockClient = MockClient((request) async {
        final response = [
          {'id': '1', 'name': 'Med 1', 'activeIngredient': 'Act 1'},
          {'id': '2', 'name': 'Med 2', 'activeIngredient': 'Act 2'},
        ];
        return http.Response(jsonEncode(response), 200);
      });

      final dataSource = CatalogRemoteDataSource(client: mockClient);
      final result = await dataSource.getMedications();

      expect(result, isA<List<CatalogMedicationModel>>());
      expect(result.length, 2);
      expect(result[0].name, 'Med 1');
    });

    test('getMedications throws ClientException on 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final dataSource = CatalogRemoteDataSource(client: mockClient);

      expect(() => dataSource.getMedications(), throwsA(isA<ClientException>()));
    });

    test('getMedications throws ServerException on 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final dataSource = CatalogRemoteDataSource(client: mockClient);

      expect(() => dataSource.getMedications(), throwsA(isA<ServerException>()));
    });

    test('getMedicationById returns model on 200', () async {
      final mockClient = MockClient((request) async {
        final response = {'id': '1', 'name': 'Med 1', 'activeIngredient': 'Act 1'};
        return http.Response(jsonEncode(response), 200);
      });

      final dataSource = CatalogRemoteDataSource(client: mockClient);
      final result = await dataSource.getMedicationById('1');

      expect(result.id, '1');
      expect(result.name, 'Med 1');
    });
  });
}
