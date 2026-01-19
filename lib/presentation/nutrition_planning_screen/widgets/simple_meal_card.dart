import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Simple Meal Card - Streamlined meal display with integrated add button
class SimpleMealCard extends StatelessWidget {
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

  double get totalCalories {
    return meals.fold(0.0, (sum, meal) {
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
                  title,
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
                  onPressed: onAddFood,
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
            if (meals.isNotEmpty) ...[
              SizedBox(height: 1.h),
              ...meals.map((meal) => _buildFoodItem(meal, context)),
            ] else ...[
              SizedBox(height: 0.5.h),
              Text(
                'Apasă + pentru a adăuga',
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

  Widget _buildFoodItem(Map<String, dynamic> meal, BuildContext context) {
    final food = meal['food_database'] as Map<String, dynamic>?;
    if (food == null) return const SizedBox.shrink();

    final name = food['name'] ?? 'Unknown';
    final quantity = (meal['serving_quantity'] as num?)?.toDouble() ?? 0;
    final unit = food['serving_unit'] ?? 'g';
    final calories = (food['calories'] as num?)?.toDouble() ?? 0;
    final servingSize = (food['serving_size'] as num?)?.toDouble() ?? 100;
    final itemCalories = (calories * quantity / servingSize).toStringAsFixed(0);

    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${quantity.toStringAsFixed(0)}$unit • $itemCalories kcal',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEditMeal != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                  onPressed: () => _showEditQuantityDialog(context, meal, name, quantity, unit),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              SizedBox(width: 1.w),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () => onDeleteMeal(meal['id']),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
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
    final controller = TextEditingController(text: currentQuantity.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editează cantitatea'),
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
                labelText: 'Cantitate ($unit)',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = double.tryParse(controller.text);
              if (newQuantity != null && newQuantity > 0 && onEditMeal != null) {
                onEditMeal!(meal['id'], newQuantity);
                Navigator.pop(context);
              }
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }
}
