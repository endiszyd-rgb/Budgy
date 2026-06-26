import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:budzet_warsztatu/core/database/database.dart';
import 'package:budzet_warsztatu/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Layout jest projektowany pod tablet 12" — używamy realistycznego,
    // szerokiego viewportu, żeby nie testować nieobsługiwanych wąskich szerokości.
    tester.view.physicalSize = const Size(2000, 1350);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final db = AppDatabase();
    await tester.pumpWidget(BudzetWarsztatuApp(db: db));
    await tester.pump();
  });
}
