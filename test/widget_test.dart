import 'package:flutter_test/flutter_test.dart';
import 'package:gbaki_ensea/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const GbakiEnseaApp());
    expect(find.byType(GbakiEnseaApp), findsOneWidget);
  });
}
