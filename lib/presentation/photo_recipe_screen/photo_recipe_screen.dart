import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../data/models/smart_recipe_models.dart';
import '../../services/food_recognition_service.dart';
import '../../services/smart_recipe_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'widgets/capture_step.dart';
import 'widgets/ingredients_review_step.dart';
import 'widgets/recipes_step.dart';
import 'widgets/log_recipe_step.dart';

/// 4-step wizard: Capture Photo → Review Ingredients → Browse Recipes → Log Meal.
class PhotoRecipeScreen extends StatefulWidget {
  const PhotoRecipeScreen({super.key});

  @override
  State<PhotoRecipeScreen> createState() => _PhotoRecipeScreenState();
}

class _PhotoRecipeScreenState extends State<PhotoRecipeScreen> {
  final _pageController = PageController();
  final _recognitionService = FoodRecognitionService();
  final _recipeService = SmartRecipeService();

  int _currentStep = 0;
  static const _totalSteps = 4;

  // Step 1 → 2 data
  bool _isRecognizing = false;
  List<DetectedIngredient> _ingredients = [];

  // Step 2 → 3 data
  bool _isGenerating = false;
  List<GeneratedRecipe> _recipes = [];

  // Step 3 → 4 data
  GeneratedRecipe? _selectedRecipe;

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ── Step 1 → 2: Capture → Recognize ─────────────────────────────────────

  Future<void> _onPhotoCaptured(Uint8List bytes) async {
    setState(() {
      _isRecognizing = true;
    });
    _goToStep(1);

    try {
      final result = await _recognitionService.recognizeIngredients(bytes);
      if (!mounted) return;
      setState(() {
        _ingredients = result.ingredients;
        _isRecognizing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecognizing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recognition failed: $e')),
      );
    }
  }

  // ── Step 2 → 3: Ingredients → Recipes ────────────────────────────────────

  Future<void> _onGenerateRecipes(List<DetectedIngredient> ingredients) async {
    setState(() {
      _ingredients = ingredients;
      _isGenerating = true;
    });
    _goToStep(2);

    try {
      final result = await _recipeService.generateRecipes(ingredients);
      if (!mounted) return;
      setState(() {
        _recipes = result.recipes;
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _recipes = [];
      });
      // Clean up nested Exception wrappers for user-facing message
      final msg = e.toString().replaceAll(RegExp(r'Exception:\s*'), '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.length > 120 ? '${msg.substring(0, 120)}...' : msg),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ── Step 3 → 4: Select recipe ────────────────────────────────────────────

  void _onRecipeSelected(GeneratedRecipe recipe) {
    setState(() => _selectedRecipe = recipe);
    _goToStep(3);
  }

  // ── Retry / back handlers ────────────────────────────────────────────────

  void _onRetakePhoto() {
    setState(() {
      _imageBytes = null;
      _ingredients = [];
      _recipes = [];
      _selectedRecipe = null;
    });
    _goToStep(0);
  }

  void _onBackToIngredients() {
    setState(() {
      _recipes = [];
      _selectedRecipe = null;
    });
    _goToStep(1);
  }

  void _onBackToRecipes() {
    setState(() => _selectedRecipe = null);
    _goToStep(2);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Photo Recipe'),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
          ),
          SizedBox(height: 1.h),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                CaptureStep(onPhotoCaptured: _onPhotoCaptured),
                IngredientsReviewStep(
                  ingredients: _ingredients,
                  isLoading: _isRecognizing,
                  onGenerateRecipes: _onGenerateRecipes,
                  onRetakePhoto: _onRetakePhoto,
                ),
                RecipesStep(
                  recipes: _recipes,
                  isLoading: _isGenerating,
                  onRecipeSelected: _onRecipeSelected,
                  onBack: _onBackToIngredients,
                  onRetry: () => _onGenerateRecipes(_ingredients),
                ),
                LogRecipeStep(
                  recipe: _selectedRecipe,
                  onBack: _onBackToRecipes,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  static const _labels = ['Capture', 'Ingredients', 'Recipes', 'Log Meal'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i == currentStep;
          final isCompleted = i < currentStep;

          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 28 : 22,
                      height: isActive ? 28 : 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        border: isActive
                            ? Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                width: 3,
                              )
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check,
                                size: 14, color: theme.colorScheme.onPrimary)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 0.4.h),
                    Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive || isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
