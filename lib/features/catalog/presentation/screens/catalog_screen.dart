import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/core/constants/app_strings.dart';
import 'package:smart_meds_v2/features/catalog/application/providers/catalog_providers.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_section_title.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogListProvider);

    return AppScaffold(
      title: AppStrings.catalogTitle,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: AppSectionTitle(
              title: AppStrings.catalogTitle,
              description: 'Busca y explora medicamentos globales',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar medicamento...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(catalogSearchQueryProvider.notifier).updateQuery(value);
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: catalogState.when(
              data: (medications) {
                if (medications.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron medicamentos.'),
                  );
                }
                return ListView.builder(
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final med = medications[index];
                    return ListTile(
                      title: Text(med.name),
                      subtitle: Text(med.activeIngredient),
                      leading: const CircleAvatar(
                        child: Icon(Icons.medication),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
