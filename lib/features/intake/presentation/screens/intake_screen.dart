import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meds_v2/features/intake/application/providers/intake_providers.dart';
import 'package:smart_meds_v2/features/intake/application/states/intake_state.dart';
import 'package:smart_meds_v2/features/intake/domain/entities/intake_capture_result.dart';
import 'package:smart_meds_v2/features/catalog/domain/constants/catalog_constants.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_scaffold.dart';
import 'package:smart_meds_v2/shared/presentation/widgets/app_section_title.dart';

class IntakeScreen extends ConsumerWidget {
  const IntakeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(intakeControllerProvider);
    final controller = ref.read(intakeControllerProvider.notifier);

    return AppScaffold(
      title: 'Ingreso',
      body: _buildBody(context, state, controller),
    );
  }

  Widget _buildBody(
    BuildContext context,
    IntakeState state,
    IntakeController controller,
  ) {
    switch (state.status) {
      case IntakeStatus.idle:
        return _buildIdleState(controller);
      case IntakeStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case IntakeStatus.reviewing:
        return _buildReviewingState(context, state, controller);
      case IntakeStatus.confirmed:
        return _buildConfirmedState(context, state, controller);
      case IntakeStatus.error:
        return _buildErrorState(state, controller);
    }
  }

  Widget _buildIdleState(IntakeController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionTitle(
            title: 'Nuevo Ingreso',
            description:
                'Inicia una captura guiada o realiza una búsqueda manual para registrar un medicamento en tu botiquín.',
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => controller.startSimulatedCapture(source: IntakeSource.barcode),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Simular código conocido'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => controller.startSimulatedCapture(
              source: IntakeSource.barcode,
              forceFallback: true,
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Simular código desconocido'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.orange.shade100,
              foregroundColor: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => controller.startSimulatedCapture(source: IntakeSource.manualSearch),
            icon: const Icon(Icons.search),
            label: const Text('Búsqueda manual en catálogo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewingState(
    BuildContext context,
    IntakeState state,
    IntakeController controller,
  ) {
    final item = state.draftItem;
    if (item == null) return const SizedBox.shrink();

    final isDesconocido = item.catalogMedicationId == CatalogConstants.unknownId;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(
            title: 'Revisar Información',
            description: 'Verifica los datos antes de agregar al botiquín.',
          ),
          const SizedBox(height: 16),
          
          if (state.errorMessage != null && state.fieldErrors == null)
            _buildGeneralError(state.errorMessage!),

          _buildSourceBadge(state.source),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesconocido) ...[
                    const Text('Nombre del medicamento:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _DraftNameField(
                      initialName: item.name,
                      errorText: state.fieldErrors?['name'],
                      onNameChanged: controller.updateDraftName,
                    ),
                  ] else ...[
                    Text(
                      'Medicamento: ${item.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildCatalogStatus(isDesconocido),
                  const SizedBox(height: 24),
                  
                  // Expiration Date Section
                  const Text('Fecha de vencimiento:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.expirationDate.toString().split(' ')[0],
                        style: TextStyle(
                          fontSize: 16,
                          color: state.fieldErrors?['expirationDate'] != null ? Colors.red : null,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: item.expirationDate.isBefore(today) ? today : item.expirationDate,
                            firstDate: today,
                            lastDate: today.add(const Duration(days: 3650)),
                          );
                          if (date != null) {
                            controller.updateDraftExpiration(date);
                          }
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Cambiar'),
                      ),
                    ],
                  ),
                  if (state.fieldErrors?['expirationDate'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        state.fieldErrors!['expirationDate']!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    
                  const SizedBox(height: 24),
                  
                  // Quantity Section
                  const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: item.quantity > 1
                            ? () => controller.updateDraftQuantity(item.quantity - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: state.fieldErrors?['quantity'] != null ? Colors.red : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.updateDraftQuantity(item.quantity + 1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  if (state.fieldErrors?['quantity'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        state.fieldErrors!['quantity']!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.reset,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.confirmIntake,
                  child: const Text('Confirmar Registro'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(IntakeSource? source) {
    if (source == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            source == IntakeSource.barcode ? Icons.qr_code : Icons.search,
            color: Colors.blue.shade700,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            source == IntakeSource.barcode ? 'Origen: Escaneo' : 'Origen: Búsqueda',
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogStatus(bool isDesconocido) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDesconocido ? Colors.orange.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isDesconocido ? 'Medicamento no identificado' : 'Identificado en catálogo',
        style: TextStyle(
          color: isDesconocido ? Colors.orange.shade900 : Colors.green.shade900,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildConfirmedState(
    BuildContext context,
    IntakeState state,
    IntakeController controller,
  ) {
    final item = state.draftItem;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              '¡Agregado con éxito!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (item != null) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text('Cantidad: ${item.quantity} unidades'),
                      Text('Vencimiento: ${item.expirationDate.toString().split(' ')[0]}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ya puedes verlo en tu inventario.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                controller.reset();
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar otro medicamento'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                controller.reset();
                context.pop();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Ir al inventario'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(IntakeState state, IntakeController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 80),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Ocurrió un error en el flujo.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: controller.dismissError,
              child: const Text('Volver a revisar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftNameField extends StatefulWidget {
  final String initialName;
  final String? errorText;
  final ValueChanged<String> onNameChanged;

  const _DraftNameField({
    required this.initialName,
    this.errorText,
    required this.onNameChanged,
  });

  @override
  State<_DraftNameField> createState() => _DraftNameFieldState();
}

class _DraftNameFieldState extends State<_DraftNameField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void didUpdateWidget(_DraftNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialName != widget.initialName && _controller.text != widget.initialName) {
      _controller.text = widget.initialName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: 'Ingresa el nombre',
        isDense: true,
        errorText: widget.errorText,
      ),
      onChanged: widget.onNameChanged,
    );
  }
}