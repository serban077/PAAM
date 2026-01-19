import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom app bar widget for the fitness application.
/// Implements clean, minimal design with contextual actions.
///
/// This widget provides a consistent app bar experience across the application
/// with support for various configurations and actions.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text to display
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Whether to show the back button
  final bool showBackButton;

  /// Custom leading widget (overrides back button)
  final Widget? leading;

  /// List of action widgets
  final List<Widget>? actions;

  /// Optional custom background color
  final Color? backgroundColor;

  /// Optional custom foreground color
  final Color? foregroundColor;

  /// Whether to center the title
  final bool centerTitle;

  /// Optional elevation
  final double? elevation;

  /// Optional bottom widget (like TabBar)
  final PreferredSizeWidget? bottom;

  /// Custom back button callback
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = false,
    this.elevation,
    this.bottom,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: subtitle != null
          ? Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.appBarTheme.titleTextStyle),
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        foregroundColor?.withValues(alpha: 0.7) ??
                        theme.appBarTheme.foregroundColor?.withValues(
                          alpha: 0.7,
                        ),
                  ),
                ),
              ],
            )
          : Text(title),
      leading:
          leading ??
          (showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (onBackPressed != null) {
                      onBackPressed!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  tooltip: 'Înapoi',
                )
              : null),
      actions: actions,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      centerTitle: centerTitle,
      elevation: elevation ?? theme.appBarTheme.elevation,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

/// Variant of CustomAppBar with search functionality
class CustomSearchAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Hint text for search field
  final String hintText;

  /// Search query callback
  final ValueChanged<String>? onSearchChanged;

  /// Search submit callback
  final ValueChanged<String>? onSearchSubmitted;

  /// Optional leading widget
  final Widget? leading;

  /// List of action widgets
  final List<Widget>? actions;

  /// Optional custom background color
  final Color? backgroundColor;

  /// Optional custom foreground color
  final Color? foregroundColor;

  /// Optional elevation
  final double? elevation;

  /// Text editing controller
  final TextEditingController? controller;

  /// Auto focus on search field
  final bool autofocus;

  const CustomSearchAppBar({
    super.key,
    this.hintText = 'Caută...',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.controller,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: leading,
      title: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onSearchChanged,
        onSubmitted: onSearchSubmitted,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: foregroundColor ?? theme.appBarTheme.foregroundColor,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: (foregroundColor ?? theme.appBarTheme.foregroundColor)
                ?.withValues(alpha: 0.6),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      actions: actions,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      elevation: elevation ?? theme.appBarTheme.elevation,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Variant of CustomAppBar with workout timer display
class CustomWorkoutAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Workout title
  final String title;

  /// Current workout time
  final String time;

  /// Whether workout is paused
  final bool isPaused;

  /// Pause/Resume callback
  final VoidCallback? onPauseResume;

  /// Stop workout callback
  final VoidCallback? onStop;

  /// Optional custom background color
  final Color? backgroundColor;

  /// Optional custom foreground color
  final Color? foregroundColor;

  const CustomWorkoutAppBar({
    super.key,
    required this.title,
    required this.time,
    this.isPaused = false,
    this.onPauseResume,
    this.onStop,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: theme.appBarTheme.titleTextStyle),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPaused ? Icons.pause_circle_outline : Icons.timer_outlined,
                size: 16,
                color:
                    foregroundColor?.withValues(alpha: 0.7) ??
                    theme.appBarTheme.foregroundColor?.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                time,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      foregroundColor?.withValues(alpha: 0.7) ??
                      theme.appBarTheme.foregroundColor?.withValues(alpha: 0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (onStop != null) {
            onStop!();
          } else {
            Navigator.of(context).pop();
          }
        },
        tooltip: 'Închide antrenament',
      ),
      actions: [
        if (onPauseResume != null)
          IconButton(
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () {
              HapticFeedback.lightImpact();
              onPauseResume!();
            },
            tooltip: isPaused ? 'Reia' : 'Pauză',
          ),
        const SizedBox(width: 8),
      ],
      backgroundColor: backgroundColor ?? colorScheme.primary,
      foregroundColor: foregroundColor ?? colorScheme.onPrimary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
