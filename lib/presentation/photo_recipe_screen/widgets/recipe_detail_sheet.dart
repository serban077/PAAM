import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../data/models/smart_recipe_models.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Bottom sheet showing full recipe details: ingredients, steps, and macros.
/// Displayed when user taps a recipe card in [RecipesStep].
class RecipeDetailSheet extends StatelessWidget {
  final GeneratedRecipe recipe;
  final VoidCallback onLogMeal;

  const RecipeDetailSheet({
    super.key,
    required this.recipe,
    required this.onLogMeal,
  });

  Color _difficultyColor(ThemeData theme) {
    switch (recipe.difficulty) {
      case 'easy':
        return theme.colorScheme.primary;
      case 'medium':
        return const Color(0xFFFF6F00);
      case 'hard':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.symmetric(vertical: 1.5.h),
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipe name + difficulty badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              recipe.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.5.w, vertical: 0.4.h),
                            decoration: BoxDecoration(
                              color: _difficultyColor(theme)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              recipe.difficulty,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: _difficultyColor(theme),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),

                      // Description
                      if (recipe.description.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 1.5.h),
                          child: Text(
                            recipe.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                      // Time + servings row
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'schedule',
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${recipe.totalTimeMinutes} min',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          CustomIconWidget(
                            iconName: 'people',
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${recipe.servings} serving${recipe.servings > 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.5.h),

                      // Macros summary row
                      Row(
                        children: [
                          _MacroChip(
                            label: '${recipe.calories.round()} kcal',
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 2.w),
                          _MacroChip(
                            label: '${recipe.proteinG.round()}g P',
                            color: const Color(0xFFE53935),
                          ),
                          SizedBox(width: 2.w),
                          _MacroChip(
                            label: '${recipe.carbsG.round()}g C',
                            color: const Color(0xFFFFB300),
                          ),
                          SizedBox(width: 2.w),
                          _MacroChip(
                            label: '${recipe.fatG.round()}g F',
                            color: const Color(0xFFFF7043),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),

                      Divider(color: theme.colorScheme.outlineVariant),
                      SizedBox(height: 1.5.h),

                      // Ingredients section
                      Text(
                        'Ingredients',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ...recipe.ingredients.map(
                        (ing) => Padding(
                          padding: EdgeInsets.only(bottom: 0.8.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 0.8.h),
                                width: 1.5.w,
                                height: 1.5.w,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 2.5.w),
                              Expanded(
                                child: Text(
                                  '${ing.ingredientName} — ${ing.quantityG.round()}g${ing.displayUnit != null ? ' (${ing.displayUnit})' : ''}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 1.5.h),

                      Divider(color: theme.colorScheme.outlineVariant),
                      SizedBox(height: 1.5.h),

                      // Steps section
                      Text(
                        'Steps',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ...List.generate(recipe.steps.length, (i) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 1.2.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 3.w,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 2.5.w),
                              Expanded(
                                child: Text(
                                  recipe.steps[i],
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      SizedBox(height: 3.h),
                    ],
                  ),
                ),
              ),

              // Fixed bottom CTA
              SafeArea(
                top: false,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 6.h,
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onLogMeal();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.tertiary,
                        foregroundColor: theme.colorScheme.onTertiary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Log This Meal',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
