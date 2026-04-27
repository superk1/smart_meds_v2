import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/features/intake/application/providers/intake_providers.dart';
import 'package:smart_meds_v2/features/intake/application/states/intake_state.dart';
import 'package:smart_meds_v2/features/intake/domain/entities/intake_capture_result.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorageService()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('IntakeController Tests', () {
    test('initial state is idle', () {
      final state = container.read(intakeControllerProvider);
      expect(state.status, IntakeStatus.idle);
      expect(state.draftItem, isNull);
    });

    test('startSimulatedCapture (match) sets state to reviewing and populates draft', () async {
      final controller = container.read(intakeControllerProvider.notifier);
      
      await controller.startSimulatedCapture(source: IntakeSource.barcode);
      
      final state = container.read(intakeControllerProvider);
      expect(state.status, IntakeStatus.reviewing);
      expect(state.draftItem, isNotNull);
      expect(state.draftItem!.catalogMedicationId, isNot('desconocido'));
    });

    test('startSimulatedCapture (no match) sets state to reviewing with fallback name', () async {
      final controller = container.read(intakeControllerProvider.notifier);
      
      await controller.startSimulatedCapture(
        source: IntakeSource.barcode,
        forceFallback: true,
      );
      
      final state = container.read(intakeControllerProvider);
      expect(state.status, IntakeStatus.reviewing);
      expect(state.draftItem!.catalogMedicationId, 'desconocido');
      expect(state.draftItem!.name, 'Medicamento Desconocido');
    });

    test('confirmIntake fails if quantity is less than 1', () async {
      final controller = container.read(intakeControllerProvider.notifier);
      
      await controller.startSimulatedCapture(source: IntakeSource.barcode);
      controller.updateDraftQuantity(0);
      
      await controller.confirmIntake();
      
      final state = container.read(intakeControllerProvider);
      expect(state.status, IntakeStatus.error);
      expect(state.fieldErrors?['quantity'], isNotNull);
    });

    test('confirmIntake fails if name is empty', () async {
      final controller = container.read(intakeControllerProvider.notifier);
      
      await controller.startSimulatedCapture(
        source: IntakeSource.barcode,
        forceFallback: true,
      );
      controller.updateDraftName('');
      
      await controller.confirmIntake();
      
      final state = container.read(intakeControllerProvider);
      expect(state.status, IntakeStatus.error);
      expect(state.fieldErrors?['name'], isNotNull);
    });

    test('confirmIntake fails if expiration date is in the past', () async {
      final controller = container.read(intakeControllerProvider.notifier);
      
      await controller.startSimulatedCapture(source: IntakeSource.barcode);
      // Set date to yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      controller.updateDraftExpiration(yesterday);
      
      await controller.confirmIntake();
      
      final state = container.read(intakeControllerProvider);
      expect(state.status, IntakeStatus.error);
      expect(state.fieldErrors?['expirationDate'], isNotNull);
    });

    test('confirmIntake adds item to inventory and sets status to confirmed', () async {
      final controller = container.read(intakeControllerProvider.notifier);
      
      await controller.startSimulatedCapture(source: IntakeSource.barcode);
      final draftItem = container.read(intakeControllerProvider).draftItem!;
      
      await controller.confirmIntake();
      
      final state = container.read(intakeControllerProvider);
      expect(state.status, IntakeStatus.confirmed);
      
      // Verify it was added to inventory
      final inventory = await container.read(inventoryListProvider.future);
      expect(inventory.any((item) => item.name == draftItem.name), isTrue);
    });

    test('reset clears the state', () async {
      final controller = container.read(intakeControllerProvider.notifier);
      
      await controller.startSimulatedCapture(source: IntakeSource.barcode);
      controller.reset();
      
      final state = container.read(intakeControllerProvider);
      expect(state.status, IntakeStatus.idle);
      expect(state.draftItem, isNull);
    });
  });
}
