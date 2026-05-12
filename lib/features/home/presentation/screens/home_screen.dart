import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meds_v2/core/constants/app_strings.dart';
import 'package:smart_meds_v2/features/auth/application/providers/auth_providers.dart';
import 'package:smart_meds_v2/features/inventory/application/providers/inventory_sync_providers.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_section_title.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: AppStrings.homeTitle,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _UserSessionPanel(),
            const SizedBox(height: 16),
            const AppSectionTitle(
              title: 'Panel Principal',
              description: 'Gestiona tu botiquín de forma inteligente.',
            ),
            const SizedBox(height: 24),
            _DashboardCard(
              title: 'Ingresar Medicamento',
              description: 'Escanea o busca un nuevo fármaco.',
              icon: Icons.add_circle_outline,
              color: Colors.blue,
              onTap: () => context.push('/intake'),
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              title: 'Mi Inventario',
              description: 'Ver stock, vencimientos y alertas.',
              icon: Icons.inventory_2_outlined,
              color: Colors.green,
              onTap: () => context.push('/inventory'),
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              title: 'Catálogo Global',
              description: 'Consulta información de medicamentos.',
              icon: Icons.auto_stories_outlined,
              color: Colors.orange,
              onTap: () => context.push('/catalog'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Herramientas Avanzadas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SmallToolCard(
                    title: 'OCR',
                    icon: Icons.document_scanner_outlined,
                    onTap: () => context.push('/ocr'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SmallToolCard(
                    title: 'Admin',
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: () {
                      if (ref.read(authControllerProvider).isAuthenticated) {
                        context.push('/admin_review');
                      } else {
                        context.push('/login');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SmallToolCard(
                    title: 'Sync',
                    icon: Icons.sync_rounded,
                    isSyncing: ref.watch(inventorySyncControllerProvider).isSyncing,
                    onTap: () {
                      if (ref.read(authControllerProvider).isAuthenticated) {
                        context.push('/settings');
                      } else {
                        context.push('/login');
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
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
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSyncing;

  const _SmallToolCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              if (isSyncing)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, color: Colors.blueGrey),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserSessionPanel extends ConsumerWidget {
  const _UserSessionPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final syncState = ref.watch(inventorySyncControllerProvider);
    final lastSyncedAt = ref.watch(lastSyncedAtProvider);

    if (authState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final isAuthenticated = authState.isAuthenticated;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAuthenticated
              ? [Colors.teal.shade50, Colors.teal.shade100.withAlpha(100)]
              : [Colors.orange.shade50, Colors.orange.shade100.withAlpha(100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAuthenticated ? Colors.teal.shade200 : Colors.orange.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAuthenticated ? Colors.teal : Colors.orange).withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(150),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAuthenticated ? Icons.person_rounded : Icons.person_outline_rounded,
                    color: isAuthenticated ? Colors.teal.shade700 : Colors.orange.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAuthenticated ? '¡Hola de nuevo!' : 'Bienvenido',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isAuthenticated ? Colors.teal.shade800 : Colors.orange.shade800,
                        ),
                      ),
                      Text(
                        isAuthenticated
                            ? (authState.session?.email ?? "Usuario")
                            : 'Inicia sesión para sincronizar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isAuthenticated ? Colors.teal.shade900 : Colors.orange.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (isAuthenticated) {
                      ref.read(authControllerProvider.notifier).logout();
                    } else {
                      context.push('/login');
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isAuthenticated ? Colors.teal.shade700 : Colors.orange.shade700,
                    backgroundColor: Colors.white.withAlpha(100),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isAuthenticated ? 'Salir' : 'Entrar',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (isAuthenticated) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Icon(
                    syncState.isSyncing ? Icons.sync : Icons.cloud_done_outlined,
                    size: 16,
                    color: syncState.isSyncing ? Colors.blue : Colors.teal.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          syncState.isSyncing ? 'Sincronizando...' : 'Datos sincronizados',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: syncState.isSyncing ? Colors.blue.shade700 : Colors.teal.shade700,
                          ),
                        ),
                        lastSyncedAt.when(
                          data: (date) => Text(
                            date != null
                                ? 'Última vez: ${_formatDateTime(date)}'
                                : 'Nunca sincronizado',
                            style: TextStyle(fontSize: 11, color: Colors.teal.shade600),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => Text(
                            'Error al obtener fecha sync',
                            style: TextStyle(fontSize: 11, color: Colors.red.shade400),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!syncState.isSyncing)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => ref.read(inventorySyncControllerProvider.notifier).syncToRemote(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      color: Colors.teal.shade700,
                      tooltip: 'Sincronizar ahora',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'ahora mismo';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
