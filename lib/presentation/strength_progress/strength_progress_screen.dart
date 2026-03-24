import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_icon_widget.dart';

/// Strength Progress Screen - Shows list of workout sessions
class StrengthProgressScreen extends StatefulWidget {
  const StrengthProgressScreen({super.key});

  @override
  State<StrengthProgressScreen> createState() => _StrengthProgressScreenState();
}

class _StrengthProgressScreenState extends State<StrengthProgressScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      setState(() => _isLoading = true);

      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final scheduleResponse = await SupabaseService.instance.client
          .from('user_workout_schedules')
          .select('plan_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (scheduleResponse == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final sessionsResponse = await SupabaseService.instance.client
          .from('workout_sessions')
          .select('id, name, day_number, focus_area, estimated_duration_minutes')
          .eq('plan_id', scheduleResponse['plan_id'])
          .order('day_number');

      if (mounted) {
        setState(() {
          _sessions = List<Map<String, dynamic>>.from(sessionsResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    await _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strength Progress'),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildSkeleton(theme)
          : _sessions.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(4.w),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      return _buildSessionCard(_sessions[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    final color = theme.colorScheme.surfaceContainerHighest.withAlpha(76);
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: EdgeInsets.only(bottom: 2.h),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 2.h, width: 40.w, color: color),
                    SizedBox(height: 1.h),
                    Container(height: 1.5.h, width: 25.w, color: color),
                    SizedBox(height: 0.5.h),
                    Container(height: 1.5.h, width: 18.w, color: color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'fitness_center',
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            SizedBox(height: 2.h),
            Text('No active plan', style: theme.textTheme.titleLarge),
            SizedBox(height: 1.h),
            Text(
              'Generate an AI workout plan to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final theme = Theme.of(context);
    final dayNumber = session['day_number'] ?? 0;
    final name = session['name'] ?? 'Workout';
    final focusArea = session['focus_area'] ?? '';
    final duration = session['estimated_duration_minutes'] ?? 60;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        contentPadding: EdgeInsets.all(3.w),
        minVerticalPadding: 2.h,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            'D$dayNumber',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (focusArea.isNotEmpty) ...[
              SizedBox(height: 0.5.h),
              Text(focusArea),
            ],
            SizedBox(height: 0.5.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'schedule',
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 1.w),
                Text('$duration min'),
              ],
            ),
          ],
        ),
        trailing: CustomIconWidget(
          iconName: 'chevron_right',
          size: 24,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(
            context,
            AppRoutes.exerciseDetails,
            arguments: {'sessionId': session['id']},
          );
        },
      ),
    );
  }
}
