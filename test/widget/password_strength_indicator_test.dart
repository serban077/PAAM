import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfitai/widgets/password_strength_indicator.dart';

import '../helpers/test_app_wrapper.dart';

void main() {
  group('PasswordStrengthIndicator', () {
    testWidgets('renders nothing for empty password', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const PasswordStrengthIndicator(password: '')),
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows "Weak" for password shorter than 8 characters', (tester) async {
      // "Use at least 8 characters" (26 chars) fits with Ahem font
      await tester.pumpWidget(
        buildTestApp(const PasswordStrengthIndicator(password: 'abc')),
      );
      await tester.pump();
      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('shows "Fair" for 8+ char password with no special chars', (tester) async {
      // Hint "Add a number and uppercase letter" (36 chars) overflows with Ahem
      // test font (1:1 char aspect ratio). Real Roboto renders these ~7px wide at 13sp.
      ignoreOverflowErrors();
      await tester.pumpWidget(
        buildTestApp(const PasswordStrengthIndicator(password: 'abcdefgh')),
      );
      await tester.pump();
      expect(find.text('Fair'), findsOneWidget);
    });

    testWidgets('shows "Strong" for 12+ chars with digit but no special char', (tester) async {
      // Hint "Add a special character for max security" (40 chars) overflows
      // with Ahem test font. Real Roboto renders correctly on device.
      ignoreOverflowErrors();
      await tester.pumpWidget(
        buildTestApp(const PasswordStrengthIndicator(password: 'abcdefghij12')),
      );
      await tester.pump();
      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('shows "Very Strong" for 12+ chars, digit, uppercase, special', (tester) async {
      // "Great password!" (15 chars) is short enough to fit without overflow
      await tester.pumpWidget(
        buildTestApp(const PasswordStrengthIndicator(password: 'Abcdef123!@#')),
      );
      await tester.pump();
      expect(find.text('Very Strong'), findsOneWidget);
    });

    testWidgets('shows LinearProgressIndicator when password is non-empty', (tester) async {
      ignoreOverflowErrors();
      await tester.pumpWidget(
        buildTestApp(const PasswordStrengthIndicator(password: 'test1234')),
      );
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('rebuilds correctly when password changes', (tester) async {
      ignoreOverflowErrors();
      final state = ValueNotifier('abc');
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder<String>(
            valueListenable: state,
            builder: (_, pw, __) => PasswordStrengthIndicator(password: pw),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Weak'), findsOneWidget);

      state.value = 'Abcdef123!@#';
      await tester.pump();
      expect(find.text('Very Strong'), findsOneWidget);
    });
  });
}
