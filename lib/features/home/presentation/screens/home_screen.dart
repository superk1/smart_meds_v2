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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppSectionTitle(
              title: 'Bienvenido a Smart Med V2',
              description: 'Dashboard principal. Aquí irán los accesos rápidos.',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/catalog'),
              child: const Text('Catálogo Global'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/inventory'),
              child: const Text('Mi Inventario'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/intake'),
              child: const Text('Ingresar Medicamento'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/ocr'),
              child: const Text('Lectura OCR'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/admin_review'),
              child: const Text('Admin - Revisiones'),
            ),
          ],
        ),
      ),
    );
  }
}
