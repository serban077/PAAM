import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/nutrition_service.dart';

class AddFoodModalWidget extends StatefulWidget {
  final String mealType;
  final VoidCallback onFoodAdded;

  const AddFoodModalWidget({
    super.key,
    required this.mealType,
    required this.onFoodAdded,
  });

  @override
  State<AddFoodModalWidget> createState() => _AddFoodModalWidgetState();
}

class _AddFoodModalWidgetState extends State<AddFoodModalWidget> {
  final _nutritionService = NutritionService(Supabase.instance.client);
  final _searchController = TextEditingController();
  final _servingController = TextEditingController(text: '100');

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedFood;
  bool _isSearching = false;
  bool _isAdding = false;

  @override
  void dispose() {
    _searchController.dispose();
    _servingController.dispose();
    super.dispose();
  }

  Future<void> _searchFood(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _nutritionService.searchFood(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  Future<void> _addFood() async {
    if (_selectedFood == null) return;

    final servingQuantity = double.tryParse(_servingController.text);
    if (servingQuantity == null || servingQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      await _nutritionService.logMeal(
        foodId: _selectedFood!['id'],
        mealType: widget.mealType,
        servingQuantity: servingQuantity,
      );
      widget.onFoodAdded();
    } catch (e) {
      setState(() => _isAdding = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding food: $e')));
      }
    }
  }

  Widget _buildFoodListItem(Map<String, dynamic> food) {
    final enteredAmount = double.tryParse(_servingController.text) ?? 100.0;
    final servingSize = (food['serving_size'] as num?)?.toDouble() ?? 100.0;
    final multiplier = enteredAmount / servingSize;

    final calories = ((food['calories'] as num?)?.toDouble() ?? 0) * multiplier;
    final protein = ((food['protein_g'] as num?)?.toDouble() ?? 0) * multiplier;
    final carbs = ((food['carbs_g'] as num?)?.toDouble() ?? 0) * multiplier;
    final fat = ((food['fat_g'] as num?)?.toDouble() ?? 0) * multiplier;
    final unit = food['serving_unit'] as String? ?? 'g';

    return ListTile(
      title: Text(
        food['name'],
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (food['brand'] != null)
            Text(
              food['brand'],
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            ),
          SizedBox(height: 0.5.h),
          Text(
            '${calories.round()} kcal | P: ${protein.toStringAsFixed(1)}g | C: ${carbs.toStringAsFixed(1)}g | F: ${fat.toStringAsFixed(1)}g',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
          ),
          Text(
            'Per ${enteredAmount.toStringAsFixed(0)}$unit',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
      trailing: _selectedFood?['id'] == food['id']
          ? Icon(Icons.check_circle, color: Colors.green, size: 20.sp)
          : null,
      onTap: () => setState(() {
        _selectedFood = food;
        // Pre-fill with the food's reference serving size so user sees a sensible default
        _servingController.text =
            (food['serving_size'] as num?)?.toStringAsFixed(0) ?? '100';
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Food',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search foods...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? Padding(
                        padding: EdgeInsets.all(3.w),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
              ),
              onChanged: (value) => _searchFood(value),
            ),
          ),

          // Amount input
          if (_selectedFood != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _servingController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        suffix: Text(
                          _selectedFood!['serving_unit'] as String? ?? 'g',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  ElevatedButton(
                    onPressed: _isAdding ? null : _addFood,
                    child: _isAdding
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Add'),
                  ),
                ],
              ),
            ),

          SizedBox(height: 2.h),

          // Search results
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.length < 2
                          ? 'Start searching for foods'
                          : 'No results found',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      return _buildFoodListItem(_searchResults[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
