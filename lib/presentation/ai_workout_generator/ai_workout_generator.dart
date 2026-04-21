import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../services/analytics_service.dart';
import '../../services/gemini_ai_service.dart';
import '../../services/supabase_service.dart';
import './widgets/generation_progress_widget.dart';
import './widgets/workout_plan_card_widget.dart';
import './widgets/exercise_preview_card_widget.dart';

class AIWorkoutGenerator extends StatefulWidget {
  const AIWorkoutGenerator({super.key});

  @override
  State<AIWorkoutGenerator> createState() => _AIWorkoutGeneratorState();
}

class _AIWorkoutGeneratorState extends State<AIWorkoutGenerator> {
  bool _isGenerating = false;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _generatedPlan;
  List<Map<String, dynamic>>? _personalizedExercises;
  CancelToken? _cancelToken;
  String _progressMessage = '';
  double _progressValue = 0.0;
  String _streamingText = '';

  final _geminiService = GeminiAIService();

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _generateWorkoutPlan() async {
    setState(() {
      _isGenerating = true;
      _hasError = false;
      _errorMessage = '';
      _generatedPlan = null;
      _streamingText = '';
      _progressValue = 0.0;
      _progressMessage = 'Analyzing your profile...';
    });

    _cancelToken = CancelToken();

    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      setState(() {
        _progressValue = 0.1;
        _progressMessage = 'Generating your personalized workout plan...';
      });

      // Stream tokens for live preview — cache is written on stream completion
      await for (final chunk in _geminiService.streamWeeklyWorkoutPlan(user.id)) {
        if (!mounted) return;
        setState(() {
          _streamingText += chunk;
          _progressValue = (_streamingText.length / 3000).clamp(0.1, 0.9);
        });
      }

      if (!mounted) return;

      // Cache was populated by the stream; this returns instantly
      final plan = await _geminiService.generateWeeklyWorkoutPlan(user.id);

      setState(() {
        _progressValue = 1.0;
        _progressMessage = 'Plan generated successfully!';
        _generatedPlan = plan;
        _isGenerating = false;
        _streamingText = '';
      });
      unawaited(AnalyticsService.instance.trackFirstOnce(
          'first_ai_plan_generated', 'analytics_first_ai_plan_generated'));
    } on GeminiException catch (e, stack) {
      unawaited(Sentry.captureException(e, stackTrace: stack,
          hint: Hint.withMap({'screen': 'AIWorkoutGenerator', 'method': '_generateWorkoutPlan'})));
      setState(() {
        _isGenerating = false;
        _hasError = true;
        _errorMessage = e.message;
        _streamingText = '';
      });
    } catch (e, stack) {
      unawaited(Sentry.captureException(e, stackTrace: stack,
          hint: Hint.withMap({'screen': 'AIWorkoutGenerator', 'method': '_generateWorkoutPlan'})));
      setState(() {
        _isGenerating = false;
        _hasError = true;
        _errorMessage = 'An error occurred: ${e.toString()}';
        _streamingText = '';
      });
    }
  }

  Future<void> _generatePersonalizedExercises() async {
    setState(() {
      _isGenerating = true;
      _hasError = false;
      _errorMessage = '';
      _personalizedExercises = null;
      _progressValue = 0.0;
      _progressMessage = 'Analyzing your preferences...';
    });

    _cancelToken = CancelToken();

    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      setState(() {
        _progressValue = 0.3;
        _progressMessage = 'Finding the best exercises for you...';
      });

      final exercises = await _geminiService.getPersonalizedExercises(user.id);

      setState(() {
        _progressValue = 1.0;
        _progressMessage = 'Exercises found!';
        _personalizedExercises = exercises;
        _isGenerating = false;
      });
    } on GeminiException catch (e, stack) {
      unawaited(Sentry.captureException(e, stackTrace: stack,
          hint: Hint.withMap({'screen': 'AIWorkoutGenerator', 'method': '_generatePersonalizedExercises'})));
      setState(() {
        _isGenerating = false;
        _hasError = true;
        _errorMessage = e.message;
      });
    } catch (e, stack) {
      unawaited(Sentry.captureException(e, stackTrace: stack,
          hint: Hint.withMap({'screen': 'AIWorkoutGenerator', 'method': '_generatePersonalizedExercises'})));
      setState(() {
        _isGenerating = false;
        _hasError = true;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  void _cancelGeneration() {
    _cancelToken?.cancel('Cancelled by user');
    setState(() {
      _isGenerating = false;
      _progressMessage = 'Generation cancelled';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI Workout Generator'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isGenerating
            ? GenerationProgressWidget(
                progressValue: _progressValue,
                progressMessage: _progressMessage,
                onCancel: _cancelGeneration,
                streamingText: _streamingText.isNotEmpty ? _streamingText : null,
              )
            : _hasError
            ? _buildErrorView(theme)
            : _generatedPlan != null || _personalizedExercises != null
            ? _buildResultsView(theme)
            : _buildInitialView(theme),
      ),
    );
  }

  Widget _buildInitialView(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withAlpha(51),
                  theme.colorScheme.secondary.withAlpha(26),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 12.w,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(height: 2.h),
                Text(
                  'AI Personalized Generator',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  'We use artificial intelligence to create workout plans perfectly tailored for you',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          _buildFeatureCard(
            theme: theme,
            icon: Icons.fitness_center,
            title: 'Full Weekly Plan',
            description: 'Generate a structured 7-day workout plan',
            onPressed: _generateWorkoutPlan,
          ),
          SizedBox(height: 2.h),
          _buildFeatureCard(
            theme: theme,
            icon: Icons.star,
            title: 'Personalized Exercises',
            description:
                'Discover the perfect exercises for your level and goals',
            onPressed: _generatePersonalizedExercises,
          ),
          SizedBox(height: 3.h),
          _buildInfoSection(theme),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 8.w),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(description, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 5.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              SizedBox(width: 2.w),
              Text(
                'About AI Generator',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildInfoItem(theme, 'Analyze your complete profile'),
          _buildInfoItem(theme, 'Adapt to your experience level'),
          _buildInfoItem(theme, 'Respect medical restrictions'),
          _buildInfoItem(theme, 'Use available equipment'),
          _buildInfoItem(theme, 'Optimize for your goals'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 5.w),
          SizedBox(width: 2.w),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildResultsView(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_generatedPlan != null) ...[
            Text(
              'Your Workout Plan',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            WorkoutPlanCardWidget(plan: _generatedPlan!),
            SizedBox(height: 2.h),
          ],
          if (_personalizedExercises != null) ...[
            Text(
              'Recommended Exercises',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _personalizedExercises!.length,
              itemBuilder: (context, index) {
                return ExercisePreviewCardWidget(
                  exercise: _personalizedExercises![index],
                );
              },
            ),
          ],
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _generatedPlan = null;
              _personalizedExercises = null;
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Generate Again'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 15.w,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: 2.h),
            Text(
              'An error occurred',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _hasError = false;
                _errorMessage = '';
              }),
              icon: const Icon(Icons.replay),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
