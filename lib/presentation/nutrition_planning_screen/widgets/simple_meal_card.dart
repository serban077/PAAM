import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

/// Simple Meal Card - Streamlined meal display with integrated add button
/// Supports marking individual food items as eaten with local state tracking
class SimpleMealCard extends StatefulWidget {
  final String title;
  final String mealType;
  final List<Map<String, dynamic>> meals;
  final VoidCallback onAddFood;
  final Function(String) onDeleteMeal;
  final Function(String, double)? onEditMeal; // mealId, newQuantity

  const SimpleMealCard({
    super.key,
    required this.title,
    required this.mealType,
    required this.meals,
    required this.onAddFood,
    required this.onDeleteMeal,
    this.onEditMeal,
  });

  @override
  State<SimpleMealCard> createState() => _SimpleMealCardState();
}

class _SimpleMealCardState extends State<SimpleMealCard> {
  final Set<String> _eatenMealIds = {};

  double get totalCalories {
    return widget.meals.fold(0.0, (sum, meal) {
      final food = meal['food_database'] as Map<String, dynamic>?;
      if (food != null) {
        final quantity = (meal['serving_quantity'] as num?)?.toDouble() ?? 1;
        final servingSize = (food['serving_size'] as num?)?.toDouble() ?? 100;
        final calories = (food['calories'] as num?)?.toDouble() ?? 0;
        return sum + (calories * quantity / servingSize);
      }
      return sum;
    });
  }

  void _toggleEaten(String mealId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_eatenMealIds.contains(mealId)) {
        _eatenMealIds.remove(mealId);
      } else {
        _eatenMealIds.add(mealId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  onPressed: widget.onAddFood,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 1.h),

            // Calories display
            Text(
              '${totalCalories.toStringAsFixed(0)} kcal',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Foods list or empty state
            if (widget.meals.isNotEmpty) ...[
              SizedBox(height: 1.h),
              ...widget.meals.map(
                (meal) => _buildFoodItem(meal, context, theme),
              ),
            ] else ...[
              SizedBox(height: 0.5.h),
              Text(
                'Tap + to add food',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(
    Map<String, dynamic> meal,
    BuildContext context,
    ThemeData theme,
  ) {
    final food = meal['food_database'] as Map<String, dynamic>?;
    if (food == null) return const SizedBox.shrink();

    final mealId = meal['id'] as String? ?? '';
    final isEaten = _eatenMealIds.contains(mealId);
    final name = food['name'] ?? 'Unknown';
    final quantity = (meal['serving_quantity'] as num?)?.toDouble() ?? 0;
    final unit = food['serving_unit'] ?? 'g';
    final calories = (food['calories'] as num?)?.toDouble() ?? 0;
    final servingSize = (food['serving_size'] as num?)?.toDouble() ?? 100;
    final itemCalories = (calories * quantity / servingSize).toStringAsFixed(0);

    return Opacity(
      opacity: isEaten ? 0.5 : 1.0,
      child: Padding(
        padding: EdgeInsets.only(bottom: 0.8.h),
        child: Row(
          children: [
            // Eaten checkbox — minimum 44pt tap target
            GestureDetector(
              onTap: () => _toggleEaten(mealId),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isEaten
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isEaten
                        ? theme.colorScheme.primary
                        : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                    child: isEaten
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
            // Food info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      decoration: isEaten ? TextDecoration.lineThrough : null,
                      color: isEaten ? Colors.grey : null,
                    ),
                  ),
                  Text(
                    '${quantity.toStringAsFixed(0)}$unit • $itemCalories kcal',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                      decoration: isEaten ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onEditMeal != null)
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.blue,
                    ),
                    onPressed: () => _showEditQuantityDialog(
                      context,
                      meal,
                      name,
                      quantity,
                      unit,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                SizedBox(width: 1.w),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                  onPressed: () => widget.onDeleteMeal(meal['id']),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditQuantityDialog(
    BuildContext context,
    Map<String, dynamic> meal,
    String foodName,
    double currentQuantity,
    String unit,
  ) {
    final controller = TextEditingController(
      text: currentQuantity.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit quantity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              foodName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity ($unit)',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = double.tryParse(controller.text);
              if (newQuantity != null &&
                  newQuantity > 0 &&
                  widget.onEditMeal != null) {
                widget.onEditMeal!(meal['id'], newQuantity);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
