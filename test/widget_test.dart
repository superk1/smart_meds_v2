import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meds_v2/main.dart' as app;

void main() {
  testWidgets('Initial screen loads correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await app.main();
    await tester.pumpAndSettle();

    expect(find.text('Panel Principal'), findsOneWidget);
    expect(find.text('Catálogo Global'), findsOneWidget);
  });
}
