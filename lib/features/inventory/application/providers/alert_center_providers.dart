import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/reminder_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';
import 'package:smart_meds_v2/features/inventory/presentation/view_models/alert_center_entry.dart';

/// Provider derivado que construye la lista completa de [AlertCenterEntry],
/// ordenada por urgencia. Se apoya en [activeAlertsProvider] e [inventoryListProvider].
final alertCenterEntriesProvider = Provider<List<AlertCenterEntry>>((ref) {
  final activeAlerts = ref.watch(activeAlertsProvider);
  final inventory = ref.watch(inventoryListProvider).value ?? [];
  if (activeAlerts.isEmpty) return [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final List<AlertCenterEntry> entries = [];

  for (final reminder in activeAlerts) {
    final item = inventory.where((i) => i.id == reminder.inventoryItemId).firstOrNull;
    // Descartar recordatorios huérfanos
    if (item == null) continue;

    String title;
    String subtitle;
    int urgencyRank;

    if (reminder.type == ReminderType.expiration && reminder.targetDate != null) {
      final target = DateTime(
        reminder.targetDate!.year,
        reminder.targetDate!.month,
        reminder.targetDate!.day,
      );
      title = item.name;

      if (target.isBefore(today)) {
        subtitle = 'Vencido';
        urgencyRank = 0; // Máxima urgencia
      } else if (target.isAtSameMomentAs(today)) {
        subtitle = 'Vence hoy';
        urgencyRank = 1;
      } else {
        final daysLeft = target.difference(today).inDays;
        final dd = target.day.toString().padLeft(2, '0');
        final mm = target.month.toString().padLeft(2, '0');
        final yyyy = target.year;
        subtitle = 'Vence el $dd/$mm/$yyyy ($daysLeft días)';
        // Más cercano = más urgente (rank menor)
        urgencyRank = 2 + daysLeft;
      }
    } else if (reminder.type == ReminderType.stock && reminder.targetQuantity != null) {
      title = item.name;
      subtitle = 'Quedan ${item.quantity} unidades (umbral: ${reminder.targetQuantity})';
      // Stock: menor cantidad = más urgente
      urgencyRank = 1000 + item.quantity;
    } else {
      continue;
    }

    entries.add(AlertCenterEntry(
      reminder: reminder,
      item: item,
      type: reminder.type,
      title: title,
      subtitle: subtitle,
      targetDate: reminder.targetDate,
      targetQuantity: reminder.targetQuantity,
      urgencyRank: urgencyRank,
    ));
  }

  entries.sort((a, b) => a.urgencyRank.compareTo(b.urgencyRank));
  return entries;
});

/// Solo alertas de vencimiento, ya ordenadas.
final alertCenterExpirationProvider = Provider<List<AlertCenterEntry>>((ref) {
  return ref.watch(alertCenterEntriesProvider)
      .where((e) => e.type == ReminderType.expiration)
      .toList();
});

/// Solo alertas de stock bajo, ya ordenadas.
final alertCenterStockProvider = Provider<List<AlertCenterEntry>>((ref) {
  return ref.watch(alertCenterEntriesProvider)
      .where((e) => e.type == ReminderType.stock)
      .toList();
});

/// Contador total de alertas activas (para badge).
final alertCenterCountProvider = Provider<int>((ref) {
  return ref.watch(alertCenterEntriesProvider).length;
});
