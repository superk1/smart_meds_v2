import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meds_v2/main.dart' as app;

void main() {
  testWidgets('Initial screen loads correctly', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a Smart Med V2'), findsOneWidget);
    expect(find.text('Catálogo Global'), findsOneWidget);
  });
}
