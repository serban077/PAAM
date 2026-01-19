import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';
import '../../../services/ai_nutrition_service.dart';

/// AI Meal Plan Section - Display and manage AI-generated meal recommendations
class AIMealPlanSection extends StatefulWidget {
  final VoidCallback onMealAdded;

  const AIMealPlanSection({
    super.key,
    required this.onMealAdded,
  });

  @override
  State<AIMealPlanSection> createState() => _AIMealPlanSectionState();
}

class _AIMealPlanSectionState extends State<AIMealPlanSection> {
  Map<String, dynamic>? _aiPlan;
  bool _isGenerating = false;
  bool _isLoadingPlan = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPlan();
  }

  /// Load saved AI plan from Supabase
  Future<void> _loadSavedPlan() async {
    setState(() => _isLoadingPlan = true);

    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoadingPlan = false);
        return;
      }

      final response = await SupabaseService.instance.client
          .from('ai_nutrition_plans')
          .select('plan_data, daily_calories_goal')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _aiPlan = response['plan_data'] as Map<String, dynamic>;
          _isLoadingPlan = false;
        });
        debugPrint('Loaded saved AI nutrition plan');
      } else {
        setState(() => _isLoadingPlan = false);
        debugPrint('No saved AI nutrition plan found');
      }
    } catch (e) {
      debugPrint('Error loading saved plan: $e');
      setState(() => _isLoadingPlan = false);
    }
  }

  Future<void> _generatePlan() async {
    setState(() => _isGenerating = true);

    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final aiService = AINutritionService();
      final plan = await aiService.generateMealPlan(userId);

      // Save plan to Supabase for persistence
      final dailyCaloriesGoal = plan['nutrition_plan']?['daily_calories_goal'] as int?;
      
      await SupabaseService.instance.client
          .from('ai_nutrition_plans')
          .insert({
            'user_id': userId,
            'plan_data': plan,
            'daily_calories_goal': dailyCaloriesGoal,
            'is_active': true,
          });

      if (mounted) {
        setState(() {
          _aiPlan = plan;
          _isGenerating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan generat și salvat cu succes!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addMealToDay(Map<String, dynamic> meal) async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final mealType = meal['type'] as String;
      final foods = meal['foods'] as List<dynamic>;

      for (var food in foods) {
        final foodName = food['name'] as String;
        final quantity = (food['quantity'] as num).toDouble();

        final foodData = await SupabaseService.instance.client
            .from('food_database')
            .select('id')
            .eq('name', foodName)
            .maybeSingle();

        if (foodData != null) {
          await SupabaseService.instance.client.from('user_meals').insert({
            'user_id': userId,
            'food_id': foodData['id'],
            'meal_type': mealType,
            'serving_quantity': quantity,
            'consumed_at': DateTime.now().toIso8601String(),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masă adăugată cu succes!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onMealAdded();
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
    final theme = Theme.of(context);

    if (_isLoadingPlan) {
      return Card(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header card
        Card(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Plan Alimentar AI',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  'Plan personalizat bazat pe caloriile și macronutrienții tăi',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 2.h),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generatePlan,
                  icon: _isGenerating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_aiPlan == null ? 'Generează Plan AI' : 'Regenerează Plan'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 5.h),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // AI meal recommendations
        if (_aiPlan != null && _aiPlan!.containsKey('nutrition_plan')) ...[
          SizedBox(height: 2.h),
          Builder(
            builder: (context) {
              final nutritionPlan = _aiPlan!['nutrition_plan'] as Map<String, dynamic>;
              final meals = nutritionPlan['meals'] as List<dynamic>?;
              if (meals == null) return const SizedBox.shrink();
              
              return Column(
                children: meals.map((meal) {
                  return _buildAIMealCard(meal as Map<String, dynamic>);
                }).toList(),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAIMealCard(Map<String, dynamic> meal) {
    final theme = Theme.of(context);
    final mealName = meal['meal_name'] as String? ?? 'Masă';
    final options = meal['options'] as List<dynamic>?;
    
    if (options == null || options.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          mealName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${options.length} opțiuni disponibile',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        leading: Icon(
          Icons.restaurant,
          color: theme.colorScheme.secondary,
        ),
        children: options.map((option) {
          return _buildMealOption(
            option as Map<String, dynamic>,
            mealName,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealOption(Map<String, dynamic> option, String mealName) {
    final theme = Theme.of(context);
    final optionId = option['option_id'] as int? ?? 1;
    final description = option['description'] as String? ?? '';
    final calories = (option['calories'] as num?)?.toDouble() ?? 0;
    final protein = (option['protein_g'] as num?)?.toDouble() ?? 0;
    final carbs = (option['carbs_g'] as num?)?.toDouble() ?? 0;
    final fat = (option['fat_g'] as num?)?.toDouble() ?? 0;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opțiunea $optionId',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${calories.toStringAsFixed(0)} kcal',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'P: ${protein.toStringAsFixed(0)}g | C: ${carbs.toStringAsFixed(0)}g | F: ${fat.toStringAsFixed(0)}g',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ElevatedButton.icon(
            onPressed: () => _addOptionToDay(option, mealName),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adaugă la Mese'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 4.h),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addOptionToDay(Map<String, dynamic> option, String mealName) async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Map meal names to meal types (must match Supabase enum exactly)
      // Supabase enum values: mic_dejun, gustare_dimineata, pranz, gustare_dupa_amiaza, cina, gustare_seara
      final mealTypeMap = {
        'Mic dejun': 'mic_dejun',
        'Mic Dejun': 'mic_dejun',
        'Prânz': 'pranz',
        'Pranz': 'pranz',
        'Cină': 'cina',
        'Cina': 'cina',
        'Gustare': 'gustare_dimineata', // Default to morning snack
        'Gustare dimineață': 'gustare_dimineata',
        'Gustare după-amiază': 'gustare_dupa_amiaza',
        'Gustare seară': 'gustare_seara',
      };

      final mealType = mealTypeMap[mealName] ?? 'gustare_dimineata';
      final description = option['description'] as String? ?? '';
      final calories = (option['calories'] as num?)?.toInt() ?? 0;
      final protein = (option['protein_g'] as num?)?.toDouble() ?? 0;
      final carbs = (option['carbs_g'] as num?)?.toDouble() ?? 0;
      final fat = (option['fat_g'] as num?)?.toDouble() ?? 0;

      // Create custom food entry for this AI meal
      // IMPORTANT: serving_size=100 and serving_quantity=1 means 1 portion = 100g
      // Formula: calories * quantity / servingSize = 450 * 1 / 1 = 450 cal (correct!)
      // The calories value already represents the TOTAL for this meal
      final customFood = await SupabaseService.instance.client
          .from('food_database')
          .insert({
            'name': 'Plan AI - $mealName',
            'serving_size': 1, // 1 portion
            'serving_unit': 'porție',
            'calories': calories, // Total calories for the meal
            'protein_g': protein, // Total protein for the meal
            'carbs_g': carbs, // Total carbs for the meal
            'fat_g': fat, // Total fat for the meal
            'is_verified': false, // Mark as AI-generated
          })
          .select()
          .single();

      // Add to user_meals with quantity=1 (one full portion)
      await SupabaseService.instance.client.from('user_meals').insert({
        'user_id': userId,
        'food_id': customFood['id'],
        'meal_type': mealType,
        'serving_quantity': 1, // 1 portion = full meal
        'consumed_at': DateTime.now().toIso8601String(),
        'notes': description, // Store full description in notes
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Masă adăugată în $mealName!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onMealAdded(); // Refresh UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la adăugare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
