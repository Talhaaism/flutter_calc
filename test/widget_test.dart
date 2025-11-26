import 'package:flutter_test/flutter_test.dart';
import 'package:calculator/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AreaApp());

    // Just verify it builds without crashing
    expect(find.byType(AreaApp), findsOneWidget);
  });
}
