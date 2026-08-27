import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/main.dart';
import 'package:guitar_theory_app/utils/app_theme.dart';

void main() {
  testWidgets('App smoke test - initializes MyApp and tests theme preset availability', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MyApp), findsOneWidget);

    // Verify all 5 theme presets exist and generate themes without error
    for (final preset in AppThemePreset.values) {
      final theme = AppTheme.getTheme(preset);
      expect(theme, isNotNull);
      final gradient = AppTheme.getBackgroundGradient(preset);
      expect(gradient.length, greaterThanOrEqualTo(2));
    }
  });
}
