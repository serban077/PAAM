import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../data/models/smart_recipe_models.dart';
import '../../../widgets/ai_loading_widget.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Step 2: Review detected ingredients — remove false positives, edit quantities.
class IngredientsReviewStep extends StatefulWidget {
  final List<DetectedIngredient> ingredients;
  final bool isLoading;
  final void Function(List<DetectedIngredient> ingredients) onGenerateRecipes;
  final VoidCallback onRetakePhoto;

  const IngredientsReviewStep({
    super.key,
    required this.ingredients,
    required this.isLoading,
    required this.onGenerateRecipes,
    required this.onRetakePhoto,
  });

  @override
  State<IngredientsReviewStep> createState() => _IngredientsReviewStepState();
}

class _IngredientsReviewStepState extends State<IngredientsReviewStep> {
  late List<DetectedIngredient> _editableIngredients;

  @override
  void initState() {
    super.initState();
    _editableIngredients = List.from(widget.ingredients);
  }

  @override
  void didUpdateWidget(IngredientsReviewStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ingredients != oldWidget.ingredients) {
      _editableIngredients = List.from(widget.ingredients);
    }
  }

  void _removeIngredient(int index) {
    HapticFeedback.lightImpact();
    setState(() => _editableIngredients.removeAt(index));
  }

  void _editQuantity(int index) {
    final ingredient = _editableIngredients[index];
    final controller = TextEditingController(
      text: ingredient.estimatedQuantityG.round().toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${ingredient.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity (g)',
            suffixText: 'g',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newQty = double.tryParse(controller.text);
              if (newQty != null && newQty > 0) {
                setState(() {
                  _editableIngredients[index] =
                      ingredient.copyWith(estimatedQuantityG: newQty);
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  static const _categoryColors = {
    'protein': Color(0xFFE53935),
    'carb': Color(0xFFFFB300),
    'fat': Color(0xFFFF7043),
    'vegetable': Color(0xFF43A047),
    'fruit': Color(0xFF7CB342),
    'dairy': Color(0xFF42A5F5),
    'condiment': Color(0xFF8D6E63),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return _buildShimmer(theme);
    }

    if (_editableIngredients.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      children: [
        // Warning for few ingredients
        if (_editableIngredients.length < 3)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    size: 18,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Few ingredients found — recipes may be limited',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        SizedBox(height: 1.5.h),

        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Row(
            children: [
              Text(
                'Detected Ingredients',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_editableIngredients.length} items',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),

        // Ingredient list
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            itemCount: _editableIngredients.length,
            separatorBuilder: (_, __) => SizedBox(height: 1.h),
            itemBuilder: (context, index) {
              final ingredient = _editableIngredients[index];
              final catColor =
                  _categoryColors[ingredient.category] ?? Colors.grey;

              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.2.h),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _categoryEmoji(ingredient.category),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  title: Text(
                    ingredient.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.2.h),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ingredient.category,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: catColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '~${ingredient.estimatedQuantityG.round()}g',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const CustomIconWidget(
                            iconName: 'edit', size: 18),
                        onPressed: () => _editQuantity(index),
                        tooltip: 'Edit quantity',
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'close',
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () => _removeIngredient(index),
                        tooltip: 'Remove',
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom actions
        Padding(
          padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 2.h),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: FilledButton.icon(
                  onPressed: _editableIngredients.isEmpty
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          widget.onGenerateRecipes(_editableIngredients);
                        },
                  icon: const CustomIconWidget(
                    iconName: 'restaurant_menu',
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Generate Recipes',
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                    foregroundColor: theme.colorScheme.onTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              TextButton.icon(
                onPressed: widget.onRetakePhoto,
                icon: const CustomIconWidget(iconName: 'camera_alt', size: 18),
                label: const Text('Retake Photo'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _categoryEmoji(String category) {
    // Used only as visual placeholder in colored container, not as icon
    switch (category) {
      case 'protein':
        return 'P';
      case 'carb':
        return 'C';
      case 'fat':
        return 'F';
      case 'vegetable':
        return 'V';
      case 'fruit':
        return 'Fr';
      case 'dairy':
        return 'D';
      case 'condiment':
        return 'S';
      default:
        return '?';
    }
  }

  Widget _buildShimmer(ThemeData theme) {
    return AILoadingWidget(
      iconName: 'search',
      title: 'Analyzing your ingredients...',
      statusMessages: const [
        'Scanning photo for food items...',
        'Reading product labels...',
        'Estimating quantities...',
        'Categorizing ingredients...',
      ],
      stepLabels: const ['Scan', 'Detect', 'Classify'],
      activeStep: 1,
      skeletonBuilder: (t) => IngredientListSkeleton(theme: t),
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
              iconName: 'search_off',
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            SizedBox(height: 2.h),
            Text(
              'No food items detected',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try taking a clearer photo with food items\nspread out on a flat surface',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 3.h),
            FilledButton.icon(
              onPressed: widget.onRetakePhoto,
              icon: const CustomIconWidget(
                iconName: 'camera_alt',
                size: 20,
                color: Colors.white,
              ),
              label: const Text('Retake Photo'),
            ),
          ],
        ),
      ),
    );
  }
}

