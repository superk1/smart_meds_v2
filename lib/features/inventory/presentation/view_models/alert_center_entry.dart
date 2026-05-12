import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';

/// Modelo de vista para una entrada del Centro de Alertas.
///
/// Contiene datos ya preparados para la UI, evitando lógica en widgets.
class AlertCenterEntry {
  final InventoryReminder? reminder;
  final InventoryItem item;
  final ReminderType type;
  final String title;
  final String subtitle;
  final DateTime? targetDate;
  final int? targetQuantity;

  /// Menor valor = mayor urgencia.
  final int urgencyRank;

  const AlertCenterEntry({
    this.reminder,
    required this.item,
    required this.type,
    required this.title,
    required this.subtitle,
    this.targetDate,
    this.targetQuantity,
    required this.urgencyRank,
  });
}
