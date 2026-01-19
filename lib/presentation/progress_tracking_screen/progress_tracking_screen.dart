import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import './widgets/weight_tracking_widget.dart';
import './widgets/measurements_tracking_widget.dart';
import './widgets/workout_analytics_widget.dart';
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
  Map<String, dynamic>? _userProfile;

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

      final response = await SupabaseService.instance.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      setState(() {
        _userProfile = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentWeight = _userProfile?['current_weight_kg']?.toDouble() ?? 0.0;
    final targetWeight = _userProfile?['target_weight_kg']?.toDouble() ?? 0.0;
    final height = _userProfile?['height_cm']?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Urmărire Progres'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly Calendar
            WeeklyCalendarWidget(
              key: _calendarKey,
              onSessionSelected: (sessionId) async {
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.workoutDetail,
                  arguments: {'sessionId': sessionId},
                );

                if (result == true) {
                  setState(() {
                    _calendarKey = UniqueKey(); // Force refresh
                  });
                }
              },
            ),
            SizedBox(height: 2.h),
            
            // Weight Progress Card
            const WeightProgressCard(),
            SizedBox(height: 3.h),

            // Measurements
            const BodyMeasurementsCard(),
            SizedBox(height: 3.h),

            // Workout analytics
            const RealWorkoutStatsWidget(),
            SizedBox(height: 3.h),

            // Photo progress
            Text(
              'Progres foto',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            const PhotoProgressWidget(),
          ],
        ),
      ),
    );
  }
}