import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';

class InventoryDetailSheet extends ConsumerWidget {
  final String itemId;

  const InventoryDetailSheet({
    super.key,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(inventoryListProvider);
    
    return inventoryState.when(
      data: (items) {
        final item = items.where((i) => i.id == itemId).firstOrNull;
        if (item == null) {
          // If item was deleted, close the sheet
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
          return const SizedBox.shrink();
        }

        final expirationState = item.expirationState;
        final stockState = item.stockState;
        final isManual = item.catalogMedicationId == 'desconocido';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isManual ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isManual ? 'Origen: Registro Manual' : 'Origen: Catálogo Oficial',
                  style: TextStyle(
                    color: isManual ? Colors.orange.shade900 : Colors.green.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                context,
                icon: Icons.calendar_today,
                label: 'Vencimiento',
                value: item.expirationDate.toString().split(' ')[0],
                trailing: _buildExpirationBadge(expirationState),
              ),
              const Divider(height: 32),
              _buildInfoRow(
                context,
                icon: Icons.inventory_2_outlined,
                label: 'Stock Actual',
                value: '${item.quantity} unidades',
                trailing: _buildStockBadge(stockState),
              ),
              const SizedBox(height: 32),
              const Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      onPressed: item.quantity > 0
                          ? () {
                              ref.read(inventoryListProvider.notifier).useItem(item);
                            }
                          : null,
                      icon: Icons.remove_circle_outline,
                      label: 'Usar 1',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      onPressed: () {
                        ref.read(inventoryListProvider.notifier).restockItem(item);
                      },
                      icon: Icons.add_circle_outline,
                      label: 'Reponer 1',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showDeleteConfirmation(context, ref, item);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Descartar Medicamento', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const Spacer(),
        trailing,
      ],
    );
  }

  Widget _buildExpirationBadge(ExpirationState state) {
    String text;
    Color color;
    Color bgColor;

    switch (state) {
      case ExpirationState.valid:
        text = 'Vigente';
        color = Colors.green.shade700;
        bgColor = Colors.green.shade50;
        break;
      case ExpirationState.expiringSoon:
        text = 'Próximo a vencer';
        color = Colors.orange.shade700;
        bgColor = Colors.orange.shade50;
        break;
      case ExpirationState.expired:
        text = 'Vencido';
        color = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        break;
    }

    return _Badge(text: text, color: color, bgColor: bgColor);
  }

  Widget _buildStockBadge(StockState state) {
    String text;
    Color color;
    Color bgColor;

    switch (state) {
      case StockState.inStock:
        text = 'Stock suficiente';
        color = Colors.blue.shade700;
        bgColor = Colors.blue.shade50;
        break;
      case StockState.lowStock:
        text = 'Stock bajo';
        color = Colors.orange.shade700;
        bgColor = Colors.orange.shade50;
        break;
      case StockState.outOfStock:
        text = 'Sin stock';
        color = Colors.grey.shade700;
        bgColor = Colors.grey.shade50;
        break;
    }

    return _Badge(text: text, color: color, bgColor: bgColor);
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar medicamento?'),
        content: Text('Se eliminará "${item.name}" de tu inventario.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(inventoryListProvider.notifier).discardItem(item.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        disabledBackgroundColor: color.withAlpha(100),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color bgColor;

  const _Badge({
    required this.text,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
