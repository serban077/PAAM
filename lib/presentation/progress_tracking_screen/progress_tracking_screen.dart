import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import './widgets/photo_progress_widget.dart';
import './widgets/weekly_calendar_widget.dart';
import './widgets/body_measurements_card.dart';
import './widgets/real_workout_stats_widget.dart';
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
        setState(() => _isLoading = false);
        return;
      }

      await SupabaseService.instance.client
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progress Tracking'), centerTitle: true),
        body: _buildSkeleton(theme),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Tracking'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              SizedBox(height: 2.h),
              const WeightProgressCard(),
              SizedBox(height: 3.h),
              const BodyMeasurementsCard(),
              SizedBox(height: 3.h),
              const RealWorkoutStatsWidget(),
              SizedBox(height: 3.h),
              Text(
                'Photo Progress',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              const PhotoProgressWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    final color = theme.colorScheme.surfaceContainerHighest.withAlpha(76);
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar skeleton
          Container(
            height: 10.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 2.h),
          // Weight card skeleton
          Container(
            height: 15.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 3.h),
          // Measurements skeleton
          Container(
            height: 20.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 3.h),
          // Stats skeleton
          Container(
            height: 12.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
