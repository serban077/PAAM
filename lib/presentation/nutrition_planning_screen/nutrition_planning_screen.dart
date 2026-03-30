import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../routes/app_routes.dart';
import '../../services/nutrition_service.dart';
import '../../services/supabase_service.dart';
import '../../services/app_cache_service.dart';
import './widgets/calorie_goal_widget.dart';
import './widgets/macro_progress_widget.dart';
import './widgets/add_food_modal_widget.dart';
import './widgets/simple_meal_card.dart';
import './widgets/water_tracking_card.dart';
import './widgets/ai_meal_plan_section.dart';
import './widgets/barcode_scanner_page.dart';
import '../../widgets/custom_icon_widget.dart';

class NutritionPlanningScreen extends StatefulWidget {
  const NutritionPlanningScreen({super.key});

  @override
  State<NutritionPlanningScreen> createState() =>
      _NutritionPlanningScreenState();
}

class _NutritionPlanningScreenState extends State<NutritionPlanningScreen> {
  final _nutritionService = NutritionService(Supabase.instance.client);
  final _cache = AppCacheService.instance;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  Map<String, double> _dailyTotals = {
    'total_calories': 0.0,
    'total_protein_g': 0.0,
    'total_carbs_g': 0.0,
    'total_fat_g': 0.0,
  };

  Map<String, dynamic> _dailyGoal = {
    'calorie_goal': 2000,
    'protein_goal_g': 150,
    'carbs_goal_g': 200,
    'fat_goal_g': 67,
  };

  List<Map<String, dynamic>> _meals = [];

