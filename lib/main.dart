import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sizer/sizer.dart';

import 'core/app_export.dart';
import 'services/supabase_service.dart';
import 'widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize services first
    await initializeDateFormatting();
    await SupabaseService.initialize();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Setup custom error handling
    bool hasShownError = false;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (!hasShownError) {
        hasShownError = true;
        Future.delayed(const Duration(seconds: 5), () {
          hasShownError = false;
        });
        return CustomErrorWidget(errorDetails: details);
      }
      return const SizedBox.shrink();
    };

    // If all initializations are successful, run the app
    runApp(const MyApp());
  } catch (e) {
    // If any initialization fails, show a fallback error screen
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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'smartfitai',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
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
          initialRoute: AppRoutes.authenticationOnboardingFlow,
        );
      },
    );
  }
}
