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
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppSectionTitle(
              title: AppStrings.catalogTitle,
              description: 'Explora medicamentos validados.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchBar(
              hintText: 'Nombre o sustancia...',
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(Colors.grey.shade100),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
              leading: const Icon(Icons.search, color: Colors.grey),
              onChanged: (value) {
                ref.read(catalogSearchQueryProvider.notifier).updateQuery(value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: catalogState.when(
              data: (medications) {
                if (medications.isEmpty) {
                  return _buildEmptyState(ref.watch(catalogSearchQueryProvider));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final med = medications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          med.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Sustancia: ${med.activeIngredient}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.medication_liquid_rounded, color: Colors.teal.shade600),
                        ),
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

  Widget _buildEmptyState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                query.isEmpty ? Icons.library_books_outlined : Icons.search_off_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              query.isEmpty ? 'Cargando catálogo...' : 'Sin coincidencias',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              query.isEmpty 
                ? 'Espera un momento mientras preparamos la lista.' 
                : 'No encontramos nada para "$query". Prueba con otro nombre.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
