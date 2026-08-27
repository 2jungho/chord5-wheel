import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/main.dart';

void main() {
  testWidgets('App smoke test - initializes MyApp', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
