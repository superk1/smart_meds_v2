import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meds_v2/features/catalog/domain/constants/catalog_constants.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_reminder.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/reminder_providers.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';
import 'package:uuid/uuid.dart';

class InventoryItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  final bool fromNotification;
  final String? notificationType;

  const InventoryItemDetailScreen({
    super.key,
    required this.itemId,
    this.fromNotification = false,
    this.notificationType,
  });

  @override
  ConsumerState<InventoryItemDetailScreen> createState() => _InventoryItemDetailScreenState();
}

class _InventoryItemDetailScreenState extends ConsumerState<InventoryItemDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryListProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (widget.fromNotification) {
          // Set highlight id so InventoryScreen can blink it
          ref.read(inventoryHighlightProvider.notifier).setHighlight(widget.itemId);
        }
      },
      child: inventoryState.when(
        data: (items) {
          final item = items.where((i) => i.id == widget.itemId).firstOrNull;
          if (item == null) {
            return AppScaffold(
              title: 'No encontrado',
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        widget.fromNotification
                            ? 'El medicamento asociado a esta notificación ya no existe en tu inventario.'
                            : 'El medicamento ya no existe en el inventario.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              ),
            );
          }

        final isManual = item.catalogMedicationId == CatalogConstants.unknownId;

        return AppScaffold(
          title: 'Detalle de Medicamento',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Name
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 8),
                _OriginChip(isManual: isManual),
                const SizedBox(height: 24),
                
                // Context Banner for Notifications
                if (widget.fromNotification) ...[
                  _NotificationContextBanner(type: widget.notificationType),
                  const SizedBox(height: 24),
                ],

                // Info Grid
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.calendar_today,
                        label: 'Vencimiento',
                        value: item.expirationDate.toString().split(' ')[0],
                        color: _getExpirationColor(item.expirationState),
                        subtitle: _getExpirationText(item.expirationState),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Stock Actual',
                        value: '${item.quantity} uds',
                        color: _getStockColor(item.stockState),
                        subtitle: _getStockText(item.stockState),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Actions Section
                const Text(
                  'Gestión de Inventario',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                _ActionTile(
                  icon: Icons.add_circle_outline,
                  label: 'Reponer unidades',
                  description: 'Aumentar el stock disponible.',
                  color: Colors.green,
                  onTap: () => ref.read(inventoryListProvider.notifier).restockItem(item),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.remove_circle_outline,
                  label: 'Usar una unidad',
                  description: 'Registrar el consumo de un medicamento.',
                  color: Colors.blue,
                  onTap: item.quantity > 0
                      ? () => ref.read(inventoryListProvider.notifier).useItem(item)
                      : null,
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.edit_outlined,
                  label: 'Editar información',
                  description: 'Cambiar nombre o fecha de vencimiento.',
                  color: Colors.orange,
                  onTap: () => _showEditDialog(context, ref, item),
                ),
                const SizedBox(height: 32),

                // Reminders Section
                _RemindersSection(item: item),
                const SizedBox(height: 32),

                // Critical Actions
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(context, ref, item),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Eliminar del inventario'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const AppScaffold(
        title: 'Cargando...',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => AppScaffold(
        title: 'Error',
        body: Center(child: Text('Error: $error')),
      ),
    ),
    );
  }

  Color _getExpirationColor(ExpirationState state) {
    return switch (state) {
      ExpirationState.valid => Colors.green,
      ExpirationState.expiringSoon => Colors.orange,
      ExpirationState.expired => Colors.red,
    };
  }

  String _getExpirationText(ExpirationState state) {
    return switch (state) {
      ExpirationState.valid => 'Vigente',
      ExpirationState.expiringSoon => 'Pronto a vencer',
      ExpirationState.expired => 'Vencido',
    };
  }

  Color _getStockColor(StockState state) {
    return switch (state) {
      StockState.inStock => Colors.blue,
      StockState.lowStock => Colors.orange,
      StockState.outOfStock => Colors.grey,
    };
  }

  String _getStockText(StockState state) {
    return switch (state) {
      StockState.inStock => 'Suficiente',
      StockState.lowStock => 'Bajo',
      StockState.outOfStock => 'Agotado',
    };
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, InventoryItem item) {
    final nameController = TextEditingController(text: item.name);
    DateTime selectedDate = item.expirationDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Medicamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre local'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Vencimiento'),
                subtitle: Text(selectedDate.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedItem = InventoryItem(
                  id: item.id,
                  catalogMedicationId: item.catalogMedicationId,
                  name: nameController.text.trim(),
                  expirationDate: selectedDate,
                  quantity: item.quantity,
                );
                ref.read(inventoryListProvider.notifier).updateItem(updatedItem);
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar medicamento?'),
        content: Text('Se borrará "${item.name}" definitivamente de tu inventario.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(inventoryListProvider.notifier).discardItem(item.id);
              Navigator.pop(context); // Close dialog
              context.pop(); // Go back to list
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _OriginChip extends StatelessWidget {
  final bool isManual;
  const _OriginChip({required this.isManual});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isManual ? Colors.orange.shade50 : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isManual ? Colors.orange.shade100 : Colors.teal.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isManual ? Icons.edit_note : Icons.verified_user_outlined,
            size: 14,
            color: isManual ? Colors.orange.shade800 : Colors.teal.shade800,
          ),
          const SizedBox(width: 4),
          Text(
            isManual ? 'Registro Manual' : 'Catálogo Oficial',
            style: TextStyle(
              color: isManual ? Colors.orange.shade800 : Colors.teal.shade800,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _RemindersSection extends ConsumerWidget {
  final InventoryItem item;
  const _RemindersSection({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersForItemProvider(item.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recordatorios',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddReminderDialog(context, ref, item),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (reminders.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications_none, color: Colors.grey, size: 20),
                SizedBox(width: 12),
                Text(
                  'No hay recordatorios activos.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reminders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = reminders[index];
              final isExpiration = r.type == ReminderType.expiration;
              
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: r.isActive ? Colors.blue.shade100 : Colors.grey.shade200),
                ),
                color: r.isActive ? Colors.blue.shade50.withAlpha(50) : Colors.grey.shade50,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    isExpiration ? Icons.event : Icons.inventory_2,
                    color: r.isActive ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    isExpiration 
                        ? 'Avisar vencimiento' 
                        : 'Avisar stock bajo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: r.isActive ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    isExpiration
                        ? 'Fecha: ${r.targetDate?.toString().split(' ')[0]}'
                        : 'Umbral: ${r.targetQuantity} unidades',
                    style: TextStyle(color: r.isActive ? Colors.black54 : Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch.adaptive(
                        value: r.isActive,
                        onChanged: (_) => ref.read(reminderListProvider.notifier).toggleReminder(r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => ref.read(reminderListProvider.notifier).deleteReminder(r.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddReminderDialog(BuildContext context, WidgetRef ref, InventoryItem item) {
    ReminderType selectedType = ReminderType.expiration;
    int daysBefore = 7;
    int threshold = 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Recordatorio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<ReminderType>(
                segments: const [
                  ButtonSegment(value: ReminderType.expiration, label: Text('Vencimiento'), icon: Icon(Icons.event)),
                  ButtonSegment(value: ReminderType.stock, label: Text('Stock'), icon: Icon(Icons.inventory_2)),
                ],
                selected: {selectedType},
                onSelectionChanged: (val) => setState(() => selectedType = val.first),
              ),
              const SizedBox(height: 24),
              if (selectedType == ReminderType.expiration)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Días antes del vencimiento:', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: daysBefore,
                      items: [1, 3, 7, 15, 30].map((d) => DropdownMenuItem(value: d, child: Text('$d días'))).toList(),
                      onChanged: (val) => setState(() => daysBefore = val!),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Avisar cuando queden menos de:', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: threshold,
                      items: [1, 2, 5, 10].map((d) => DropdownMenuItem(value: d, child: Text('$d unidades'))).toList(),
                      onChanged: (val) => setState(() => threshold = val!),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final id = const Uuid().v4();
                final now = DateTime.now();
                
                DateTime? targetDate;
                int? targetQuantity;

                if (selectedType == ReminderType.expiration) {
                  targetDate = item.expirationDate.subtract(Duration(days: daysBefore));
                } else {
                  targetQuantity = threshold;
                }

                final reminder = InventoryReminder(
                  id: id,
                  inventoryItemId: item.id,
                  type: selectedType,
                  createdAt: now,
                  targetDate: targetDate,
                  targetQuantity: targetQuantity,
                );

                ref.read(reminderListProvider.notifier).addReminder(reminder);
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDisabled ? Colors.grey.shade100 : color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isDisabled ? Colors.grey : color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.grey : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationContextBanner extends StatelessWidget {
  final String? type;

  const _NotificationContextBanner({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String title;
    String message;

    if (type == 'expiration') {
      icon = Icons.event;
      color = Colors.orange;
      title = 'Alerta de vencimiento';
      message = 'Llegaste aquí desde una notificación de vencimiento.';
    } else if (type == 'stock') {
      icon = Icons.inventory_2_outlined;
      color = Colors.blue;
      title = 'Alerta de stock bajo';
      message = 'Llegaste aquí desde una notificación de stock bajo.';
    } else {
      icon = Icons.notifications_active_outlined;
      color = Colors.indigo;
      title = 'Desde una notificación';
      message = 'Llegaste aquí al tocar una alerta de tu botiquín.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.withAlpha(200),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
