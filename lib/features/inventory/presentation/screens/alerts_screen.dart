import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/alert_center_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';
import 'package:smart_meds_v2/features/inventory/presentation/view_models/alert_center_entry.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expirationAlerts = ref.watch(alertCenterExpirationProvider);
    final stockAlerts = ref.watch(alertCenterStockProvider);
    final isEmpty = expirationAlerts.isEmpty && stockAlerts.isEmpty;

    return AppScaffold(
      title: 'Centro de alertas',
      body: isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Alertas activas de tu botiquín.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // --- Sección Vencimiento ---
                if (expirationAlerts.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.event,
                    title: 'Vencimiento',
                    count: expirationAlerts.length,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.orange.shade100),
                    ),
                    elevation: 0,
                    child: Column(
                      children: _buildAlertTiles(context, expirationAlerts),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // --- Sección Stock Bajo ---
                if (stockAlerts.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.inventory_2_outlined,
                    title: 'Stock bajo',
                    count: stockAlerts.length,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.blue.shade100),
                    ),
                    elevation: 0,
                    child: Column(
                      children: _buildAlertTiles(context, stockAlerts),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  List<Widget> _buildAlertTiles(BuildContext context, List<AlertCenterEntry> entries) {
    final List<Widget> tiles = [];
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      tiles.add(
        _AlertTile(
          entry: entry,
          onTap: () {
            final typeParam = entry.type == ReminderType.expiration ? 'expiration' : 'stock';
            context.push('/inventory/${entry.item.id}?fromNotification=1&type=$typeParam');
          },
        ),
      );
      if (i < entries.length - 1) {
        tiles.add(const Divider(height: 0));
      }
    }
    return tiles;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay alertas activas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cuando un medicamento venza o tenga stock bajo, aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AlertCenterEntry entry;
  final VoidCallback onTap;

  const _AlertTile({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpiration = entry.type == ReminderType.expiration;
    final Color iconColor;
    final IconData tileIcon;

    if (isExpiration) {
      // Vencido = rojo, hoy = naranja, futuro = naranja claro
      if (entry.urgencyRank == 0) {
        iconColor = Colors.red;
        tileIcon = Icons.error_outline;
      } else if (entry.urgencyRank == 1) {
        iconColor = Colors.orange;
        tileIcon = Icons.warning_amber_rounded;
      } else {
        iconColor = Colors.orange.shade300;
        tileIcon = Icons.event;
      }
    } else {
      iconColor = Colors.blue;
      tileIcon = Icons.inventory_2_outlined;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(tileIcon, color: iconColor, size: 22),
      ),
      title: Text(
        entry.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        entry.subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
