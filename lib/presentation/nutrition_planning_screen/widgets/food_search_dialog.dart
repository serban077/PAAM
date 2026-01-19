import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';

/// Food Search Dialog - Search and select foods from database
class FoodSearchDialog extends StatefulWidget {
  const FoodSearchDialog({super.key});

  @override
  State<FoodSearchDialog> createState() => _FoodSearchDialogState();
}

class _FoodSearchDialogState extends State<FoodSearchDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPopularFoods();
  }

  Future<void> _loadPopularFoods() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await SupabaseService.instance.client
          .from('food_database')
          .select()
          .eq('is_verified', true)
          .limit(20);

      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(results);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading popular foods: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchFood(String query) async {
    if (query.isEmpty) {
      _loadPopularFoods();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await SupabaseService.instance.client
          .from('food_database')
          .select()
          .ilike('name', '%$query%')
          .limit(30);

      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(results);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching foods: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        height: 80.h,
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Caută Aliment',
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

            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Caută aliment',
                hintText: 'Ex: pui, orez, mere...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadPopularFoods();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                _searchFood(value);
              },
            ),
            SizedBox(height: 2.h),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 60.sp,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Nu am găsit alimente',
                                style: theme.textTheme.titleMedium,
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Încearcă alt termen de căutare',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final food = _searchResults[index];
                            return _buildFoodTile(food);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodTile(Map<String, dynamic> food) {
    final theme = Theme.of(context);
    final name = food['name'] ?? 'Unknown';
    final calories = food['calories'] ?? 0;
    final servingSize = food['serving_size'] ?? 100;
    final servingUnit = food['serving_unit'] ?? 'g';
    final protein = (food['protein_g'] as num?)?.toDouble() ?? 0;
    final carbs = (food['carbs_g'] as num?)?.toDouble() ?? 0;
    final fat = (food['fat_g'] as num?)?.toDouble() ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        contentPadding: EdgeInsets.all(2.w),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.5.h),
            Text(
              '$calories kcal / $servingSize$servingUnit',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'P: ${protein.toStringAsFixed(1)}g • C: ${carbs.toStringAsFixed(1)}g • F: ${fat.toStringAsFixed(1)}g',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.add_circle,
          color: theme.colorScheme.primary,
          size: 28.sp,
        ),
        onTap: () => Navigator.pop(context, food),
      ),
    );
  }
}
