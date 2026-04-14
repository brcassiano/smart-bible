import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bible/app.dart';

void main() {
  testWidgets('App renders home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartBibleApp(),
      ),
    );

    // Verify app title is displayed
    expect(find.text('Smart Bible'), findsWidgets);
  });
}
