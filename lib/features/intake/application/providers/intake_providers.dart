import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/features/catalog/application/providers/catalog_providers.dart';
import 'package:smart_meds_v2/features/intake/application/states/intake_state.dart';
import 'package:smart_meds_v2/features/intake/data/fakes/fake_intake_capture_service.dart';
import 'package:smart_meds_v2/features/intake/domain/entities/intake_capture_result.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/catalog/domain/constants/catalog_constants.dart';
import 'package:smart_meds_v2/features/intake/domain/services/intake_capture_service.dart';
import 'package:smart_meds_v2/features/admin_review/application/providers/admin_review_providers.dart';
import 'package:smart_meds_v2/features/admin_review/domain/entities/pending_medication_submission.dart';

final fakeIntakeCaptureServiceProvider = Provider<FakeIntakeCaptureService>((ref) {
  return FakeIntakeCaptureService();
});

final barcodeCaptureServiceProvider = Provider<BarcodeCaptureService>((ref) {
  return ref.watch(fakeIntakeCaptureServiceProvider);
});

final imageOcrCaptureServiceProvider = Provider<ImageOcrCaptureService>((ref) {
  return ref.watch(fakeIntakeCaptureServiceProvider);
});

final manualSearchServiceProvider = Provider<ManualSearchService>((ref) {
  return ref.watch(fakeIntakeCaptureServiceProvider);
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
      state = state.copyWith(status: IntakeStatus.reviewing, errorMessage: null, fieldErrors: null);
    } else {
      reset();
    }
  }

  void clearFieldError(String field) {
    if (state.fieldErrors != null && state.fieldErrors!.containsKey(field)) {
      final newErrors = Map<String, String>.from(state.fieldErrors!);
      newErrors.remove(field);
      state = state.copyWith(fieldErrors: newErrors.isEmpty ? null : newErrors);
    }
  }

  Future<void> startSimulatedCapture({
    required IntakeSource source,
    bool forceFallback = false,
  }) async {
    state = state.copyWith(
      status: IntakeStatus.loading,
      errorMessage: null,
      fieldErrors: null,
    );

    try {
      IntakeCaptureResult result;

      if (source == IntakeSource.barcode) {
        final barcodeService = ref.read(barcodeCaptureServiceProvider);
        // Para simular el fallo, necesitamos acceder al fake si es necesario, 
        // pero el requerimiento dice "depender de abstracciones".
        // Como estamos en fase fake, el provider ya nos da el FakeIntakeCaptureService.
        if (forceFallback && barcodeService is FakeIntakeCaptureService) {
          barcodeService.setForceNoMatch(true);
        }
        result = await barcodeService.scanBarcode();
        if (forceFallback && barcodeService is FakeIntakeCaptureService) {
          barcodeService.setForceNoMatch(false);
        }
      } else {
        final manualService = ref.read(manualSearchServiceProvider);
        result = await manualService.searchByText('Ibuprofeno');
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
    String medicationName = result.fallbackName ?? CatalogConstants.unknownName;
    String catalogId = CatalogConstants.unknownId;

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

    final errors = <String, String>{};

    // Validation
    if (draftItem.quantity < 1) {
      errors['quantity'] = 'La cantidad debe ser al menos 1.';
    }
    if (draftItem.name.trim().isEmpty) {
      errors['name'] = 'El nombre no puede estar vacío.';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiration = DateTime(draftItem.expirationDate.year, draftItem.expirationDate.month, draftItem.expirationDate.day);
    
    if (expiration.isBefore(today)) {
      errors['expirationDate'] = 'La fecha no puede ser en el pasado.';
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(
        status: IntakeStatus.error,
        fieldErrors: errors,
        errorMessage: 'Por favor, corrige los errores antes de continuar.',
      );
      return;
    }

    state = state.copyWith(
      status: IntakeStatus.loading,
      errorMessage: null,
      fieldErrors: null,
    );

    try {
      // 1. Add to local inventory (always)
      await ref.read(inventoryListProvider.notifier).addItem(draftItem);

      // 2. If it's an unknown medication, submit for moderation
      if (draftItem.catalogMedicationId == CatalogConstants.unknownId) {
        final submission = PendingMedicationSubmission(
          id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
          proposedName: draftItem.name,
          proposedActiveIngredient: 'Desconocido', // Or capture this from UI if available
          userId: 'user_local', // Placeholder until Auth is implemented
        );
        
        await ref.read(pendingSubmissionRepositoryProvider).submitForReview(submission);
      }

      state = state.copyWith(
        status: IntakeStatus.confirmed,
      );
    } catch (e) {
      state = state.copyWith(
        status: IntakeStatus.error,
        errorMessage: 'Error al procesar el ingreso: $e',
      );
    }
  }

  void updateDraftQuantity(int newQuantity) {
    final currentDraft = state.draftItem;
    if (currentDraft == null) return;
    
    clearFieldError('quantity');

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

    clearFieldError('name');

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

    clearFieldError('expirationDate');

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