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
  final _servingController = TextEditingController(text: '1.0');

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
        ).showSnackBar(SnackBar(content: Text('Eroare la căutare: $e')));
      }
    }
  }

  Future<void> _addFood() async {
    if (_selectedFood == null) return;

    final servingQuantity = double.tryParse(_servingController.text);
    if (servingQuantity == null || servingQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduceți o cantitate validă')),
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
        ).showSnackBar(SnackBar(content: Text('Eroare la adăugare: $e')));
      }
    }
  }

  Widget _buildFoodListItem(Map<String, dynamic> food) {
    final servingQuantity = double.tryParse(_servingController.text) ?? 1.0;
    final servingSize = food['serving_size'] ?? 100.0;
    final multiplier = (servingQuantity * servingSize) / 100.0;

    final calories = (food['calories'] * multiplier).round();
    final protein = (food['protein_g'] * multiplier).toStringAsFixed(1);
    final carbs = (food['carbs_g'] * multiplier).toStringAsFixed(1);
    final fat = (food['fat_g'] * multiplier).toStringAsFixed(1);

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
            '$calories kcal | P: ${protein}g | C: ${carbs}g | F: ${fat}g',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
          ),
          Text(
            'Per ${servingQuantity.toStringAsFixed(1)} x ${servingSize.toStringAsFixed(0)}${food['serving_unit']}',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
      trailing: _selectedFood?['id'] == food['id']
          ? Icon(Icons.check_circle, color: Colors.green, size: 20.sp)
          : null,
      onTap: () => setState(() => _selectedFood = food),
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
                  'Adaugă Aliment',
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
                hintText: 'Caută alimente...',
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

          // Serving size input
          if (_selectedFood != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _servingController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cantitate',
                        suffix: Text(
                          'x ${_selectedFood!['serving_size']}${_selectedFood!['serving_unit']}',
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
                        : const Text('Adaugă'),
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
                          ? 'Începeți să căutați alimente'
                          : 'Nu s-au găsit rezultate',
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
