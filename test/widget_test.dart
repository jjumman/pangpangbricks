// Basic widget test for PangPang Bricks

import 'package:flutter_test/flutter_test.dart';
import 'package:pangpangbricks/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PangPangBricksApp());

    // Verify that the app launches without errors
    expect(find.byType(PangPangBricksApp), findsOneWidget);
  });
}
