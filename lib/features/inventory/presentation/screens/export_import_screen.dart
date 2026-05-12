import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_export_providers.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_section_title.dart';

class ExportImportScreen extends ConsumerWidget {
  const ExportImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryExportImportControllerProvider);

    // Listen for success/error messages
    ref.listen(inventoryExportImportControllerProvider, (previous, next) {
      if (next.lastSuccessMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.lastSuccessMessage!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(inventoryExportImportControllerProvider.notifier).clearMessages();
      }
      if (next.lastErrorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.lastErrorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(inventoryExportImportControllerProvider.notifier).clearMessages();
      }
    });

    return AppScaffold(
      title: 'Respaldo Manual',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(
              title: 'Exportar e Importar',
              description: 'Gestiona tus datos de forma local y segura.',
            ),
            const SizedBox(height: 32),
            
            _ActionCard(
              title: 'Exportar Inventario',
              description: 'Genera un archivo JSON con todos tus medicamentos para guardarlo o compartirlo.',
              icon: Icons.file_upload_outlined,
              color: Colors.blue,
              isLoading: state.isProcessing,
              onTap: () => ref.read(inventoryExportImportControllerProvider.notifier).exportInventory(),
            ),
            
            const SizedBox(height: 20),
            
            _ActionCard(
              title: 'Importar Inventario',
              description: 'Carga un archivo de respaldo previo. Nota: Esto sobrescribirá tu inventario actual.',
              icon: Icons.file_download_outlined,
              color: Colors.orange,
              isLoading: state.isProcessing,
              onTap: () => _confirmImport(context, ref),
            ),
            
            const SizedBox(height: 48),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueGrey),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Los archivos de respaldo contienen nombres, cantidades y fechas de vencimiento. No incluyen fotos ni datos sensibles fuera de tu botiquín.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmImport(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Importar respaldo?'),
        content: const Text(
          'Esta acción reemplazará todos los medicamentos actuales en tu botiquín por los que contiene el archivo seleccionado. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(inventoryExportImportControllerProvider.notifier).importInventory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Importar y Sobrescribir'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withAlpha(50)),
      ),
      color: color.withAlpha(10),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
