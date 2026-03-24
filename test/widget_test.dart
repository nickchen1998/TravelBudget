import 'package:flutter_test/flutter_test.dart';
import 'package:travel_budget/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const TravelBudgetApp());
    expect(find.text('旅算'), findsOneWidget);
  });
}
