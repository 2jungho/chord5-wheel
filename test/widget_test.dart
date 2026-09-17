import 'package:flutter/material.dart';
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

  testWidgets('Desktop Dashboard: Left Dock and Right Workspace bottom lines match 1:1', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Find Left Dock container (width: 380)
    final leftDockFinder = find.byWidgetPredicate((widget) =>
        widget is SizedBox && widget.width == 380);
    expect(leftDockFinder, findsOneWidget);

    final leftBox = tester.getRect(leftDockFinder);

    // Get the right Column inside the Row
    final intrinsicHeightFinder = find.byType(IntrinsicHeight).first;
    final rowRect = tester.getRect(intrinsicHeightFinder);

    // Left dock height must equal Row height
    expect(leftBox.height, equals(rowRect.height));
    expect(leftBox.bottom, equals(rowRect.bottom));

    // Test on 1200 width (medium laptop)
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump(const Duration(milliseconds: 300));
    final leftBox1200 = tester.getRect(leftDockFinder);
    final rowRect1200 = tester.getRect(intrinsicHeightFinder);
    expect(leftBox1200.bottom, equals(rowRect1200.bottom));
  });

  testWidgets('AppHeader: Brand title and subtitles remain consistent across all 3 tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Initial tab: Explorer
    expect(find.text('Guitar & Theory'), findsOneWidget);
    expect(find.textContaining('Circle of Fifths'), findsOneWidget);

    // Switch to Chord Analyzer (generator)
    await tester.tap(find.text('코드 분석'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Guitar & Theory'), findsOneWidget);
    expect(find.textContaining('Chord Analyzer'), findsOneWidget);

    // Switch to Progression Studio (studio)
    await tester.tap(find.text('코드진행'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Guitar & Theory'), findsOneWidget);
    expect(find.textContaining('Chord Progression Studio'), findsOneWidget);
  });
}
