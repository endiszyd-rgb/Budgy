import 'package:flutter_test/flutter_test.dart';

import 'package:budzet_warsztatu/core/database/database.dart';
import 'package:budzet_warsztatu/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    final db = AppDatabase();
    await tester.pumpWidget(BudzetWarsztatuApp(db: db));
    await tester.pump();
  });
}
