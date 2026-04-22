import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfitai/theme/app_theme.dart';
import 'package:smartfitai/widgets/custom_bottom_bar.dart';

import '../helpers/test_app_wrapper.dart';

void main() {
  group('CustomBottomBar goldens', () {
    testWidgets('light theme — tab 0 (Home)', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(
          bottomNavigationBar: CustomBottomBar(currentIndex: 0, onTap: (_) {}),
        ),
      );
      await expectLater(
        find.byType(CustomBottomBar),
        matchesGoldenFile('goldens/bottom_bar_light_home.png'),
      );
    });

    testWidgets('light theme — tab 2 (Nutrition)', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(
          bottomNavigationBar: CustomBottomBar(currentIndex: 2, onTap: (_) {}),
        ),
      );
      await expectLater(
        find.byType(CustomBottomBar),
        matchesGoldenFile('goldens/bottom_bar_light_nutrition.png'),
      );
    });

    testWidgets('light theme — tab 4 (Profile)', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(
          bottomNavigationBar: CustomBottomBar(currentIndex: 4, onTap: (_) {}),
        ),
      );
      await expectLater(
        find.byType(CustomBottomBar),
        matchesGoldenFile('goldens/bottom_bar_light_profile.png'),
      );
    });

    testWidgets('dark theme — tab 0 (Home)', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(
          bottomNavigationBar: CustomBottomBar(currentIndex: 0, onTap: (_) {}),
        ),
        theme: AppTheme.darkTheme,
      );
      await expectLater(
        find.byType(CustomBottomBar),
        matchesGoldenFile('goldens/bottom_bar_dark_home.png'),
      );
    });

    testWidgets('dark theme — tab 2 (Nutrition)', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(
          bottomNavigationBar: CustomBottomBar(currentIndex: 2, onTap: (_) {}),
        ),
        theme: AppTheme.darkTheme,
      );
      await expectLater(
        find.byType(CustomBottomBar),
        matchesGoldenFile('goldens/bottom_bar_dark_nutrition.png'),
      );
    });

    testWidgets('dark theme — tab 4 (Profile)', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(
          bottomNavigationBar: CustomBottomBar(currentIndex: 4, onTap: (_) {}),
        ),
        theme: AppTheme.darkTheme,
      );
      await expectLater(
        find.byType(CustomBottomBar),
        matchesGoldenFile('goldens/bottom_bar_dark_profile.png'),
      );
    });
  });
}
