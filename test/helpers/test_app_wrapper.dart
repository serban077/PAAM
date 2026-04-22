import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:smartfitai/theme/app_theme.dart';

/// Wraps [child] in a Sizer + MaterialApp with SmartFitAI themes.
/// Required for any widget/golden test that uses `.h`, `.w`, or `.sp`.
Widget buildTestApp(Widget child, {ThemeData? theme}) {
  return Sizer(
    builder: (_, __, ___) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ?? AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

/// Sets the test viewport to 390×844 logical pixels (iPhone 14 equivalent)
/// so Sizer computes `.sp` values that match real phone rendering.
/// Call this at the start of any testWidgets that uses Sizer-scaled text.
void setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Suppresses RenderFlex overflow errors for the duration of one test.
///
/// Flutter widget tests render with the Ahem font, where every character is
/// a perfect 1em × 1em square. Proportional hint text that fits real devices
/// overflows in tests because character widths are ≈2× what Roboto renders.
/// Use this when the test verifies string content, not layout dimensions.
void ignoreOverflowErrors() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.library == 'rendering library' &&
        details.exception.toString().contains('overflowed')) {
      return;
    }
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
}

/// Pumps [child] at an iPhone-14-equivalent logical resolution and
/// registers a teardown to reset the view size.
/// Use this for all golden tests so PNGs are generated at a stable size.
Future<void> pumpGoldenWidget(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(buildTestApp(child, theme: theme));
  await tester.pump();
}
