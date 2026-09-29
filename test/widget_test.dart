import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/app.dart';

void main() {
  testWidgets('App smoke test - renders Ochanya Gili app', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OchanyaGiliApp(),
      ),
    );

    // Initial frame builds
    await tester.pumpAndSettle();

    // Verify brand title is displayed
    expect(find.text('OCHANYA GILI'), findsWidgets);
  });
}
