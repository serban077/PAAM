import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfitai/theme/app_theme.dart';
import 'package:smartfitai/widgets/custom_app_bar.dart';

import '../helpers/test_app_wrapper.dart';

void main() {
  group('CustomAppBar goldens', () {
    testWidgets('light — title only', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(appBar: CustomAppBar(title: 'Dashboard')),
      );
      await expectLater(
        find.byType(CustomAppBar),
        matchesGoldenFile('goldens/app_bar_light_title_only.png'),
      );
    });

    testWidgets('light — title + subtitle', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(appBar: CustomAppBar(title: 'Workouts', subtitle: 'This week')),
      );
      await expectLater(
        find.byType(CustomAppBar),
        matchesGoldenFile('goldens/app_bar_light_subtitle.png'),
      );
    });

    testWidgets('light — title + back button', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(
          appBar: CustomAppBar(title: 'Exercise Detail', showBackButton: true),
        ),
      );
      await expectLater(
        find.byType(CustomAppBar),
        matchesGoldenFile('goldens/app_bar_light_back.png'),
      );
    });

    testWidgets('dark — title only', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(appBar: CustomAppBar(title: 'Dashboard')),
        theme: AppTheme.darkTheme,
      );
      await expectLater(
        find.byType(CustomAppBar),
        matchesGoldenFile('goldens/app_bar_dark_title_only.png'),
      );
    });

    testWidgets('dark — title + subtitle', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(appBar: CustomAppBar(title: 'Workouts', subtitle: 'This week')),
        theme: AppTheme.darkTheme,
      );
      await expectLater(
        find.byType(CustomAppBar),
        matchesGoldenFile('goldens/app_bar_dark_subtitle.png'),
      );
    });

    testWidgets('dark — title + back button', (tester) async {
      await pumpGoldenWidget(
        tester,
        Scaffold(
          appBar: CustomAppBar(title: 'Exercise Detail', showBackButton: true),
        ),
        theme: AppTheme.darkTheme,
      );
      await expectLater(
        find.byType(CustomAppBar),
        matchesGoldenFile('goldens/app_bar_dark_back.png'),
      );
    });
  });
}
