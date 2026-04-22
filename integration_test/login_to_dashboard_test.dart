// Patrol integration test stub — requires a running Android emulator/device.
// Run with: flutter test integration_test/login_to_dashboard_test.dart
//           (after patrol setup: https://patrol.leancode.co/getting-started)
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Login → Dashboard smoke test', () {
    testWidgets('stub — deferred until Patrol emulator CI is set up', (tester) async {
      markTestSkipped('Patrol integration tests require an Android emulator. '
          'Set up Patrol CI job to enable this test.');
    });
  });
}
