import 'package:flutter_test/flutter_test.dart';
import 'package:flash/main.dart';

void main() {
  testWidgets('Flash app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlashApp());
    expect(find.text('الفلاش'), findsOneWidget);
  });
}
