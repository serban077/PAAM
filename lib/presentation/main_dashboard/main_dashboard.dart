import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/custom_bottom_bar.dart';
import './main_dashboard_initial_page.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  MainDashboardState createState() => MainDashboardState();
}

class MainDashboardState extends State<MainDashboard> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int currentIndex = 0;

  // ALL CustomBottomBar routes in EXACT order matching CustomBottomBar items
  final List<String> routes = [
    '/main-dashboard',
    '/exercise-library',
    '/nutrition-planning',
    '/progress-tracking',
    '/user-profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        initialRoute: '/main-dashboard',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/main-dashboard':
            case '/':
              return MaterialPageRoute(
                builder: (context) => const MainDashboardInitialPage(),
                settings: settings,
              );
            default:
              // Check AppRoutes.routes for all other routes
              if (AppRoutes.routes.containsKey(settings.name)) {
                return MaterialPageRoute(
                  builder: AppRoutes.routes[settings.name]!,
                  settings: settings,
                );
              }
              return null;
          }
        },
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // For the routes that are not in the AppRoutes.routes, do not navigate to them.
          if (!AppRoutes.routes.containsKey(routes[index])) {
            return;
          }
          if (currentIndex != index) {
            setState(() => currentIndex = index);
            navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
      ),
    );
  }
}
