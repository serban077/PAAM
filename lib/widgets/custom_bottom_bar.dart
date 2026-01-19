import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom bottom navigation bar widget for the fitness application.
/// Implements bottom-heavy interaction design with thumb-reachable navigation.
///
/// This widget is parameterized and reusable across different implementations.
/// Navigation logic should be handled by the parent widget.
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when a navigation item is tapped
  final Function(int) onTap;

  /// Optional custom background color
  final Color? backgroundColor;

  /// Optional custom selected item color
  final Color? selectedItemColor;

  /// Optional custom unselected item color
  final Color? unselectedItemColor;

  /// Optional elevation
  final double? elevation;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        // Provide haptic feedback for better user experience
        HapticFeedback.lightImpact();
        onTap(index);
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      selectedItemColor: selectedItemColor ?? colorScheme.primary,
      unselectedItemColor:
          unselectedItemColor ??
          theme.bottomNavigationBarTheme.unselectedItemColor,
      elevation: elevation ?? 8.0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        // Dashboard/Home - Central hub with personalized greeting
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined, size: 24),
          activeIcon: const Icon(Icons.home, size: 24),
          label: 'Acasă',
          tooltip: 'Pagina principală',
        ),

        // Workouts - Exercise library and active workout sessions
        BottomNavigationBarItem(
          icon: const Icon(Icons.fitness_center_outlined, size: 24),
          activeIcon: const Icon(Icons.fitness_center, size: 24),
          label: 'Antrenamente',
          tooltip: 'Antrenamente și exerciții',
        ),

        // Nutrition - Meal planning and macro tracking
        BottomNavigationBarItem(
          icon: const Icon(Icons.restaurant_menu_outlined, size: 24),
          activeIcon: const Icon(Icons.restaurant_menu, size: 24),
          label: 'Nutriție',
          tooltip: 'Planificare mese',
        ),

        // Progress - Photo and measurement tracking
        BottomNavigationBarItem(
          icon: const Icon(Icons.trending_up_outlined, size: 24),
          activeIcon: const Icon(Icons.trending_up, size: 24),
          label: 'Progres',
          tooltip: 'Urmărire progres',
        ),

        // Profile - Settings and preferences
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline, size: 24),
          activeIcon: const Icon(Icons.person, size: 24),
          label: 'Profil',
          tooltip: 'Setări profil',
        ),
      ],
    );
  }
}

/// Navigation item data model for custom bottom bar
class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final String? tooltip;

  const BottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.tooltip,
  });
}

/// Predefined navigation items matching the Mobile Navigation Hierarchy
class BottomNavItems {
  BottomNavItems._();

  static const List<BottomNavItem> items = [
    BottomNavItem(
      label: 'Acasă',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: '/main-dashboard',
      tooltip: 'Pagina principală',
    ),
    BottomNavItem(
      label: 'Antrenamente',
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      route: '/exercise-library',
      tooltip: 'Antrenamente și exerciții',
    ),
    BottomNavItem(
      label: 'Nutriție',
      icon: Icons.restaurant_menu_outlined,
      activeIcon: Icons.restaurant_menu,
      route: '/nutrition-planning',
      tooltip: 'Planificare mese',
    ),
    BottomNavItem(
      label: 'Progres',
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up,
      route: '/progress-tracking',
      tooltip: 'Urmărire progres',
    ),
    BottomNavItem(
      label: 'Profil',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: '/user-profile',
      tooltip: 'Setări profil',
    ),
  ];
}
