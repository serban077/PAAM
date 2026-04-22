import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfitai/widgets/custom_bottom_bar.dart';

import '../helpers/test_app_wrapper.dart';

void main() {
  group('CustomBottomBar', () {
    testWidgets('renders 5 navigation items', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            bottomNavigationBar: CustomBottomBar(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      // 5 labels
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('initial tab index is reflected', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            bottomNavigationBar: CustomBottomBar(
              currentIndex: 2,
              onTap: (_) {},
            ),
          ),
        ),
      );
      final bar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bar.currentIndex, equals(2));
    });

    testWidgets('onTap callback fires with correct index', (tester) async {
      int tappedIndex = -1;
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            bottomNavigationBar: CustomBottomBar(
              currentIndex: 0,
              onTap: (i) => tappedIndex = i,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Nutrition'));
      await tester.pump();
      expect(tappedIndex, equals(2));
    });

    testWidgets('supports dark theme without overflow', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            bottomNavigationBar: CustomBottomBar(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
          theme: const MaterialApp().darkTheme ??
              ThemeData(brightness: Brightness.dark),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
