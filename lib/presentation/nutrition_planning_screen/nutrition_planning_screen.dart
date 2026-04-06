import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../routes/app_routes.dart';
import '../../services/nutrition_service.dart';
import '../../services/supabase_service.dart';
import '../../services/app_cache_service.dart';
import '../../theme/app_theme.dart';
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

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

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

      final results = await Future.wait([
        _nutritionService.getUserMeals(_selectedDate),
        _nutritionService.getDailyNutritionTotals(_selectedDate),
        _nutritionService.getDailyGoal(_selectedDate),
      ]);

      final meals = results[0] as List<Map<String, dynamic>>;
      final totals = results[1] as Map<String, double>;
      final goal = results[2] as Map<String, dynamic>;

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

  Future<void> _editMealQuantity(String mealId, double newQuantity) async {
    try {
      await SupabaseService.instance.client
          .from('user_meals')
          .update({'serving_quantity': newQuantity})
          .eq('id', mealId);

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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
          onFoodAdded: () => _cache.invalidateNutrition(_dateKey),
        ),
      ),
    );
    if (!mounted) return;
    if (result == BarcodeScannerPage.kNotFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not found. Try adding it manually by name.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
    _loadNutritionData(forceRefresh: true);
  }

  void _stepDate(int days) {
    final next = _selectedDate.add(Duration(days: days));
    if (days > 0 && next.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = next);
    _loadNutritionData();
  }

  Future<void> _pickDate() async {
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? _buildSkeleton(isDark)
          : Stack(
              fit: StackFit.expand,
              children: [
                // ── Gradient background ──
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [AppTheme.backgroundDark, AppTheme.primaryVariantDark]
                            : [AppTheme.primaryVariantLight, AppTheme.primaryLight],
                      ),
                    ),
                  ),
                ),
                // ── Content ──
                SafeArea(
                  child: Column(
                    children: [
                      _buildTitleBar(isDark),
                      _buildDateStepper(isDark),
                      SizedBox(height: 1.h),
                      CalorieGoalWidget(
                        dailyGoal: (_dailyGoal['calorie_goal'] ?? 2000).toDouble(),
                        consumed: _dailyTotals['total_calories']?.toDouble() ?? 0.0,
                        onGradient: true,
                      ),
                      SizedBox(height: 2.h),
                      // ── White content sheet ──
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            border: isDark
                                ? Border(
                                    top: BorderSide(
                                      color: AppTheme.primaryDark.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.35)
                                    : AppTheme.shadowLight,
                                blurRadius: 24,
                                offset: const Offset(0, -6),
                              ),
                            ],
                          ),
                          child: RefreshIndicator(
                            onRefresh: _loadNutritionData,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Drag handle ──
                                  Center(
                                    child: Container(
                                      width: 10.w,
                                      height: 0.5.h,
                                      margin: EdgeInsets.only(bottom: 2.h),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.15)
                                            : Colors.black.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  // ── Macro row ──
                                  _buildMacroRow(isDark),
                                  SizedBox(height: 2.5.h),
                                  // ── Quick actions ──
                                  _buildQuickActions(isDark),
                                  SizedBox(height: 2.5.h),
                                  // ── Meals section ──
                                  _buildSectionHeader('Today\'s Meals', isDark),
                                  SizedBox(height: 1.5.h),
                                  ..._buildMealCards(),
                                  SizedBox(height: 2.h),
                                  // ── Water tracking ──
                                  const WaterTrackingCard(),
                                  SizedBox(height: 2.h),
                                  // ── AI Meal Plan ──
                                  AIMealPlanSection(
                                    onMealAdded: _loadNutritionData,
                                  ),
                                  SizedBox(height: 2.h),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Header bar ──────────────────────────────────────────────────────────────

  Widget _buildTitleBar(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      child: Row(
        children: [
          SizedBox(width: 2.w),
          Text(
            'Nutrition',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Add food to DB
          IconButton(
            icon: const CustomIconWidget(iconName: 'add_circle_outline', size: 22, color: Colors.white),
            tooltip: 'Add food to database',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context, rootNavigator: true).pushNamed(
                AppRoutes.userFoodSubmission,
                arguments: {'barcode': '', 'productName': ''},
              );
            },
          ),
          // Calendar picker
          IconButton(
            icon: const CustomIconWidget(iconName: 'calendar_today', size: 20, color: Colors.white),
            onPressed: _pickDate,
          ),
        ],
      ),
    );
  }

  // ── Date stepper ────────────────────────────────────────────────────────────

  Widget _buildDateStepper(bool isDark) {
    final dateLabel = _isToday
        ? 'Today'
        : DateFormat('EEE, MMM d', 'en_US').format(_selectedDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const CustomIconWidget(iconName: 'chevron_left', size: 22, color: Colors.white),
          onPressed: () => _stepDate(-1),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.6.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
        IconButton(
          icon: CustomIconWidget(
            iconName: 'chevron_right',
            size: 22,
            color: _isToday
                ? Colors.white.withValues(alpha: 0.30)
                : Colors.white,
          ),
          onPressed: _isToday ? null : () => _stepDate(1),
        ),
      ],
    );
  }

  // ── Macro row ────────────────────────────────────────────────────────────────

  Widget _buildMacroRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: MacroProgressWidget(
            label: 'Protein',
            consumed: _dailyTotals['total_protein_g']?.toDouble() ?? 0.0,
            target: (_dailyGoal['protein_goal_g'] ?? 150).toDouble(),
            unit: 'g',
            color: const Color(0xFF2196F3),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: MacroProgressWidget(
            label: 'Carbs',
            consumed: _dailyTotals['total_carbs_g']?.toDouble() ?? 0.0,
            target: (_dailyGoal['carbs_goal_g'] ?? 200).toDouble(),
            unit: 'g',
            color: const Color(0xFFFF9800),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: MacroProgressWidget(
            label: 'Fat',
            consumed: _dailyTotals['total_fat_g']?.toDouble() ?? 0.0,
            target: (_dailyGoal['fat_goal_g'] ?? 67).toDouble(),
            unit: 'g',
            color: const Color(0xFF9C27B0),
          ),
        ),
      ],
    );
  }

  // ── Quick actions ────────────────────────────────────────────────────────────

  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Add', isDark),
        SizedBox(height: 1.5.h),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: 'qr_code_scanner',
                label: 'Scan',
                sublabel: 'Barcode',
                gradientColors: const [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                onTap: _openBarcodeScanner,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _QuickActionCard(
                icon: 'camera_alt',
                label: 'Photo',
                sublabel: 'Recipe',
                gradientColors: const [Color(0xFF1565C0), Color(0xFF1976D2)],
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final result = await Navigator.of(context, rootNavigator: true)
                      .pushNamed(AppRoutes.photoRecipe);
                  if (result == true) _loadNutritionData();
                },
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _QuickActionCard(
                icon: 'search',
                label: 'Search',
                sublabel: 'Food',
                gradientColors: isDark
                    ? [AppTheme.primaryVariantDark, AppTheme.primaryDark]
                    : [AppTheme.primaryVariantLight, AppTheme.primaryLight],
                onTap: () => _showAddFoodModal('mic_dejun'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Meal cards ───────────────────────────────────────────────────────────────

  List<Widget> _buildMealCards() {
    const meals = [
      ('Breakfast', 'mic_dejun', 'breakfast'),
      ('Lunch', 'pranz', 'lunch'),
      ('Dinner', 'cina', 'dinner'),
      ('Snack', 'gustare_dimineata', 'snack'),
    ];

    return meals.map((m) {
      final (title, type, _) = m;
      return Padding(
        padding: EdgeInsets.only(bottom: 1.5.h),
        child: RepaintBoundary(
          child: SimpleMealCard(
            title: title,
            mealType: type,
            meals: _getMealsForType(type),
            onAddFood: () => _showAddFoodModal(type),
            onDeleteMeal: _deleteMeal,
            onEditMeal: _editMealQuantity,
          ),
        ),
      );
    }).toList();
  }

  // ── Section header ────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
        letterSpacing: -0.2,
      ),
    );
  }

  // ── Skeleton ─────────────────────────────────────────────────────────────────

  Widget _buildSkeleton(bool isDark) {
    final shimmer = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [AppTheme.backgroundDark, AppTheme.primaryVariantDark]
                    : [AppTheme.primaryVariantLight, AppTheme.primaryLight],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              // Title bar skeleton
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                child: Row(children: [
                  Container(height: 3.h, width: 25.w, color: Colors.white.withValues(alpha: 0.25)),
                  const Spacer(),
                  Container(width: 8.w, height: 3.h, color: Colors.white.withValues(alpha: 0.25)),
                ]),
              ),
              // Date stepper skeleton
              Center(
                child: Container(
                  height: 4.h, width: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              // Calorie ring skeleton
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Container(
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              // White sheet skeleton
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      SizedBox(height: 2.h),
                      // Macro row skeleton
                      Row(children: List.generate(3, (i) => Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 2 ? 2.w : 0),
                          height: 10.h,
                          decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(16)),
                        ),
                      ))),
                      SizedBox(height: 2.h),
                      // Quick actions skeleton
                      Row(children: List.generate(3, (i) => Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 2 ? 2.w : 0),
                          height: 9.h,
                          decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(16)),
                        ),
                      ))),
                      SizedBox(height: 2.h),
                      ...List.generate(4, (_) => Container(
                        height: 8.h, margin: EdgeInsets.only(bottom: 1.5.h),
                        decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(14)),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Quick action card ─────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final String icon;
  final String label;
  final String sublabel;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 9.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(iconName: icon, size: 22, color: Colors.white),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 9.sp,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
