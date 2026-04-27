import 'package:flutter/material.dart';
import 'package:smart_meds_v2/core/constants/app_strings.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_section_title.dart';

class OcrScreen extends StatelessWidget {
  const OcrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: AppStrings.ocrTitle,
      body: Center(
        child: AppSectionTitle(
          title: AppStrings.ocrTitle,
          description: 'Pantalla para leer texto de cajas de medicamentos localmente.',
        ),
      ),
    );
  }
}
