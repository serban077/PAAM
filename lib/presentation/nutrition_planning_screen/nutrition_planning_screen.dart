import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../services/nutrition_service.dart';
import '../../services/supabase_service.dart';
import './widgets/calorie_goal_widget.dart';
import './widgets/macro_progress_widget.dart';
import './widgets/add_food_modal_widget.dart';
import './widgets/simple_meal_card.dart';
import './widgets/water_tracking_card.dart';
import './widgets/ai_meal_plan_section.dart';
import './widgets/barcode_scanner_page.dart';

class NutritionPlanningScreen extends StatefulWidget {
  const NutritionPlanningScreen({super.key});

  @override
  State<NutritionPlanningScreen> createState() =>
      _NutritionPlanningScreenState();
}

class _NutritionPlanningScreenState extends State<NutritionPlanningScreen> {
  final _nutritionService = NutritionService(Supabase.instance.client);
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

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  Future<void> _loadNutritionData() async {
    setState(() => _isLoading = true);
    try {
      final meals = await _nutritionService.getUserMeals(_selectedDate);
      final totals = await _nutritionService.getDailyNutritionTotals(
        _selectedDate,
      );
      final goal = await _nutritionService.getDailyGoal(_selectedDate);

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

  void _showAddFoodModal(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFoodModalWidget(
        mealType: mealType,
        onFoodAdded: () {
          Navigator.pop(context);
          _loadNutritionData();
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getMealsForType(String mealType) {
    return _meals.where((meal) => meal['meal_type'] == mealType).toList();
  }

  /// Edit meal quantity and update in database
  Future<void> _editMealQuantity(String mealId, double newQuantity) async {
    try {
      await SupabaseService.instance.client
          .from('user_meals')
          .update({'serving_quantity': newQuantity})
          .eq('id', mealId);
      
      // Reload data to refresh calories
      await _loadNutritionData();
      
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

  Future<void> _openBarcodeScanner() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          onFoodAdded: _loadNutritionData,
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
    _loadNutritionData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Planning'),
        centerTitle: true,
        actions: [
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
                    SizedBox(height: 3.h),

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