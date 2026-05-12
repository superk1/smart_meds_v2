import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/inventory/data/repositories/local_reminder_repository_impl.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  late MockLocalStorageService mockStorage;
  late LocalReminderRepositoryImpl repository;

  setUp(() {
    mockStorage = MockLocalStorageService();
    repository = LocalReminderRepositoryImpl(mockStorage);
  });

  group('LocalReminderRepositoryImpl Tests', () {
    test('getAll returns empty list when no data', () async {
      when(() => mockStorage.readString(any())).thenReturn(null);
      
      final result = await repository.getAll();
      
      expect(result, isEmpty);
    });

    test('save adds a reminder and persists it', () async {
      when(() => mockStorage.readString(any())).thenReturn(null);
      when(() => mockStorage.writeString(any(), any())).thenAnswer((_) async => {});

      final reminder = InventoryReminder(
        id: '1',
        inventoryItemId: 'item1',
        type: ReminderType.stock,
        createdAt: DateTime.now(),
        targetQuantity: 2,
      );

      await repository.save(reminder);

      verify(() => mockStorage.writeString(any(), any(that: contains('"id":"1"')))).called(1);
    });

    test('delete removes a reminder', () async {
      final reminder = InventoryReminder(
        id: '1',
        inventoryItemId: 'item1',
        type: ReminderType.stock,
        createdAt: DateTime.now(),
        targetQuantity: 2,
      );
      
      final jsonList = '[${jsonEncode(reminder.toJson())}]';
      when(() => mockStorage.readString(any())).thenReturn(jsonList);
      when(() => mockStorage.writeString(any(), any())).thenAnswer((_) async => {});

      await repository.delete('1');

      verify(() => mockStorage.writeString(any(), '[]')).called(1);
    });
  });
}
