import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../data/models/smart_recipe_models.dart';
import '../../../services/nutrition_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Step 4: Log a selected recipe as a meal.
/// Displays recipe summary, serving count selector, meal type picker, and
/// a "Log Meal" CTA that creates a food_database row + logs the meal.
class LogRecipeStep extends StatefulWidget {
  final GeneratedRecipe? recipe;
  final VoidCallback onBack;

  const LogRecipeStep({
    super.key,
    required this.recipe,
    required this.onBack,
  });

  @override
  State<LogRecipeStep> createState() => _LogRecipeStepState();
}

class _LogRecipeStepState extends State<LogRecipeStep> {
  final _nutritionService =
      NutritionService(SupabaseService.instance.client);

  String? _selectedMealType;
  int _servingCount = 1;
  bool _isLogging = false;

  static const _mealTypes = [
    ('Breakfast', 'mic_dejun'),
    ('Lunch', 'pranz'),
    ('Dinner', 'cina'),
    ('Snack', 'gustare_dimineata'),
  ];

  // ── Computed macros scaled by serving count ──

  double get _calories => (widget.recipe?.calories ?? 0) * _servingCount;
  double get _proteinG => (widget.recipe?.proteinG ?? 0) * _servingCount;
  double get _carbsG => (widget.recipe?.carbsG ?? 0) * _servingCount;
  double get _fatG => (widget.recipe?.fatG ?? 0) * _servingCount;

  // ── Log meal logic ──

  Future<void> _logRecipe() async {
    final recipe = widget.recipe;
    if (recipe == null || _selectedMealType == null) return;

    setState(() => _isLogging = true);

    try {
      // 1. Create temp food_database row for this recipe
      final foodRow = {
        'name': recipe.name,
        'calories': _calories.round(),
        'protein_g': _proteinG,
        'carbs_g': _carbsG,
        'fat_g': _fatG,
        'serving_size': 1,
        'serving_unit': 'portion',
        'is_verified': false,
        'is_user_contributed': true,
      };

      final insertedFood = await _nutritionService
          .submitUserFood(foodRow)
          .timeout(const Duration(seconds: 15));

      // 2. Log the meal
      await _nutritionService
          .logMeal(
            foodId: insertedFood['id'].toString(),
            mealType: _selectedMealType!,
            servingQuantity: 1,
          )
          .timeout(const Duration(seconds: 15));

      HapticFeedback.lightImpact();

      if (!mounted) return;

      // 3. Pop back with success
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLogging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log meal: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = widget.recipe;

    if (recipe == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Recipe summary card ──
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: theme.colorScheme.outlineVariant, width: 0.5),
            ),
            child: Padding(
              padding: EdgeInsets.all(3.5.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (recipe.description.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 0.5.h),
                      child: Text(
                        recipe.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  SizedBox(height: 1.5.h),

                  // Dynamic macro chips (scaled by serving count)
                  Row(
                    children: [
                      _MacroChip(
                        label: '${_calories.round()} kcal',
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 2.w),
                      _MacroChip(
                        label: '${_proteinG.round()}g P',
                        color: const Color(0xFFE53935),
                      ),
                      SizedBox(width: 2.w),
                      _MacroChip(
                        label: '${_carbsG.round()}g C',
                        color: const Color(0xFFFFB300),
                      ),
                      SizedBox(width: 2.w),
                      _MacroChip(
                        label: '${_fatG.round()}g F',
                        color: const Color(0xFFFF7043),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // ── Serving count selector ──
          Text(
            'Servings',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _CounterButton(
                icon: 'remove',
                enabled: _servingCount > 1,
                theme: theme,
                onTap: () {
                  if (_servingCount > 1) {
                    HapticFeedback.selectionClick();
                    setState(() => _servingCount--);
                  }
                },
              ),
              SizedBox(
                width: 12.w,
                child: Text(
                  '$_servingCount',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _CounterButton(
                icon: 'add',
                enabled: _servingCount < 10,
                theme: theme,
                onTap: () {
                  if (_servingCount < 10) {
                    HapticFeedback.selectionClick();
                    setState(() => _servingCount++);
                  }
                },
              ),
              SizedBox(width: 3.w),
              Text(
                'of ${recipe.servings}-serving recipe',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // ── Meal type picker ──
          Text(
            'Meal Type',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _mealTypes.map((entry) {
              final (label, key) = entry;
              final selected = _selectedMealType == key;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMealType = val ? key : null);
                },
                selectedColor:
                    theme.colorScheme.tertiary.withValues(alpha: 0.2),
                checkmarkColor: theme.colorScheme.tertiary,
                labelStyle: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.onSurface,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 4.h),

          // ── Log Meal CTA ──
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: FilledButton(
              onPressed:
                  (_selectedMealType != null && !_isLogging) ? _logRecipe : null,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiary,
                foregroundColor: theme.colorScheme.onTertiary,
                disabledBackgroundColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLogging
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onTertiary,
                      ),
                    )
                  : Text(
                      'Log Meal',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 2.h),

          // Back button
          Center(
            child: TextButton.icon(
              onPressed: widget.onBack,
              icon:
                  const CustomIconWidget(iconName: 'arrow_back', size: 18),
              label: const Text('Back to Recipes'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Counter Button ──────────────────────────────────────────────────────────

class _CounterButton extends StatelessWidget {
  final String icon;
  final bool enabled;
  final ThemeData theme;
  final VoidCallback onTap;

  const _CounterButton({
    required this.icon,
    required this.enabled,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        style: IconButton.styleFrom(
          backgroundColor: enabled
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: CustomIconWidget(
          iconName: icon,
          size: 20,
          color: enabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ── Macro Chip ──────────────────────────────────────────────────────────────

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MacroChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
