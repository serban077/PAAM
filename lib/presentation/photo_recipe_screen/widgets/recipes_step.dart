import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../data/models/smart_recipe_models.dart';
import '../../../widgets/ai_loading_widget.dart';
import '../../../widgets/custom_icon_widget.dart';
import 'recipe_detail_sheet.dart';

/// Step 3: Browse generated recipes, tap to see details, select one to log.
class RecipesStep extends StatelessWidget {
  final List<GeneratedRecipe> recipes;
  final bool isLoading;
  final void Function(GeneratedRecipe recipe) onRecipeSelected;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  const RecipesStep({
    super.key,
    required this.recipes,
    required this.isLoading,
    required this.onRecipeSelected,
    required this.onBack,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) return _buildShimmer(theme);
    if (recipes.isEmpty) return _buildEmptyState(theme);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Row(
            children: [
              Text(
                'Your Recipes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${recipes.length} options',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.5.h),

        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            itemCount: recipes.length,
            separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return _RecipeCard(
                recipe: recipe,
                onTap: () => _showRecipeDetail(context, recipe),
                onSelect: () {
                  HapticFeedback.lightImpact();
                  onRecipeSelected(recipe);
                },
                theme: theme,
              );
            },
          ),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 2.h),
          child: TextButton.icon(
            onPressed: onBack,
            icon: const CustomIconWidget(iconName: 'arrow_back', size: 18),
            label: const Text('Back to Ingredients'),
          ),
        ),
      ],
    );
  }

  void _showRecipeDetail(BuildContext context, GeneratedRecipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => RecipeDetailSheet(
        recipe: recipe,
        onLogMeal: () {
          Navigator.pop(ctx);
          onRecipeSelected(recipe);
        },
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme) {
    return AILoadingWidget(
      iconName: 'restaurant_menu',
      title: 'Crafting your recipes...',
      statusMessages: const [
        'Matching ingredients to recipes...',
        'Calculating macros per serving...',
        'Picking the best combinations...',
        'Finalizing meal ideas...',
      ],
      stepLabels: const ['Match', 'Calculate', 'Build'],
      activeStep: 1,
      skeletonBuilder: (t) => RecipeCardSkeleton(theme: t),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'restaurant',
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            SizedBox(height: 2.h),
            Text(
              'Could not generate recipes',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try again or go back to edit ingredients',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 3.h),
            if (onRetry != null)
              Padding(
                padding: EdgeInsets.only(bottom: 1.5.h),
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const CustomIconWidget(
                    iconName: 'refresh',
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text('Try Again'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                    foregroundColor: theme.colorScheme.onTertiary,
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: onBack,
              icon: const CustomIconWidget(
                iconName: 'arrow_back',
                size: 18,
              ),
              label: const Text('Back to Ingredients'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recipe Card ─────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final GeneratedRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onSelect;
  final ThemeData theme;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onSelect,
    required this.theme,
  });

  Color _difficultyColor() {
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(3.5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + difficulty badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 2.w, vertical: 0.3.h),
                    decoration: BoxDecoration(
                      color: _difficultyColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      recipe.difficulty,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: _difficultyColor(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),

              // Description
              Text(
                recipe.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.5.h),

              // Macro chips row
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
              SizedBox(height: 1.5.h),

              // Time + servings + select button
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'schedule',
                    size: 14,
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
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${recipe.servings} serving${recipe.servings > 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: onSelect,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      foregroundColor: theme.colorScheme.onTertiary,
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 0.8.h),
                      minimumSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Log This',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

