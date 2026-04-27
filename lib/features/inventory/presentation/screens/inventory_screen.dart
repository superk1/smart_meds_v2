import 'package:go_router/go_router.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/core/constants/app_strings.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_providers.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_section_title.dart';
import 'package:smart_meds_v2/features/inventory/presentation/widgets/inventory_detail_sheet.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(filteredInventoryProvider);
    final activeFilter = ref.watch(inventoryFilterProvider);
    final baseInventory = ref.watch(inventoryListProvider);
    final searchQuery = ref.watch(inventorySearchQueryProvider);
    final summaryAsync = ref.watch(inventorySummaryProvider);

    return AppScaffold(
      title: AppStrings.inventoryTitle,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: AppSectionTitle(
                    title: AppStrings.inventoryTitle,
                    description: 'Tu botiquín personal organizado.',
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => context.push('/intake'),
                  icon: const Icon(Icons.add),
                  tooltip: 'Nuevo Ingreso',
                ),
              ],
            ),
          ),
          
          // Summary Header
          summaryAsync.when(
            data: (summary) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _SummaryCard(
                      label: 'Total',
                      value: summary['total'] ?? 0,
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      label: 'Próximos',
                      value: summary['expiringSoon'] ?? 0,
                      icon: Icons.timer_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      label: 'Vencidos',
                      value: summary['expired'] ?? 0,
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      label: 'Sin Stock',
                      value: summary['outOfStock'] ?? 0,
                      icon: Icons.remove_shopping_cart_outlined,
                      color: Colors.blueGrey,
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox(height: 80),
            error: (error, _) => const SizedBox.shrink(),
          ),
          
          const SizedBox(height: 16),
          
          // Search and Sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    hintText: 'Buscar por nombre...',
                    elevation: const WidgetStatePropertyAll(0),
                    backgroundColor: WidgetStatePropertyAll(Colors.grey.shade100),
                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
                    onChanged: (value) => ref.read(inventorySearchQueryProvider.notifier).setQuery(value),
                    leading: const Icon(Icons.search, color: Colors.grey),
                    trailing: [
                      if (searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => ref.read(inventorySearchQueryProvider.notifier).clearQuery(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SortButton(
                  currentCriteria: ref.watch(inventorySortCriteriaProvider),
                  onSelected: (criteria) => ref.read(inventorySortCriteriaProvider.notifier).setSortCriteria(criteria),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  count: baseInventory.whenOrNull(data: (items) => items.length),
                  isSelected: activeFilter == InventoryFilter.all,
                  onSelected: () => ref.read(inventoryFilterProvider.notifier).setFilter(InventoryFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Próximos',
                  count: baseInventory.whenOrNull(data: (items) => items.where((i) => i.expirationState == ExpirationState.expiringSoon).length),
                  isSelected: activeFilter == InventoryFilter.expiringSoon,
                  onSelected: () => ref.read(inventoryFilterProvider.notifier).setFilter(InventoryFilter.expiringSoon),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Vencidos',
                  count: baseInventory.whenOrNull(data: (items) => items.where((i) => i.expirationState == ExpirationState.expired).length),
                  isSelected: activeFilter == InventoryFilter.expired,
                  onSelected: () => ref.read(inventoryFilterProvider.notifier).setFilter(InventoryFilter.expired),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Sin stock',
                  count: baseInventory.whenOrNull(data: (items) => items.where((i) => i.stockState == StockState.outOfStock).length),
                  isSelected: activeFilter == InventoryFilter.outOfStock,
                  onSelected: () => ref.read(inventoryFilterProvider.notifier).setFilter(InventoryFilter.outOfStock),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: inventoryState.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState(
                    activeFilter,
                    searchQuery,
                    baseInventory.asData?.value ?? [],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _InventoryItemCard(
                      item: item,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => InventoryDetailSheet(itemId: item.id),
                        );
                      },
                      onAction: (action) {
                        if (action == 'use') {
                          ref.read(inventoryListProvider.notifier).useItem(item);
                        } else if (action == 'restock') {
                          ref.read(inventoryListProvider.notifier).restockItem(item);
                        } else if (action == 'discard') {
                          ref.read(inventoryListProvider.notifier).discardItem(item.id);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    InventoryFilter filter,
    String query,
    List<InventoryItem> baseItems,
  ) {
    String title;
    String description;
    IconData icon;
    Color iconColor = Colors.grey.shade400;

    if (baseItems.isEmpty) {
      title = 'Tu botiquín está vacío';
      description = 'Comienza agregando los medicamentos que tienes en casa.';
      icon = Icons.inventory_2_outlined;
    } else if (query.isNotEmpty) {
      title = 'Sin coincidencias';
      description = 'No encontramos nada que coincida con "$query"';
      icon = Icons.search_off_rounded;
    } else {
      switch (filter) {
        case InventoryFilter.all:
          title = 'Nada por aquí';
          description = 'Tu inventario parece estar vacío.';
          icon = Icons.inventory_2_outlined;
          break;
        case InventoryFilter.expiringSoon:
          title = 'Sin alertas próximas';
          description = 'No tienes medicamentos próximos a vencer. ¡Excelente!';
          icon = Icons.timer_outlined;
          iconColor = Colors.orange.shade200;
          break;
        case InventoryFilter.expired:
          title = 'Todo vigente';
          description = 'No tienes medicamentos vencidos en este filtro.';
          icon = Icons.verified_user_outlined;
          iconColor = Colors.green.shade200;
          break;
        case InventoryFilter.outOfStock:
          title = 'Stock completo';
          description = 'No tienes medicamentos agotados. ¡Bien hecho!';
          icon = Icons.check_circle_outline_rounded;
          iconColor = Colors.blue.shade200;
          break;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  const _InventoryItemCard({
    required this.item,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final stockState = item.stockState;
    final expirationState = item.expirationState;
    final isOutOfStock = stockState == StockState.outOfStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOutOfStock ? Colors.grey.shade100 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: isOutOfStock ? Colors.grey.shade400 : Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock ? Colors.grey : Colors.black87,
                        decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity} unidades • Expira: ${item.expirationDate.toString().split(' ')[0]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _ExpirationBadge(state: expirationState),
                        _StockBadge(state: stockState),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: onAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'use',
                    enabled: item.quantity > 0,
                    child: const Row(
                      children: [
                        Icon(Icons.remove_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Usar 1'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'restock',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Reponer 1'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'discard',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Descartar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpirationBadge extends StatelessWidget {
  final ExpirationState state;

  const _ExpirationBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    switch (state) {
      case ExpirationState.valid:
        text = 'Vigente';
        color = Colors.green;
        break;
      case ExpirationState.expiringSoon:
        text = 'Pronto a vencer';
        color = Colors.orange;
        break;
      case ExpirationState.expired:
        text = 'Vencido';
        color = Colors.red;
        break;
    }

    return _MiniBadge(text: text, color: color);
  }
}

class _StockBadge extends StatelessWidget {
  final StockState state;

  const _StockBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    switch (state) {
      case StockState.inStock:
        text = 'Stock OK';
        color = Colors.blue;
        break;
      case StockState.lowStock:
        text = 'Stock bajo';
        color = Colors.orange;
        break;
      case StockState.outOfStock:
        text = 'Agotado';
        color = Colors.grey;
        break;
    }

    return _MiniBadge(text: text, color: color);
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.withAlpha(220),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    this.count,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      avatar: count != null ? CircleAvatar(
        radius: 10,
        backgroundColor: isSelected ? Colors.white.withAlpha(50) : Colors.black.withAlpha(20),
        child: Text(
          count.toString(),
          style: TextStyle(
            fontSize: 9,
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final InventorySortCriteria currentCriteria;
  final ValueChanged<InventorySortCriteria> onSelected;

  const _SortButton({
    required this.currentCriteria,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<InventorySortCriteria>(
        icon: const Icon(Icons.sort_rounded, color: Colors.black54),
        tooltip: 'Ordenar',
        onSelected: onSelected,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: InventorySortCriteria.expirationDate,
            child: Text('Vencimiento'),
          ),
          const PopupMenuItem(
            value: InventorySortCriteria.nameAZ,
            child: Text('Nombre A-Z'),
          ),
          const PopupMenuItem(
            value: InventorySortCriteria.lowStock,
            child: Text('Stock bajo'),
          ),
        ],
      ),
    );
  }
}
