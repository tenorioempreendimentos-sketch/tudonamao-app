import 'package:flutter_test/flutter_test.dart';
import 'package:tudonamao/main.dart';

void main() {
  testWidgets('TudoNaMao App smoke test', (WidgetTester tester) async {
    expect(find.byType(TudoNaMaoApp), findsNothing);
  });
}
