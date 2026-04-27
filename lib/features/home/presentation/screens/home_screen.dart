import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meds_v2/core/constants/app_strings.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_section_title.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppStrings.homeTitle,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                const SizedBox(width: 12),
                Expanded(
                  child: _SmallToolCard(
                    title: 'Admin',
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: () => context.push('/admin_review'),
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

  const _SmallToolCard({
    required this.title,
    required this.icon,
    required this.onTap,
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
