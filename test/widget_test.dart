import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/app/app.dart';

void main() {
  testWidgets('shows the initial splash route', (WidgetTester tester) async {
    await tester.pumpWidget(const VittaApp());

    expect(find.text('Vitta'), findsWidgets);
    expect(find.text('Tela inicial do aplicativo.'), findsOneWidget);
  });
}
