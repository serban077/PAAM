import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/body_measurements_card.dart';
import './widgets/photo_progress_widget.dart';
import './widgets/real_workout_stats_widget.dart';
import './widgets/weekly_calendar_widget.dart';
import './widgets/weight_progress_card.dart';
import '../../routes/app_routes.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  Key _calendarKey = UniqueKey();
  bool _isLoading = true;
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      await SupabaseService.instance.client
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _refreshCount++;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    await _loadUserProfile();
    if (mounted) {
      setState(() => _calendarKey = UniqueKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: _buildSkeleton(theme),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
            onRefresh: _refresh,
            color: theme.colorScheme.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(theme, isDark),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      WeeklyCalendarWidget(
                        key: _calendarKey,
                        onSessionSelected: (sessionId) async {
                          final result = await Navigator.pushNamed(
                            context,
                            AppRoutes.workoutDetail,
                            arguments: {'sessionId': sessionId},
                          );
                          if (result == true) {
                            setState(() => _calendarKey = UniqueKey());
                          }
                        },
                      ),
                      SizedBox(height: 2.5.h),
                      const WeightProgressCard(),
                      SizedBox(height: 2.5.h),
                      const RealWorkoutStatsWidget(),
                      SizedBox(height: 2.5.h),
                      _buildSectionHeader(theme, 'Body Measurements', 'straighten'),
                      SizedBox(height: 1.5.h),
                      const BodyMeasurementsCard(),
                      SizedBox(height: 2.5.h),
                      _buildSectionHeader(theme, 'Photo Progress', 'photo_camera'),
                      SizedBox(height: 1.5.h),
                      const PhotoProgressWidget(),
                      SizedBox(height: 4.h),
                    ]),
                  ),
                ),
              ],
            ),
          )
          .animate(key: ValueKey(_refreshCount))
          .fade(duration: 500.ms, curve: Curves.easeOut)
          .slideY(begin: 0.06, end: 0, duration: 500.ms, curve: Curves.easeOut),
    );
  }

  SliverAppBar _buildSliverAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 15.h,
      pinned: true,
      floating: false,
      backgroundColor:
          isDark ? AppTheme.primaryVariantDark : AppTheme.primaryLight,
      elevation: 0,
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      actions: [
        IconButton(
          icon: const CustomIconWidget(
            iconName: 'refresh',
            color: Colors.white,
            size: 22,
          ),
          onPressed: _refresh,
          tooltip: 'Refresh',
        ),
        SizedBox(width: 1.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 5.w, bottom: 1.6.h),
        title: Text(
          'My Progress',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.primaryVariantDark,
                      AppTheme.backgroundDark,
                    ]
                  : [
                      AppTheme.primaryLight,
                      AppTheme.primaryVariantLight,
                    ],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 5.w, bottom: 5.5.h),
                child: Text(
                  'Track your transformation',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, String iconName) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 2.5.w),
        CustomIconWidget(
          iconName: iconName,
          color: theme.colorScheme.primary,
          size: 17,
        ),
        SizedBox(width: 2.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Container(
              height: 15.h,
              color: Colors.white,
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  SizedBox(height: 1.h),
                  _skeletonBox(14.h),
                  SizedBox(height: 2.5.h),
                  _skeletonBox(20.h),
                  SizedBox(height: 2.5.h),
                  _skeletonBox(18.h),
                  SizedBox(height: 2.5.h),
                  _skeletonBox(60.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