  String get _dateKey {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  Future<void> _loadNutritionData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      // Check cache first
      if (!forceRefresh) {
        final cached = _cache.getNutrition(_dateKey);
        if (cached != null) {
          setState(() {
            _meals = cached.meals;
            _dailyTotals = cached.dailyTotals;
            _dailyGoal = cached.dailyGoal;
            _isLoading = false;
          });
          return;
        }
      }

      // Parallel fetch
      final results = await Future.wait([
        _nutritionService.getUserMeals(_selectedDate),
        _nutritionService.getDailyNutritionTotals(_selectedDate),
        _nutritionService.getDailyGoal(_selectedDate),
      ]);

      final meals = results[0] as List<Map<String, dynamic>>;
      final totals = results[1] as Map<String, double>;
      final goal = results[2] as Map<String, dynamic>;

      // Update cache
      _cache.setNutrition(_dateKey, NutritionCacheData(
        meals: meals,
        dailyTotals: totals,
        dailyGoal: goal,
      ));

      if (!mounted) return;
      setState(() {
        _meals = meals;
        _dailyTotals = totals;
        _dailyGoal = goal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  /// Recalculate totals from local _meals list.
  /// Uses the same formula as the Supabase RPC: calories * serving_quantity / serving_size.
  void _recalculateTotals() {
    double totalCal = 0, totalP = 0, totalC = 0, totalF = 0;
    for (final meal in _meals) {
      final food = meal['food_database'] as Map<String, dynamic>?;
      if (food == null) continue;
      final qty = (meal['serving_quantity'] as num?)?.toDouble() ?? 0;
      final size = (food['serving_size'] as num?)?.toDouble() ?? 100;
      final factor = size > 0 ? qty / size : 0.0;
      totalCal += ((food['calories'] as num?)?.toDouble() ?? 0) * factor;
      totalP += ((food['protein_g'] as num?)?.toDouble() ?? 0) * factor;
      totalC += ((food['carbs_g'] as num?)?.toDouble() ?? 0) * factor;
      totalF += ((food['fat_g'] as num?)?.toDouble() ?? 0) * factor;
    }
    _dailyTotals = {
      'total_calories': totalCal,
      'total_protein_g': totalP,
      'total_carbs_g': totalC,
      'total_fat_g': totalF,
    };
    _cache.invalidateNutrition(_dateKey);
  }

  void _showAddFoodModal(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFoodModalWidget(
        mealType: mealType,
        onFoodAdded: () {
          Navigator.pop(context);
          _cache.invalidateNutrition(_dateKey);
          _loadNutritionData(forceRefresh: true);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getMealsForType(String mealType) {
    return _meals.where((meal) => meal['meal_type'] == mealType).toList();
  }

  /// Edit meal quantity — update DB then apply locally.
  Future<void> _editMealQuantity(String mealId, double newQuantity) async {
    try {
      await SupabaseService.instance.client
          .from('user_meals')
          .update({'serving_quantity': newQuantity})
          .eq('id', mealId);

      // Local update instead of full reload
      if (!mounted) return;
      setState(() {
        final idx = _meals.indexWhere((m) => m['id'] == mealId);
        if (idx != -1) {
          _meals[idx] = {..._meals[idx], 'serving_quantity': newQuantity};
        }
        _recalculateTotals();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quantity updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Delete a meal — update DB then remove locally.
  Future<void> _deleteMeal(String mealId) async {
    try {
      await _nutritionService.deleteMeal(mealId);
      if (!mounted) return;
      setState(() {
        _meals.removeWhere((m) => m['id'] == mealId);
        _recalculateTotals();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting meal: $e')),
        );
      }
    }
  }

  Future<void> _openBarcodeScanner() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          onFoodAdded: () {
            _cache.invalidateNutrition(_dateKey);
          },
        ),
      ),
    );
    if (!mounted) return;
    if (result == BarcodeScannerPage.kNotFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Product not found. Try adding it manually by name.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
    _loadNutritionData(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Planning'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add food to database',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context, rootNavigator: true).pushNamed(
                AppRoutes.userFoodSubmission,
                arguments: {'barcode': '', 'productName': ''},
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() => _selectedDate = picked);
                _loadNutritionData();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openBarcodeScanner,
        tooltip: 'Scan barcode',
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: _isLoading
          ? _buildSkeleton(context)
          : RefreshIndicator(
              onRefresh: _loadNutritionData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date display
                    Text(
                      DateFormat(
                        'EEEE, MMMM d, yyyy',
                        'en_US',
                      ).format(_selectedDate),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Calorie goal widget
                    CalorieGoalWidget(
                      dailyGoal: (_dailyGoal['calorie_goal'] ?? 2000).toDouble(),
                      consumed: _dailyTotals['total_calories']?.toDouble() ?? 0.0,
                    ),
                    SizedBox(height: 2.h),

                    // Macro progress
                    MacroProgressWidget(
                      label: 'Protein',
                      consumed: _dailyTotals['total_protein_g']?.toDouble() ?? 0.0,
                      target: (_dailyGoal['protein_goal_g'] ?? 150).toDouble(),
                      unit: 'g',
                      color: Colors.blue,
                    ),
                    SizedBox(height: 1.h),
                    MacroProgressWidget(
                      label: 'Carbohydrates',
                      consumed: _dailyTotals['total_carbs_g']?.toDouble() ?? 0.0,
                      target: (_dailyGoal['carbs_goal_g'] ?? 200).toDouble(),
                      unit: 'g',
                      color: Colors.orange,
                    ),
                    SizedBox(height: 1.h),
                    MacroProgressWidget(
                      label: 'Fats',
                      consumed: _dailyTotals['total_fat_g']?.toDouble() ?? 0.0,
                      target: (_dailyGoal['fat_goal_g'] ?? 67).toDouble(),
                      unit: 'g',
                      color: Colors.green,
                    ),
                    SizedBox(height: 3.h),

                    // Meal cards (4 simple cards)
                    SimpleMealCard(
                      title: 'Breakfast',
                      mealType: 'mic_dejun',
                      meals: _getMealsForType('mic_dejun'),
                      onAddFood: () => _showAddFoodModal('mic_dejun'),
                      onDeleteMeal: (mealId) async {
                        await _nutritionService.deleteMeal(mealId);
                        _loadNutritionData();
                      },
                      onEditMeal: _editMealQuantity,
                    ),
                    SizedBox(height: 1.5.h),

                    SimpleMealCard(
                      title: 'Lunch',
                      mealType: 'pranz',
                      meals: _getMealsForType('pranz'),
                      onAddFood: () => _showAddFoodModal('pranz'),
                      onDeleteMeal: (mealId) async {
                        await _nutritionService.deleteMeal(mealId);
                        _loadNutritionData();
                      },
                      onEditMeal: _editMealQuantity,
                    ),
                    SizedBox(height: 1.5.h),

                    SimpleMealCard(
                      title: 'Dinner',
                      mealType: 'cina',
                      meals: _getMealsForType('cina'),
                      onAddFood: () => _showAddFoodModal('cina'),
                      onDeleteMeal: (mealId) async {
                        await _nutritionService.deleteMeal(mealId);
                        _loadNutritionData();
                      },
                      onEditMeal: _editMealQuantity,
                    ),
                    SizedBox(height: 1.5.h),

                    SimpleMealCard(
                      title: 'Snack',
                      mealType: 'gustare_dimineata',
                      meals: _getMealsForType('gustare_dimineata'),
                      onAddFood: () => _showAddFoodModal('gustare_dimineata'),
                      onDeleteMeal: (mealId) async {
                        await _nutritionService.deleteMeal(mealId);
                        _loadNutritionData();
                      },
                      onEditMeal: _editMealQuantity,
                    ),
                    SizedBox(height: 2.h),

                    // Water tracking
                    const WaterTrackingCard(),
                    SizedBox(height: 2.h),

                    // Photo Recipe CTA
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                      ),
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final result = await Navigator.of(context,
                                  rootNavigator: true)
                              .pushNamed(AppRoutes.photoRecipe);
                          if (result == true && mounted) {
                            _loadNutritionData();
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 2.h),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(2.5.w),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: CustomIconWidget(
                                  iconName: 'camera_alt',
                                  size: 24,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Generate Recipe from Photo',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 0.3.h),
                                    Text(
                                      'Snap your ingredients, get recipes',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CustomIconWidget(
                                iconName: 'chevron_right',
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // AI Meal Plan Section
                    AIMealPlanSection(
                      onMealAdded: _loadNutritionData,
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.surfaceContainerHighest.withAlpha(76);
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 2.h, width: 50.w, color: color),
          SizedBox(height: 2.h),
          Container(
            height: 12.h,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          ),
          SizedBox(height: 2.h),
          ...List.generate(3, (_) => Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Container(
              height: 3.h,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            ),
          )),
          SizedBox(height: 3.h),
          ...List.generate(4, (_) => Padding(
            padding: EdgeInsets.only(bottom: 1.5.h),
            child: Container(
              height: 10.h,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            ),
          )),
        ],
      ),
    );
  }
}