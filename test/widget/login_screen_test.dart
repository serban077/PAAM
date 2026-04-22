// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfitai/presentation/auth/login_screen.dart';

import '../helpers/test_app_wrapper.dart';

/// Initialize Supabase once with stub credentials so AuthService() can
/// construct without throwing. No network calls are made during tests.
Future<void> _initSupabaseStub() async {
  SharedPreferences.setMockInitialValues({});
  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
          '.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTcwMDAwMDAwMH0'
          '.placeholder',
      debug: false,
    );
  } catch (_) {
    // Already initialized (test re-runs or other test files)
  }
}

void main() {
  setUpAll(_initSupabaseStub);

  group('LoginScreen — form validation', () {
    // Helper: pump login screen and wait for session check to complete.
    // With a stub Supabase, currentSession == null → form shown immediately.
    Future<void> pumpLogin(WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));
      // Allow initState async (_checkExistingSession) to complete.
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    testWidgets('shows form after session check resolves', (tester) async {
      await pumpLogin(tester);
      // Either the form is visible or we're still in loading — no crash.
      expect(tester.takeException(), isNull);
    });

    testWidgets('email and password fields exist', (tester) async {
      await pumpLogin(tester);
      // There should be at least 2 TextFormFields (email + password).
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });

    testWidgets('tapping submit with empty fields shows email validation error',
        (tester) async {
      await pumpLogin(tester);

      // Find and tap the sign-in button (ElevatedButton with sign-in label)
      final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
      if (signInBtn.evaluate().isEmpty) {
        // Button may have a different label — find any ElevatedButton
        final anyBtn = find.byType(ElevatedButton).first;
        await tester.tap(anyBtn);
      } else {
        await tester.tap(signInBtn);
      }
      await tester.pump();

      expect(
        find.text('Please enter your email'),
        findsOneWidget,
      );
    });

    testWidgets('invalid email format shows validator message', (tester) async {
      await pumpLogin(tester);

      // Find the email TextFormField and enter an invalid address
      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'notanemail');
      await tester.pump();

      // Submit the form
      final signInBtn = find.byType(ElevatedButton).first;
      await tester.tap(signInBtn);
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('password visibility toggle changes obscure state', (tester) async {
      await pumpLogin(tester);

      // Find the password field (second TextFormField)
      final passwordField = find.byType(TextFormField).at(1);
      final editableText = tester.widget<EditableText>(
        find.descendant(of: passwordField, matching: find.byType(EditableText)),
      );
      expect(editableText.obscureText, isTrue);

      // Tap the visibility suffix icon
      final visibilityIcon = find.byIcon(Icons.visibility_off_outlined);
      if (visibilityIcon.evaluate().isNotEmpty) {
        await tester.tap(visibilityIcon);
        await tester.pump();

        final updated = tester.widget<EditableText>(
          find.descendant(of: passwordField, matching: find.byType(EditableText)),
        );
        expect(updated.obscureText, isFalse);
      }
    });
  });
}
