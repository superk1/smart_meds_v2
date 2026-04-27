import 'dart:convert';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/admin_review/data/models/pending_medication_submission_model.dart';
import 'package:smart_meds_v2/features/admin_review/domain/entities/pending_medication_submission.dart';
import 'package:smart_meds_v2/features/admin_review/domain/repositories/pending_submission_repository.dart';

class FakePendingSubmissionRepository implements PendingSubmissionRepository {
  final LocalStorageService _storage;
  static const String _storageKey = 'admin_pending_submissions';

  final List<PendingMedicationSubmission> _submissions = [];
  bool _isInitialized = false;

  FakePendingSubmissionRepository(this._storage);

  Future<void> _init() async {
    if (_isInitialized) return;

    final storedData = _storage.readString(_storageKey);
    if (storedData != null) {
      final List<dynamic> decoded = jsonDecode(storedData);
      _submissions.clear();
      _submissions.addAll(
        decoded.map((m) => PendingMedicationSubmissionModel.fromMap(m as Map<String, dynamic>).toDomain()),
      );
    } else {
      // Seed initial data
      _submissions.addAll([
        const PendingMedicationSubmission(
          id: 'sub_1',
          proposedName: 'Aspirina 500mg',
          proposedActiveIngredient: 'Ácido Acetilsalicílico',
          userId: 'user_123',
        ),
        const PendingMedicationSubmission(
          id: 'sub_2',
          proposedName: 'Tempra Forte',
          proposedActiveIngredient: 'Paracetamol',
          userId: 'user_456',
        ),
      ]);
      await _save();
    }
    _isInitialized = true;
  }

  Future<void> _save() async {
    final String encoded = jsonEncode(
      _submissions.map((s) => PendingMedicationSubmissionModel.fromDomain(s).toMap()).toList(),
    );
    await _storage.writeString(_storageKey, encoded);
  }

  @override
  Future<List<PendingMedicationSubmission>> getPendingSubmissions() async {
    await _init();
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_submissions);
  }

  @override
  Future<void> approveSubmission(String id) async {
    await _init();
    await Future.delayed(const Duration(milliseconds: 100));
    _submissions.removeWhere((sub) => sub.id == id);
    await _save();
  }

  @override
  Future<void> rejectSubmission(String id) async {
    await _init();
    await Future.delayed(const Duration(milliseconds: 100));
    _submissions.removeWhere((sub) => sub.id == id);
    await _save();
  }
}
