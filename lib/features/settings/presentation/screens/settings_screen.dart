import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meds_v2/features/auth/application/providers/auth_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_backup_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_sync_providers.dart';
import 'package:smart_meds_v2/core/notifications/notification_initializer.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/reminder_providers.dart';
import 'package:smart_meds_v2/features/inventory/data/services/local_notification_service.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_section_title.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/notification_preferences_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(inventorySyncControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final notificationPrefs = ref.watch(notificationPreferencesProvider);

    // Listen for success/error/conflict messages
    ref.listen(inventorySyncControllerProvider, (previous, next) {
      final successMsg = next.lastSuccessMessage;
      if (successMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(inventorySyncControllerProvider.notifier).clearMessages();
      }
      
      final errorMsg = next.lastErrorMessage;
      if (errorMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(inventorySyncControllerProvider.notifier).clearMessages();
      }

      // Detect new conflict
      final hadConflictBefore = previous?.hasConflict ?? false;
      if (!hadConflictBefore && next.hasConflict) {
        _showConflictDialog(context, ref, next);
      }
    });

    return AppScaffold(
      title: 'Configuración',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Account Section ---
          const AppSectionTitle(
            title: 'Cuenta',
            description: 'Tu sesión de usuario.',
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: authState.isAuthenticated
                  ? Row(
                      children: [
                        Icon(Icons.account_circle, color: Colors.teal.shade700, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sesión activa', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                authState.session?.email ?? '',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Text(
                          'Para sincronizar tu inventario y enviar propuestas al catálogo, inicia sesión.',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/login'),
                          icon: const Icon(Icons.login),
                          label: const Text('Iniciar sesión'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // --- Conflict Resolution Section ---
          if (syncState.hasConflict) ...[
            const _ConflictResolutionBlock(),
            const SizedBox(height: 24),
          ],

          // --- Sync Section ---
          const AppSectionTitle(
            title: 'Sincronización',
            description: 'Gestiona la copia de seguridad de tu inventario.',
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _SyncActionTile(
                    title: 'Subir al servidor',
                    subtitle: 'Envía el inventario de este dispositivo y reemplaza el que está en la nube.',
                    icon: Icons.cloud_upload_outlined,
                    onTap: syncState.isSyncing 
                        ? null 
                        : () => ref.read(inventorySyncControllerProvider.notifier).syncToRemote(),
                  ),
                  const Divider(),
                  _SyncActionTile(
                    title: 'Descargar del servidor',
                    subtitle: 'Trae el inventario de la nube y reemplaza lo que tienes en este dispositivo.',
                    icon: Icons.cloud_download_outlined,
                    onTap: syncState.isSyncing 
                        ? null 
                        : () => ref.read(inventorySyncControllerProvider.notifier).syncFromRemote(),
                  ),
                  const Divider(),
                  const _SyncMetadataInfo(),
                  if (syncState.isSyncing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text(
                      'Sincronizando...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- Backup Section ---
          const AppSectionTitle(
            title: 'Respaldo local',
            description: 'Protege tu inventario antes de sincronizar.',
          ),
          const SizedBox(height: 16),
          _BackupSection(),
          const SizedBox(height: 24),

          // --- Notifications Section ---
          const AppSectionTitle(
            title: 'Notificaciones',
            description: 'Gestiona las alertas de tu botiquín.',
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Probar notificación'),
                  subtitle: const Text('Envía una alerta de prueba inmediata.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final service = ref.read(notificationServiceProvider);
                    if (service is LocalNotificationService) {
                      service.showTestNotification();
                    }
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Solicitar permisos'),
                  subtitle: const Text('Asegúrate de que la app pueda enviarte avisos.'),
                  onTap: () async {
                    final granted = await NotificationInitializer.requestPermissions();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(granted 
                              ? 'Permisos concedidos correctamente.' 
                              : 'Permisos denegados o no configurados.'),
                          backgroundColor: granted ? Colors.green : Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            elevation: 0,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.event),
                  title: const Text('Alertas de vencimiento'),
                  subtitle: const Text('Recibir avisos cuando se acerque la fecha de vencimiento.'),
                  value: notificationPrefs.expirationAlertsEnabled,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).setExpirationEnabled(value);
                  },
                ),
                const Divider(height: 0),
                SwitchListTile(
                  secondary: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Alertas de stock bajo'),
                  subtitle: const Text('Recibir avisos cuando queden pocas unidades de un medicamento.'),
                  value: notificationPrefs.stockAlertsEnabled,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).setStockEnabled(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Multi-device info ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Si usas tu cuenta en más de un dispositivo, el inventario se mantiene '
              'compartido. Cuando sincronizas, se envía el inventario completo de '
              'este dispositivo y reemplaza el que está en la nube (última escritura gana). '
              'Por eso, asegúrate de descargar primero si hiciste cambios en otro dispositivo.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncMetadataInfo extends ConsumerWidget {
  const _SyncMetadataInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastAtAsync = ref.watch(lastSyncedAtProvider);
    final lastVerAsync = ref.watch(lastSyncedVersionProvider);
    final syncState = ref.watch(inventorySyncControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              syncState.hasConflict
                  ? Icons.warning_amber_rounded
                  : Icons.cloud_done_outlined,
              color: syncState.hasConflict ? Colors.orange : Colors.teal.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              syncState.hasConflict
                  ? 'Conflicto de sincronización'
                  : 'Estado de sincronización',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        lastAtAsync.when(
          data: (date) => Text(
            date != null 
                ? 'Última sincronización: ${_formatDate(date)}'
                : 'Nunca se ha sincronizado.',
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
          error: (_, _) => const Text('Error al cargar última sincronización', style: TextStyle(fontSize: 12, color: Colors.red)),
          loading: () => const Text('Cargando última sincronización...', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: 4),
        lastVerAsync.when(
          data: (version) => Text(
            version != null 
                ? 'Versión en este dispositivo: v$version'
                : 'Versión: ninguna (descarga primero).',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          error: (_, _) => const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
        ),
        if (syncState.hasConflict)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Hay un conflicto pendiente. Abre el cuadro de diálogo para decidir.',
              style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

void _showConflictDialog(
  BuildContext context,
  WidgetRef ref,
  InventorySyncState state,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final snapshot = state.pendingRemoteSnapshot;
      final versionText = snapshot != null ? ' (v${snapshot.version})' : '';

      return AlertDialog(
        title: const Text('Conflicto de inventario'),
        content: Text(
          state.conflictMessage ??
              'Otro dispositivo cambió tu inventario en la nube.'
              '\n\nElige qué versión conservar:\n'
              '- Mantener lo de la nube$versionText\n'
              '- Mantener lo de este dispositivo',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(inventorySyncControllerProvider.notifier).dismissConflict();
            },
            child: const Text('Decidir más tarde'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(inventorySyncControllerProvider.notifier).resolveConflictByDownloadingRemote();
            },
            child: const Text('Mantener nube'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(inventorySyncControllerProvider.notifier).resolveConflictByForceUploadingLocal();
            },
            child: const Text('Mantener este dispositivo'),
          ),
        ],
      );
    },
  );
}

class _BackupSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryBackupControllerProvider);

    // Listen for messages
    ref.listen(inventoryBackupControllerProvider, (previous, next) {
      if (next.lastSuccessMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.lastSuccessMessage!), backgroundColor: Colors.green),
        );
        ref.read(inventoryBackupControllerProvider.notifier).clearMessages();
      }
      if (next.lastErrorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.lastErrorMessage!), backgroundColor: Colors.red),
        );
        ref.read(inventoryBackupControllerProvider.notifier).clearMessages();
      }
    });

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.lastBackup != null) ...[
              Row(
                children: [
                  const Icon(Icons.backup_outlined, color: Colors.blueGrey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Último respaldo: ${_formatDate(state.lastBackup!.createdAt)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Items: ${state.lastBackup!.itemCount} | Origen: ${state.lastBackup!.reason}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isRestoring 
                          ? null 
                          : () => _showRestoreConfirmation(context, ref),
                      child: const Text('Restaurar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => ref.read(inventoryBackupControllerProvider.notifier).createManualBackup(),
                      child: const Text('Backup local'),
                    ),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.import_export, color: Colors.blue),
                title: const Text('Exportar / Importar archivo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Comparte o carga un archivo JSON de tu botiquín.', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => context.push('/export-import'),
              ),
            ] else ...[
              const Text(
                'Aún no tienes un respaldo local. Te recomendamos crear uno antes de sincronizar.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(inventoryBackupControllerProvider.notifier).createManualBackup(),
                  icon: const Icon(Icons.add_to_photos_outlined),
                  label: const Text('Crear respaldo local'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/export-import'),
                  icon: const Icon(Icons.import_export),
                  label: const Text('Exportar / Importar JSON'),
                ),
              ),
            ],
            if (state.isRestoring) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showRestoreConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: const Text(
          'Esto reemplazará tu inventario local actual por el último respaldo guardado. '
          '¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(inventoryBackupControllerProvider.notifier).restoreLastBackup();
            },
            child: const Text('Restaurar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}


class _SyncActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _SyncActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.teal.shade700),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      enabled: onTap != null,
    );
  }
}

class _ConflictResolutionBlock extends ConsumerWidget {
  const _ConflictResolutionBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventorySyncControllerProvider);
    final remote = state.pendingRemoteSnapshot;

    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.shade200, width: 2),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Text(
                  'Conflicto detectado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              state.conflictMessage ?? 'Hay cambios concurrentes en la nube.',
              style: const TextStyle(fontSize: 13),
            ),
            if (remote != null) ...[
              const SizedBox(height: 8),
              Text(
                'Versión remota: v${remote.version} | Modificado: ${_formatDate(remote.updatedAt)}',
                style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: state.isSyncing 
                      ? null 
                      : () => ref.read(inventorySyncControllerProvider.notifier).resolveConflictByDownloadingRemote(),
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar inventario remoto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: state.isSyncing 
                      ? null 
                      : () => _showForceUploadConfirmation(context, ref),
                  icon: const Icon(Icons.upload),
                  label: const Text('Sobrescribir nube con mis datos'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber.shade900,
                    side: BorderSide(color: Colors.amber.shade700),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: state.isSyncing 
                      ? null 
                      : () => ref.read(inventorySyncControllerProvider.notifier).dismissConflict(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showForceUploadConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobrescribir inventario remoto'),
        content: const Text(
          'Esto reemplazará permanentemente los cambios realizados desde otros dispositivos con los datos de este teléfono. '
          '¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(inventorySyncControllerProvider.notifier).resolveConflictByForceUploadingLocal();
            },
            child: const Text('Sobrescribir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
