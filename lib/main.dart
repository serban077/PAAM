import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:upgrader/upgrader.dart';

import 'core/app_export.dart';
import 'services/analytics_service.dart';
import 'services/supabase_service.dart';
import 'services/theme_service.dart';
import 'widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 0.2;
      options.environment = kDebugMode ? 'debug' : 'production';
      // Strip user identity from all events to prevent PII leakage
      options.beforeSend = (event, hint) => event.copyWith(user: null);
    },
    appRunner: () async {
      try {
        await initializeDateFormatting();
        await SupabaseService.initialize();
        await ThemeService.init();
        await AnalyticsService.instance.initialize();
        await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp]);

        bool hasShownError = false;
        ErrorWidget.builder = (FlutterErrorDetails details) {
          if (!hasShownError) {
            hasShownError = true;
            Future.delayed(
                const Duration(seconds: 5), () => hasShownError = false);
            return CustomErrorWidget(errorDetails: details);
          }
          return const SizedBox.shrink();
        };

        runApp(const MyApp());
      } catch (e, stack) {
        await Sentry.captureException(e,
            stackTrace: stack,
            hint: Hint.withMap({'context': 'app_initialization'}));
        debugPrint('Initialization failed: $e');
        runApp(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      'Application failed to start. Please restart.\nError: $e'),
                ),
              ),
            ),
          ),
        );
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeMode, child) {
        return Sizer(
          builder: (context, orientation, screenType) {
            return UpgradeAlert(
              upgrader: Upgrader(
                debugLogging: kDebugMode,
              ),
              child: MaterialApp(
                title: 'smartfitai',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(1.0)),
                    child: child!,
                  );
                },
                // 🚨 END CRITICAL SECTION
                debugShowCheckedModeBanner: false,
                routes: AppRoutes.routes,
                onGenerateRoute: AppRoutes.onGenerateRoute,
                initialRoute: AppRoutes.loginScreen,
                navigatorObservers: [SentryNavigatorObserver()],
              ),
            );
          },
        );
      },
    );
  }
}
