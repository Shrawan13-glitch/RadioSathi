import 'package:flutter_test/flutter_test.dart';

import 'package:radio_sathi/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RadioSathiApp());
    expect(find.text('Radio Sathi'), findsOneWidget);
  });
}