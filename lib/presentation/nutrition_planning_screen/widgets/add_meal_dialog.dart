import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';
import './food_search_dialog.dart';
import './quantity_input_dialog.dart';

/// Add Meal Dialog - Compose a complete meal with multiple foods
class AddMealDialog extends StatefulWidget {
  const AddMealDialog({super.key});

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  String _selectedMealType = 'mic_dejun';
  final List<Map<String, dynamic>> _selectedFoods = [];
  bool _isSaving = false;

  double get _totalCalories => _selectedFoods.fold(
        0,
        (sum, food) => sum + (food['calories'] as double),
      );

  double get _totalProtein => _selectedFoods.fold(
        0,
        (sum, food) => sum + (food['protein'] as double),
      );

  double get _totalCarbs => _selectedFoods.fold(
        0,
        (sum, food) => sum + (food['carbs'] as double),
      );

  double get _totalFat => _selectedFoods.fold(
        0,
        (sum, food) => sum + (food['fat'] as double),
      );

  Future<void> _addFood() async {
    // Step 1: Search and select food
    final selectedFood = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const FoodSearchDialog(),
    );

    if (selectedFood == null) return;

    // Step 2: Enter quantity
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => QuantityInputDialog(food: selectedFood),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedFoods.add(result);
      });
    }
  }

  Future<void> _saveMeal() async {
    if (_selectedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adaugă cel puțin un aliment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Save each food as a separate meal entry
      for (var foodData in _selectedFoods) {
        await SupabaseService.instance.client.from('user_meals').insert({
          'user_id': userId,
          'food_id': foodData['food']['id'],
          'meal_type': _selectedMealType,
          'serving_quantity': foodData['quantity'],
          'consumed_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to signal refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Masă salvată: ${_totalCalories.toStringAsFixed(0)} kcal',
            ),
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        height: 85.h,
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Adaugă Masă',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Meal type selector
            Text(
              'Tip masă',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 1.h),
            DropdownButtonFormField<String>(
              value: _selectedMealType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'mic_dejun', child: Text('Mic dejun')),
                DropdownMenuItem(value: 'pranz', child: Text('Prânz')),
                DropdownMenuItem(value: 'cina', child: Text('Cină')),
                DropdownMenuItem(value: 'snack', child: Text('Snack')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMealType = value);
                }
              },
            ),
            SizedBox(height: 2.h),

            // Add food button
            ElevatedButton.icon(
              onPressed: _addFood,
              icon: const Icon(Icons.add),
              label: const Text('Adaugă Aliment'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 6.h),
              ),
            ),
            SizedBox(height: 2.h),

            // Selected foods list
            Text(
              'Alimente adăugate (${_selectedFoods.length})',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 1.h),
            Expanded(
              child: _selectedFoods.isEmpty
                  ? Center(
                      child: Text(
                        'Nu ai adăugat alimente încă',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedFoods.length,
                      itemBuilder: (context, index) {
                        final foodData = _selectedFoods[index];
                        return _buildFoodItem(foodData, index);
                      },
                    ),
            ),
            SizedBox(height: 2.h),

            // Totals
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTotalRow('Total Calorii', '${_totalCalories.toStringAsFixed(0)} kcal', Colors.orange),
                  SizedBox(height: 0.5.h),
                  _buildTotalRow('Proteine', '${_totalProtein.toStringAsFixed(1)} g', Colors.blue),
                  SizedBox(height: 0.5.h),
                  _buildTotalRow('Carbohidrați', '${_totalCarbs.toStringAsFixed(1)} g', Colors.green),
                  SizedBox(height: 0.5.h),
                  _buildTotalRow('Grăsimi', '${_totalFat.toStringAsFixed(1)} g', Colors.red),
                ],
              ),
            ),
            SizedBox(height: 2.h),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMeal,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 6.h),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Salvează Masa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> foodData, int index) {
    final food = foodData['food'] as Map<String, dynamic>;
    final quantity = foodData['quantity'] as double;
    final calories = foodData['calories'] as double;
    final servingUnit = food['serving_unit'] ?? 'g';

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        title: Text(food['name'] ?? 'Unknown'),
        subtitle: Text('${quantity.toStringAsFixed(0)}$servingUnit • ${calories.toStringAsFixed(0)} kcal'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() => _selectedFoods.removeAt(index));
          },
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
