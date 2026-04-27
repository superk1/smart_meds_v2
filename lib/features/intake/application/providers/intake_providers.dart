import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/features/catalog/application/providers/catalog_providers.dart';
import 'package:smart_meds_v2/features/intake/application/states/intake_state.dart';
import 'package:smart_meds_v2/features/intake/data/fakes/fake_intake_capture_service.dart';
import 'package:smart_meds_v2/features/intake/domain/entities/intake_capture_result.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';

final fakeIntakeCaptureServiceProvider = Provider<FakeIntakeCaptureService>((ref) {
  return FakeIntakeCaptureService();
});

final intakeControllerProvider =
    NotifierProvider<IntakeController, IntakeState>(() {
  return IntakeController();
});

class IntakeController extends Notifier<IntakeState> {
  @override
  IntakeState build() {
    return const IntakeState();
  }

  void reset() {
    state = const IntakeState();
  }

  void dismissError() {
    if (state.draftItem != null) {
      state = state.copyWith(status: IntakeStatus.reviewing, errorMessage: null);
    } else {
      reset();
    }
  }

  Future<void> startSimulatedCapture({
    required IntakeSource source,
    bool forceFallback = false,
  }) async {
    state = state.copyWith(
      status: IntakeStatus.loading,
      errorMessage: null,
    );

    try {
      final captureService = ref.read(fakeIntakeCaptureServiceProvider);
      IntakeCaptureResult result;

      if (source == IntakeSource.barcode) {
        if (forceFallback) {
          result = await captureService.simulateBarcodeNoMatch();
        } else {
          result = await captureService.simulateBarcodeMatch();
        }
      } else {
        result = await captureService.simulateManualSearchMatch('Ibuprofeno');
      }

      await _processCaptureResult(result);
    } catch (e) {
      state = state.copyWith(
        status: IntakeStatus.error,
        errorMessage: 'Error al procesar la entrada.',
      );
    }
  }

  Future<void> _processCaptureResult(IntakeCaptureResult result) async {
    String medicationName = result.fallbackName ?? 'Medicamento Desconocido';
    String catalogId = 'desconocido';

    if (result.hasCatalogMatch) {
      final catalogRepo = ref.read(catalogRepositoryProvider);
      final catalogItem = await catalogRepo.getMedicationById(result.catalogId!);
      
      if (catalogItem != null) {
        medicationName = catalogItem.name;
        catalogId = catalogItem.id;
      }
    }

    final draft = InventoryItem(
      id: 'draft_${Random().nextInt(10000)}',
      catalogMedicationId: catalogId,
      name: medicationName,
      expirationDate: DateTime.now().add(const Duration(days: 180)),
      quantity: 1,
    );

    state = state.copyWith(
      status: IntakeStatus.reviewing,
      draftItem: draft,
      source: result.source,
    );
  }

  Future<void> confirmIntake() async {
    final draftItem = state.draftItem;
    if (draftItem == null) return;

    // Validation
    if (draftItem.quantity < 1) {
      state = state.copyWith(status: IntakeStatus.error, errorMessage: 'La cantidad debe ser al menos 1.');
      return;
    }
    if (draftItem.name.trim().isEmpty) {
      state = state.copyWith(status: IntakeStatus.error, errorMessage: 'El nombre del medicamento no puede estar vacío.');
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiration = DateTime(draftItem.expirationDate.year, draftItem.expirationDate.month, draftItem.expirationDate.day);
    if (expiration.isBefore(today)) {
      state = state.copyWith(status: IntakeStatus.error, errorMessage: 'La fecha de vencimiento no puede ser en el pasado.');
      return;
    }

    state = state.copyWith(
      status: IntakeStatus.loading,
      errorMessage: null,
    );

    try {
      await ref.read(inventoryListProvider.notifier).addItem(draftItem);

      state = state.copyWith(
        status: IntakeStatus.confirmed,
      );
    } catch (e) {
      state = state.copyWith(
        status: IntakeStatus.error,
        errorMessage: 'Error al guardar en el inventario.',
      );
    }
  }

  void updateDraftQuantity(int newQuantity) {
    final currentDraft = state.draftItem;
    if (currentDraft == null || newQuantity < 1) return;

    final updatedDraft = InventoryItem(
      id: currentDraft.id,
      catalogMedicationId: currentDraft.catalogMedicationId,
      name: currentDraft.name,
      expirationDate: currentDraft.expirationDate,
      quantity: newQuantity,
    );

    state = state.copyWith(draftItem: updatedDraft);
  }

  void updateDraftName(String newName) {
    final currentDraft = state.draftItem;
    if (currentDraft == null) return;

    final updatedDraft = InventoryItem(
      id: currentDraft.id,
      catalogMedicationId: currentDraft.catalogMedicationId,
      name: newName,
      expirationDate: currentDraft.expirationDate,
      quantity: currentDraft.quantity,
    );

    state = state.copyWith(draftItem: updatedDraft);
  }

  void updateDraftExpiration(DateTime newDate) {
    final currentDraft = state.draftItem;
    if (currentDraft == null) return;

    final updatedDraft = InventoryItem(
      id: currentDraft.id,
      catalogMedicationId: currentDraft.catalogMedicationId,
      name: currentDraft.name,
      expirationDate: newDate,
      quantity: currentDraft.quantity,
    );

    state = state.copyWith(draftItem: updatedDraft);
  }
}