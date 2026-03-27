import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../routes/app_routes.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Post-workout summary screen shown after a session is completed.
/// Pushed via Navigator.pushReplacement from ActiveWorkoutSession.
class WorkoutSummaryScreen extends StatelessWidget {
  final String sessionName;
  final Map<String, dynamic> workoutLog;
  final List<Map<String, dynamic>> setLogs;
  final List<Map<String, dynamic>> newPRs;
  final List<Map<String, dynamic>> exercises; // session_exercises with nested exercises map
  final int durationSeconds;

  const WorkoutSummaryScreen({
    super.key,
    required this.sessionName,
    required this.workoutLog,
    required this.setLogs,
    required this.newPRs,
    required this.exercises,
    required this.durationSeconds,
  });

  // ── helpers ──────────────────────────────────────────────────────────

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int get _totalCompletedSets =>
      setLogs.where((s) => s['is_completed'] == true).length;

  double get _totalVolume {
    double v = 0;
    for (final s in setLogs) {
      if (s['is_completed'] == true && s['weight_kg'] != null) {
        v += (s['weight_kg'] as num).toDouble() *
            (s['reps'] as num).toDouble();
      }
    }
    return v;
  }

  /// Groups set logs by session_exercise_id, merging exercise name
  /// from the exercises list.
  List<_ExerciseSummary> _buildExerciseSummaries() {
    final Map<String, _ExerciseSummary> map = {};

    for (final ex in exercises) {
      final exId = ex['id'] as String;
      final name =
          (ex['exercises'] as Map<String, dynamic>?)?['name'] as String? ??
              'Exercise';
      final totalSets = ex['sets'] as int? ?? 0;
      map[exId] = _ExerciseSummary(
          sessionExerciseId: exId, name: name, totalSets: totalSets, sets: []);
    }

    for (final s in setLogs) {
      if (s['is_completed'] != true) continue;
      final seId = s['session_exercise_id'] as String;
      map[seId]?.sets.add(s);
    }

    return map.values.toList();
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summaries = _buildExerciseSummaries();
    final volume = _totalVolume;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient header
          Positioned(
            top: 0, left: 0, right: 0,
            height: 28.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.surface,
                        ]
                      : [
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer,
                        ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(6.w, 3.h, 6.w, 2.h),
                    child: Column(
                      children: [
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: isDark
                              ? theme.colorScheme.primary
                              : Colors.white,
                          size: 56,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Workout Complete!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? theme.colorScheme.onSurface
                                : Colors.white,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          sessionName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? theme.colorScheme.onSurfaceVariant
                                : Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: 'timer',
                            label: 'Duration',
                            value: _formatDuration(durationSeconds),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: _StatCard(
                            icon: 'fitness_center',
                            label: 'Volume',
                            value: volume >= 1000
                                ? '${(volume / 1000).toStringAsFixed(1)}k'
                                : volume.toStringAsFixed(0),
                            unit: 'kg',
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: _StatCard(
                            icon: 'check_circle_outline',
                            label: 'Sets',
                            value: '$_totalCompletedSets',
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // New PRs section
                if (newPRs.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildPRSection(theme),
                  ),

                // Exercise breakdown
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.h),
                    child: Text(
                      'Exercise Breakdown',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) =>
                        _ExerciseBreakdownTile(summary: summaries[i]),
                    childCount: summaries.length,
                  ),
                ),

                // Back to dashboard button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 4.h),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).popUntil(
                          (route) =>
                              route.settings.name ==
                                  AppRoutes.mainDashboard ||
                              route.isFirst,
                        );
                      },
                      icon: CustomIconWidget(
                        iconName: 'home',
                        color: theme.colorScheme.onPrimary,
                        size: 22,
                      ),
                      label: const Text('Back to Dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: Size(double.infinity, 6.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPRSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.amber[700]?.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber[600]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                    iconName: 'emoji_events',
                    color: Colors.amber[700]!,
                    size: 22),
                SizedBox(width: 2.w),
                Text(
                  'New Personal Records!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ...newPRs.map((pr) {
              final weight = (pr['weight_kg'] as num).toDouble();
              final reps = pr['reps'] as int;
              return Padding(
                padding: EdgeInsets.only(top: 0.5.h),
                child: Text(
                  '• ${weight.toStringAsFixed(1)} kg × $reps reps',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.amber[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String? unit;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 22),
          SizedBox(height: 0.8.h),
          RichText(
            text: TextSpan(
              text: value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              children: unit != null
                  ? [
                      TextSpan(
                        text: ' $unit',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ]
                  : [],
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSummary {
  final String sessionExerciseId;
  final String name;
  final int totalSets;
  final List<Map<String, dynamic>> sets;

  _ExerciseSummary({
    required this.sessionExerciseId,
    required this.name,
    required this.totalSets,
    required this.sets,
  });
}

class _ExerciseBreakdownTile extends StatelessWidget {
  final _ExerciseSummary summary;

  const _ExerciseBreakdownTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = summary.sets.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.h),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          title: Text(
            summary.name,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '$completed / ${summary.totalSets} sets',
            style: theme.textTheme.bodySmall?.copyWith(
              color: completed == summary.totalSets
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            if (summary.sets.isEmpty)
              Padding(
                padding: EdgeInsets.all(3.w),
                child: Text('No sets logged',
                    style: theme.textTheme.bodySmall),
              )
            else
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      children: [
                        Text('Set',
                            style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold)),
                        Text('Weight',
                            style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold)),
                        Text('Reps',
                            style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ...summary.sets.map((s) {
                      final w = s['weight_kg'];
                      final weightStr = w != null
                          ? '${(w as num).toStringAsFixed(1)} kg'
                          : 'BW';
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${s['set_number']}',
                                style: theme.textTheme.bodySmall),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(weightStr,
                                style: theme.textTheme.bodySmall),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${s['reps']}',
                                style: theme.textTheme.bodySmall),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
