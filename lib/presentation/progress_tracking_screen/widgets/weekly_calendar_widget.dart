import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import '../../../../services/supabase_service.dart';

class WeeklyCalendarWidget extends StatefulWidget {
  final Function(String sessionId) onSessionSelected;

  const WeeklyCalendarWidget({
    super.key,
    required this.onSessionSelected,
  });

  @override
  State<WeeklyCalendarWidget> createState() => _WeeklyCalendarWidgetState();
}

class _WeeklyCalendarWidgetState extends State<WeeklyCalendarWidget> {
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, Map<String, dynamic>> _scheduledSessions = {};
  Map<DateTime, bool> _completedSessions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklySchedule();
  }

  Future<void> _loadWeeklySchedule() async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Get user's active plan
      final scheduleResponse = await SupabaseService.instance.client
          .from('user_workout_schedules')
          .select('plan_id, start_date')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (scheduleResponse == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final planId = scheduleResponse['plan_id'];
      
      // 2. Get sessions for this plan
      final sessionsResponse = await SupabaseService.instance.client
          .from('workout_sessions')
          .select('id, day_number, session_name, focus_area')
          .eq('plan_id', planId);

      // 3. Map sessions to actual dates for the current week
      final Map<DateTime, Map<String, dynamic>> sessionMap = {};
      final List<dynamic> sessions = sessionsResponse as List<dynamic>;

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      for (var session in sessions) {
        final dayNum = session['day_number'] as int;
        if (dayNum >= 1 && dayNum <= 7) {
           final sessionDate = startOfWeek.add(Duration(days: dayNum - 1));
           sessionMap[sessionDate] = session;
        }
      }

      // 4. Get logs for this week
      final logsResponse = await SupabaseService.instance.client
          .from('workout_logs')
          .select('completed_at, session_id')
          .eq('user_id', userId)
          .gte('completed_at', startOfWeek.toIso8601String())
          .lt('completed_at', endOfWeek.toIso8601String());

      final Map<DateTime, bool> completedMap = {};
      for (var log in logsResponse) {
        final completedDate = DateTime.parse(log['completed_at']).toLocal();
        final dateKey = DateTime(completedDate.year, completedDate.month, completedDate.day);
        completedMap[dateKey] = true;
      }

      if (mounted) {
        setState(() {
          _scheduledSessions = sessionMap;
          _completedSessions = completedMap;
          _isLoading = false;
        });
      }

    } catch (e) {
      debugPrint('Error loading schedule: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Text(
            'Calendar Antrenamente',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 14.h, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            itemCount: 7,
            itemBuilder: (context, index) {
              final date = startOfWeek.add(Duration(days: index));
              final dateOnly = DateTime(date.year, date.month, date.day);
              final isSelected = _selectedDate.day == date.day && 
                                 _selectedDate.month == date.month;
              final isToday = today.isAtSameMomentAs(dateOnly);
              
              final session = _scheduledSessions.entries.firstWhere(
                (entry) => entry.key.isAtSameMomentAs(dateOnly),
                orElse: () => MapEntry(dateOnly, {}),
              ).value;

              final hasWorkout = session.isNotEmpty;
              final isCompleted = _completedSessions.containsKey(dateOnly);
              final isMissed = hasWorkout && !isCompleted && dateOnly.isBefore(today);

              // Determine Color
              Color statusColor;
              if (isCompleted) {
                statusColor = Colors.green;
              } else if (isMissed) {
                statusColor = Colors.red;
              } else if (hasWorkout) {
                statusColor = Colors.orange;
              } else {
                statusColor = Colors.grey.withAlpha(50);
              }

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = dateOnly);
                  if (hasWorkout) {
                    widget.onSessionSelected(session['id']);
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Niciun antrenament programat pentru această zi.')),
                    );
                  }
                },
                child: Container(
                  width: 18.w,
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : (isToday ? Colors.blue.withAlpha(30) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey.withAlpha(50),
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E', 'ro_RO').format(date).toUpperCase(), 
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      if (hasWorkout)
                        Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.white : statusColor,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check : (isMissed ? Icons.close : Icons.fitness_center),
                            size: 10.sp,
                            color: isSelected ? statusColor : Colors.white,
                          ),
                        )
                      else
                        SizedBox(height: 2.5.h), 
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
