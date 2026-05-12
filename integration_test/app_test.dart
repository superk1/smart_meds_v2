import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_meds_v2/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de Integración - Smart Meds V2', () {
    testWidgets('Flujo principal: Home -> Inventario -> Detalle', (tester) async {
      // 1. Iniciar App
      await app.main();
      await tester.pumpAndSettle();

      // 2. Verificar que estamos en Home
      expect(find.text('Smart Meds'), findsOneWidget);
      expect(find.text('Botiquín'), findsOneWidget);

      // 3. Navegar a Inventario
      final inventoryCard = find.text('Botiquín');
      await tester.tap(inventoryCard);
      await tester.pumpAndSettle();

      // 4. Verificar que estamos en Inventario
      expect(find.text('Inventario'), findsAtLeastNWidgets(1));
      
      // El inventario inicial tiene Paracetamol e Ibuprofeno en el FakeRepository
      expect(find.text('Paracetamol 500mg'), findsOneWidget);
      expect(find.text('Ibuprofeno 400mg'), findsOneWidget);

      // 5. Ver detalle de un item
      await tester.tap(find.text('Paracetamol 500mg'));
      await tester.pumpAndSettle();

      // 6. Verificar pantalla de detalle
      expect(find.text('Detalle del Medicamento'), findsOneWidget);
      expect(find.text('Paracetamol 500mg'), findsAtLeastNWidgets(1));
      expect(find.text('Información General'), findsOneWidget);
    });
  });
}
