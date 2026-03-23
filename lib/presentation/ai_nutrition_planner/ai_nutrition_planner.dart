import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:dio/dio.dart';

import '../../services/gemini_ai_service.dart';
import '../../services/supabase_service.dart';
import './widgets/nutrition_generation_progress_widget.dart';
import './widgets/nutrition_summary_widget.dart';
import './widgets/meal_plan_card_widget.dart';

class AINutritionPlanner extends StatefulWidget {
  const AINutritionPlanner({super.key});

  @override
  State<AINutritionPlanner> createState() => _AINutritionPlannerState();
}

class _AINutritionPlannerState extends State<AINutritionPlanner> {
  bool _isGenerating = false;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _nutritionPlan;
  CancelToken? _cancelToken;
  String _progressMessage = '';
  double _progressValue = 0.0;

  final _geminiService = GeminiAIService();

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _generateNutritionPlan() async {
    setState(() {
      _isGenerating = true;
      _hasError = false;
      _errorMessage = '';
      _nutritionPlan = null;
      _progressValue = 0.0;
      _progressMessage = 'Analyzing your profile...';
    });

    _cancelToken = CancelToken();

    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      setState(() {
        _progressValue = 0.3;
        _progressMessage = 'Calculating your caloric needs...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _progressValue = 0.6;
        _progressMessage = 'Creating your personalized meal plan...';
      });

      final plan = await _geminiService.generateNutritionPlan(user.id);

      setState(() {
        _progressValue = 1.0;
        _progressMessage = 'Nutrition plan generated!';
        _nutritionPlan = plan;
        _isGenerating = false;
      });
    } on GeminiException catch (e) {
      setState(() {
        _isGenerating = false;
        _hasError = true;
        _errorMessage = e.message;
      });
    } catch (e) {
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
        title: const Text('AI Nutrition Planner'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isGenerating
            ? NutritionGenerationProgressWidget(
                progressValue: _progressValue,
                progressMessage: _progressMessage,
                onCancel: _cancelGeneration,
              )
            : _hasError
            ? _buildErrorView(theme)
            : _nutritionPlan != null
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
                  theme.colorScheme.secondary.withAlpha(51),
                  theme.colorScheme.tertiary.withAlpha(26),
                ],
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 12.w,
                  color: theme.colorScheme.secondary,
                ),
                SizedBox(height: 2.h),
                Text(
                  'AI Nutrition Planner',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  'We create personalized nutrition plans tailored to your goals and preferences',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          _buildFeatureCard(
            theme: theme,
            icon: Icons.calculate,
            title: 'Precise Calorie Calculation',
            description:
                'We determine your caloric needs based on goals and activity level',
          ),
          SizedBox(height: 2.h),
          _buildFeatureCard(
            theme: theme,
            icon: Icons.pie_chart,
            title: 'Optimal Macro Distribution',
            description:
                'We balance protein, carbohydrates and fats perfectly for you',
          ),
          SizedBox(height: 2.h),
          _buildFeatureCard(
            theme: theme,
            icon: Icons.lunch_dining,
            title: 'Personalized Meals',
            description:
                'Concrete meal examples adapted to your food preferences',
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _generateNutritionPlan,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Nutrition Plan'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
            ),
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
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withAlpha(26),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: theme.colorScheme.secondary, size: 8.w),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.secondary),
              SizedBox(width: 2.w),
              Text(
                'What You Get',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildInfoItem(theme, 'Personalized calorie calculation'),
          _buildInfoItem(theme, 'Optimal macronutrient distribution'),
          _buildInfoItem(theme, 'Full daily meal plan'),
          _buildInfoItem(theme, 'Respects dietary preferences'),
          _buildInfoItem(theme, 'Avoids declared allergens'),
          _buildInfoItem(theme, 'Hydration and supplement recommendations'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.secondary,
            size: 5.w,
          ),
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
          Text(
            'Your Nutrition Plan',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          NutritionSummaryWidget(
            dailyCalories: _nutritionPlan!['dailyCalories'] ?? 0,
            macros: _nutritionPlan!['macros'] as Map<String, dynamic>? ?? {},
          ),
          SizedBox(height: 2.h),
          Text(
            'Recommended Meals',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (_nutritionPlan!['mealPlan'] as List?)?.length ?? 0,
            itemBuilder: (context, index) {
              final meal =
                  (_nutritionPlan!['mealPlan'] as List)[index]
                      as Map<String, dynamic>;
              return MealPlanCardWidget(meal: meal);
            },
          ),
          if (_nutritionPlan!['hydration'] != null) ...[
            SizedBox(height: 2.h),
            _buildHydrationCard(theme),
          ],
          if (_nutritionPlan!['supplements'] != null) ...[
            SizedBox(height: 2.h),
            _buildSupplementsCard(theme),
          ],
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () => setState(() => _nutritionPlan = null),
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

  Widget _buildHydrationCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Icon(Icons.water_drop, color: theme.colorScheme.primary, size: 8.w),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hydration',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _nutritionPlan!['hydration'] ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementsCard(ThemeData theme) {
    final supplements = _nutritionPlan!['supplements'] as List? ?? [];

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medication,
                  color: theme.colorScheme.secondary,
                  size: 6.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Recommended Supplements',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: supplements.map((supplement) {
                return Chip(
                  label: Text(supplement),
                  backgroundColor: theme.colorScheme.secondary.withAlpha(26),
                );
              }).toList(),
            ),
          ],
        ),
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
