import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_meds_v2/core/errors/app_exception.dart';
import 'package:smart_meds_v2/features/admin_review/data/datasources/admin_review_remote_datasource.dart';
import 'package:smart_meds_v2/features/admin_review/data/models/pending_medication_submission_model.dart';

void main() {
  group('AdminReviewRemoteDataSource Tests', () {
    test('getPendingSubmissions returns list of models on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test_token');
        final response = [
          {
            'id': '1',
            'proposedName': 'Med 1',
            'proposedActiveIngredient': 'Ing 1',
            'userId': 'user_1'
          },
        ];
        return http.Response(jsonEncode(response), 200);
      });

      final dataSource = AdminReviewRemoteDataSource(client: mockClient, token: 'test_token');
      final result = await dataSource.getPendingSubmissions();

      expect(result.length, 1);
      expect(result[0].proposedName, 'Med 1');
    });

    test('getPendingSubmissions throws AuthException on 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final dataSource = AdminReviewRemoteDataSource(client: mockClient, token: 'token');
      expect(() => dataSource.getPendingSubmissions(), throwsA(isA<AuthException>()));
    });

    test('getPendingSubmissions throws AuthException on 403', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      final dataSource = AdminReviewRemoteDataSource(client: mockClient, token: 'token');
      expect(() => dataSource.getPendingSubmissions(), throwsA(isA<AuthException>()));
    });

    test('submitForReview throws AuthException when token is null', () async {
      final dataSource = AdminReviewRemoteDataSource(token: null);
      final model = PendingMedicationSubmissionModel(
        id: '1',
        proposedName: 'Test',
        proposedActiveIngredient: 'Test',
        userId: '1',
      );
      
      expect(() => dataSource.submitForReview(model), throwsA(isA<AuthException>()));
    });
  });
}
