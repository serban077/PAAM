import 'package:flutter/material.dart';
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
          SnackBar(content: Text('Eroare la încărcarea datelor: $e')),
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
            content: Text('Cantitate actualizată!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificare Nutriție'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        'EEEE, d MMMM yyyy',
                        'ro_RO',
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
                      label: 'Proteine',
                      consumed: _dailyTotals['total_protein_g']?.toDouble() ?? 0.0,
                      target: (_dailyGoal['protein_goal_g'] ?? 150).toDouble(),
                      unit: 'g',
                      color: Colors.blue,
                    ),
                    SizedBox(height: 1.h),
                    MacroProgressWidget(
                      label: 'Carbohidrați',
                      consumed: _dailyTotals['total_carbs_g']?.toDouble() ?? 0.0,
                      target: (_dailyGoal['carbs_goal_g'] ?? 200).toDouble(),
                      unit: 'g',
                      color: Colors.orange,
                    ),
                    SizedBox(height: 1.h),
                    MacroProgressWidget(
                      label: 'Grăsimi',
                      consumed: _dailyTotals['total_fat_g']?.toDouble() ?? 0.0,
                      target: (_dailyGoal['fat_goal_g'] ?? 67).toDouble(),
                      unit: 'g',
                      color: Colors.green,
                    ),
                    SizedBox(height: 3.h),

                    // Meal cards (4 simple cards)
                    SimpleMealCard(
                      title: 'Mic Dejun',
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
                      title: 'Prânz',
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
                      title: 'Cină',
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
                      title: 'Gustare',
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
}