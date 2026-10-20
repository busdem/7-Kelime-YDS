import 'package:flutter_test/flutter_test.dart';

import 'package:yds_app/main.dart';

void main() {
  testWidgets('YdsApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const YdsApp());
    expect(find.text('YDS Kelime Rehberi'), findsOneWidget);
  });
}
