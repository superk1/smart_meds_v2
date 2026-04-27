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
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: AppSectionTitle(
              title: AppStrings.inventoryTitle,
              description: 'Gestiona tu botiquín personal',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      GoRouter.of(context).push('/intake');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo Ingreso'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Summary Header
          summaryAsync.when(
            data: (summary) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SummaryCard(
                      label: 'Total',
                      value: summary['total'] ?? 0,
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'Próximos',
                      value: summary['expiringSoon'] ?? 0,
                      icon: Icons.timer,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'Vencidos',
                      value: summary['expired'] ?? 0,
                      icon: Icons.warning_amber,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'Sin Stock',
                      value: summary['outOfStock'] ?? 0,
                      icon: Icons.shopping_cart,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => ref.read(inventorySearchQueryProvider.notifier).setQuery(value),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => ref.read(inventorySearchQueryProvider.notifier).clearQuery(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<InventorySortCriteria>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Ordenar por',
                  onSelected: (criteria) =>
                      ref.read(inventorySortCriteriaProvider.notifier).setSortCriteria(criteria),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: InventorySortCriteria.expirationDate,
                      child: Text('Vencimiento más próximo'),
                    ),
                    const PopupMenuItem(
                      value: InventorySortCriteria.nameAZ,
                      child: Text('Nombre A-Z'),
                    ),
                    const PopupMenuItem(
                      value: InventorySortCriteria.lowStock,
                      child: Text('Menor stock primero'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  label: 'Próximos a vencer',
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
          const SizedBox(height: 8),
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
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final expirationState = item.expirationState;
                    final stockState = item.stockState;

                    return ListTile(
                      title: Text(
                        item.name,
                        style: TextStyle(
                          color: stockState == StockState.outOfStock ? Colors.grey : null,
                          decoration: stockState == StockState.outOfStock ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cantidad: ${item.quantity} | Expira: ${item.expirationDate.toString().split(' ')[0]}',
                            style: TextStyle(
                              color: stockState == StockState.outOfStock ? Colors.grey : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildExpirationBadge(expirationState),
                              _buildStockBadge(stockState),
                            ],
                          ),
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: stockState == StockState.outOfStock ? Colors.grey.shade200 : null,
                        child: Icon(
                          Icons.inventory_2,
                          color: stockState == StockState.outOfStock ? Colors.grey : null,
                        ),
                      ),
                      isThreeLine: true,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => InventoryDetailSheet(itemId: item.id),
                        );
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'use') {
                            ref.read(inventoryListProvider.notifier).useItem(item);
                          } else if (value == 'restock') {
                            ref.read(inventoryListProvider.notifier).restockItem(item);
                          } else if (value == 'discard') {
                            ref.read(inventoryListProvider.notifier).discardItem(item.id);
                          }
                        },
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
    if (baseItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tu inventario está vacío',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Agrega medicamentos usando el botón superior.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sin coincidencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'No encontramos resultados para "$query"',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    String title;
    String description;
    IconData icon;

    switch (filter) {
      case InventoryFilter.all:
        title = 'Tu inventario está vacío';
        description = 'Agrega medicamentos usando el botón superior.';
        icon = Icons.inventory_2_outlined;
        break;
      case InventoryFilter.expiringSoon:
        title = 'Sin alertas próximas';
        description = 'No tienes medicamentos próximos a vencer.';
        icon = Icons.notifications_none;
        break;
      case InventoryFilter.expired:
        title = 'Todo vigente';
        description = 'No tienes medicamentos vencidos.';
        icon = Icons.check_circle_outline;
        break;
      case InventoryFilter.outOfStock:
        title = 'Stock completo';
        description = 'No tienes medicamentos sin stock.';
        icon = Icons.shopping_basket_outlined;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color.withAlpha(200),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(50) : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}
