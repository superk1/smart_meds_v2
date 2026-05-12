import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/reminder_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';
import 'package:smart_meds_v2/features/inventory/presentation/view_models/alert_center_entry.dart';

/// Provider derivado que construye la lista completa de [AlertCenterEntry],
/// ordenada por urgencia. Se apoya en [activeAlertsProvider] e [inventoryListProvider].
final alertCenterEntriesProvider = Provider<List<AlertCenterEntry>>((ref) {
  final activeAlerts = ref.watch(activeAlertsProvider);
  final inventory = ref.watch(inventoryListProvider).value ?? [];
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final Set<String> processedItemTypes = {};
  final List<AlertCenterEntry> entries = [];

  // 1. First, process Manual Reminders (they have priority or are explicit)
  for (final reminder in activeAlerts) {
    final item = inventory.where((i) => i.id == reminder.inventoryItemId).firstOrNull;
    if (item == null) continue;

    String title = item.name;
    String subtitle;
    int urgencyRank;

    if (reminder.type == ReminderType.expiration && reminder.targetDate != null) {
      final target = DateTime(reminder.targetDate!.year, reminder.targetDate!.month, reminder.targetDate!.day);
      if (target.isBefore(today)) {
        subtitle = 'Vencido (Recordatorio)';
        urgencyRank = 0;
      } else if (target.isAtSameMomentAs(today)) {
        subtitle = 'Vence hoy';
        urgencyRank = 1;
      } else {
        final daysLeft = target.difference(today).inDays;
        subtitle = 'Vence el ${target.day}/${target.month}/${target.year} ($daysLeft días)';
        urgencyRank = 2 + daysLeft;
      }
      processedItemTypes.add('${item.id}_${ReminderType.expiration}');
    } else if (reminder.type == ReminderType.stock && reminder.targetQuantity != null) {
      subtitle = 'Bajo stock: quedan ${item.quantity} (umbral: ${reminder.targetQuantity})';
      urgencyRank = 500 + item.quantity;
      processedItemTypes.add('${item.id}_${ReminderType.stock}');
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

  // 2. Second, process Automatic Health Alerts
  for (final item in inventory) {
    // A. Automatic Expiration
    final expState = item.expirationState;
    if (expState != ExpirationState.valid && !processedItemTypes.contains('${item.id}_${ReminderType.expiration}')) {
      final expDate = DateTime(item.expirationDate.year, item.expirationDate.month, item.expirationDate.day);
      final daysLeft = expDate.difference(today).inDays;
      
      String subtitle;
      int urgencyRank;
      
      if (expState == ExpirationState.expired) {
        subtitle = '¡Medicamento vencido!';
        urgencyRank = 0;
      } else {
        subtitle = 'Vence pronto: $daysLeft días (${expDate.day}/${expDate.month})';
        urgencyRank = 2 + daysLeft;
      }

      entries.add(AlertCenterEntry(
        item: item,
        type: ReminderType.expiration,
        title: item.name,
        subtitle: subtitle,
        targetDate: item.expirationDate,
        urgencyRank: urgencyRank,
      ));
    }

    // B. Automatic Stock
    final stState = item.stockState;
    if (stState != StockState.inStock && !processedItemTypes.contains('${item.id}_${ReminderType.stock}')) {
      String subtitle;
      int urgencyRank;

      if (stState == StockState.outOfStock) {
        subtitle = '¡Agotado!';
        urgencyRank = 5; // Muy urgente
      } else {
        subtitle = 'Stock bajo: ${item.quantity} unidades restantes';
        urgencyRank = 500 + item.quantity;
      }

      entries.add(AlertCenterEntry(
        item: item,
        type: ReminderType.stock,
        title: item.name,
        subtitle: subtitle,
        targetQuantity: 2, // Umbral por defecto de la entidad
        urgencyRank: urgencyRank,
      ));
    }
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

/// Alertas de máxima urgencia (vencidos, agotan hoy, sin stock).
final criticalAlertsProvider = Provider<List<AlertCenterEntry>>((ref) {
  return ref.watch(alertCenterEntriesProvider)
      .where((e) => e.urgencyRank < 10)
      .toList();
});
