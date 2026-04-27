import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/core/constants/app_strings.dart';
import 'package:smart_meds_v2/features/admin_review/application/providers/admin_review_providers.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_section_title.dart';

class AdminReviewScreen extends ConsumerWidget {
  const AdminReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsState = ref.watch(pendingSubmissionsListProvider);

    return AppScaffold(
      title: AppStrings.adminReviewTitle,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: AppSectionTitle(
              title: AppStrings.adminReviewTitle,
              description: 'Moderar medicamentos propuestos por los usuarios.',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: submissionsState.when(
              data: (submissions) {
                if (submissions.isEmpty) {
                  return const Center(
                    child: Text('No hay revisiones pendientes.'),
                  );
                }
                return ListView.builder(
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final sub = submissions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(sub.proposedName),
                        subtitle: Text('Activo: ${sub.proposedActiveIngredient}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => ref.read(pendingSubmissionsListProvider.notifier).approve(sub.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => ref.read(pendingSubmissionsListProvider.notifier).reject(sub.id),
                            ),
                          ],
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
}
