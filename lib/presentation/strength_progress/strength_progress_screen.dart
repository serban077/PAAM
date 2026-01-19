import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../routes/app_routes.dart';

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

      // Get active plan
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

      // Get all sessions for this plan
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progres Forță'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center, size: 60.sp, color: Colors.grey),
                      SizedBox(height: 2.h),
                      Text(
                        'Nu ai un plan activ',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Generează un plan AI pentru a începe',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return _buildSessionCard(session);
                  },
                ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final theme = Theme.of(context);
    final dayNumber = session['day_number'] ?? 0;
    final name = session['name'] ?? 'Antrenament';
    final focusArea = session['focus_area'] ?? '';
    final duration = session['estimated_duration_minutes'] ?? 60;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        contentPadding: EdgeInsets.all(3.w),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            'Z$dayNumber',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                Icon(Icons.schedule, size: 14.sp, color: Colors.grey),
                SizedBox(width: 1.w),
                Text('$duration min'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
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
