import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/intake/domain/entities/intake_capture_result.dart';

enum IntakeStatus {
  idle,
  loading,
  reviewing,
  confirmed,
  error,
}

class IntakeState {
  final IntakeStatus status;
  final InventoryItem? draftItem;
  final IntakeSource? source;
  final String? errorMessage;

  const IntakeState({
    this.status = IntakeStatus.idle,
    this.draftItem,
    this.source,
    this.errorMessage,
  });

  IntakeState copyWith({
    IntakeStatus? status,
    InventoryItem? draftItem,
    IntakeSource? source,
    String? errorMessage,
  }) {
    return IntakeState(
      status: status ?? this.status,
      draftItem: draftItem ?? this.draftItem,
      source: source ?? this.source,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
