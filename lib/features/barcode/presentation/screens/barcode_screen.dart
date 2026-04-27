import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_section_title.dart';

class BarcodeScreen extends StatelessWidget {
  const BarcodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Escaneo de Código',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppSectionTitle(
                title: 'Próximamente',
                description:
                    'El escaneo real por cámara se implementará en una fase futura. '
                    'Por ahora, utiliza el flujo unificado de ingreso.',
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.push('/intake'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ir al flujo de ingreso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}