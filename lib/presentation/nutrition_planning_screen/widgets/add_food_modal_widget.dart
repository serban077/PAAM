import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/nutrition_service.dart';
import '../../../services/open_food_facts_service.dart';
import '../../../services/usda_food_service.dart';

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

class _AddFoodModalWidgetState extends State<AddFoodModalWidget>
    with SingleTickerProviderStateMixin {
  final _nutritionService = NutritionService(Supabase.instance.client);
  final _offService = OpenFoodFactsService();
  final _usdaService = UsdaFoodService();

  final _searchController = TextEditingController();
  final _servingController = TextEditingController(text: '100');

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedFood;

  bool _isSearching = false;
  bool _isLoadingExternal = false;
  bool _isAdding = false;
  bool _hasMoreOffPages = false;

  int _offPage = 1;
  String? _lastQuery;

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _shimmerAnimation = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _searchController.dispose();
    _servingController.dispose();
    super.dispose();
  }

  // ── Search ───────────────────────────────────────────────────────────────

  Future<void> _searchFood(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _hasMoreOffPages = false;
        _isLoadingExternal = false;
      });
      return;
    }

    _lastQuery = query;
    _offPage = 1;

    // Tier 1: local Supabase — instant, shown immediately
    setState(() => _isSearching = true);

    List<Map<String, dynamic>> localResults = [];
    try {
      localResults = await _nutritionService.searchFood(query);
    } catch (_) {}

    // Abort if the query changed while we were awaiting
    if (_lastQuery != query || !mounted) return;

    setState(() {
      _searchResults =
          localResults.map((f) => {...f, '_source': 'Local'}).toList();
      _isSearching = false;
      _isLoadingExternal = true;
      _hasMoreOffPages = false;
    });

    // Tier 2 + 3: external APIs always run in parallel — local results already visible above
    {
      final results = await Future.wait([
        _offService.searchFoods(query, page: 1),
        _usdaService.searchFoods(query),
      ]);

      if (_lastQuery != query || !mounted) return;

      final offResults = results[0];
      final usdaResults = results[1];

      // Deduplicate: local results take priority; external deduped by name|brand
      final seen = <String>{};
      for (final food in _searchResults) {
        seen.add(_foodKey(food));
      }

      final combined = List<Map<String, dynamic>>.from(_searchResults);
      for (final food in [...offResults, ...usdaResults]) {
        final key = _foodKey(food);
        if (!seen.contains(key)) {
          seen.add(key);
          combined.add(food);
        }
      }

      setState(() {
        _searchResults = combined;
        _isLoadingExternal = false;
        _hasMoreOffPages = offResults.length >= 20;
      });
    }
  }

  Future<void> _loadMoreOff() async {
    if (_lastQuery == null) return;
    _offPage++;
    setState(() => _isLoadingExternal = true);

    final more = await _offService.searchFoods(_lastQuery!, page: _offPage);

    if (!mounted) return;

    final seen = _searchResults.map(_foodKey).toSet();
    final newItems = more
        .where((f) => !seen.contains(_foodKey(f)))
        .toList();

    setState(() {
      _searchResults = [..._searchResults, ...newItems];
      _isLoadingExternal = false;
      _hasMoreOffPages = more.length >= 20;
    });
  }

  String _foodKey(Map<String, dynamic> food) {
    final name = (food['name'] as String? ?? '').toLowerCase().trim();
    final brand = (food['brand'] as String? ?? '').toLowerCase().trim();
    return '$name|$brand';
  }

  // ── Add food ─────────────────────────────────────────────────────────────

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
      Map<String, dynamic> food = _selectedFood!;

      // Cache external foods into Supabase to obtain a real DB id
      final source = food['_source'] as String? ?? 'Local';
      if (source != 'Local') {
        food = await _nutritionService.cacheExternalFood(food);
      }

      await _nutritionService.logMeal(
        foodId: food['id'] as String,
        mealType: widget.mealType,
        servingQuantity: servingQuantity,
      );
      widget.onFoodAdded();
    } catch (e) {
      setState(() => _isAdding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding food: $e')),
        );
      }
    }
  }

  // ── Selection helper ──────────────────────────────────────────────────────

  bool _isFoodSelected(Map<String, dynamic> food) {
    if (_selectedFood == null) return false;
    final selId = _selectedFood!['id'];
    final foodId = food['id'];
    if (selId != null && foodId != null) return selId == foodId;
    // External foods not yet cached: compare by name + brand
    return _selectedFood!['name'] == food['name'] &&
        _selectedFood!['brand'] == food['brand'];
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildSourceBadge(String source) {
    final theme = Theme.of(context);
    final Color color;
    if (source == 'USDA') {
      color = theme.colorScheme.secondary;
    } else if (source == 'Open Food Facts') {
      color = theme.colorScheme.primary;
    } else {
      color = theme.colorScheme.primary;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        source,
        style: TextStyle(
          color: color,
          fontSize: 8.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFoodListItem(Map<String, dynamic> food) {
    final enteredAmount = double.tryParse(_servingController.text) ?? 100.0;
    final servingSize = (food['serving_size'] as num?)?.toDouble() ?? 100.0;
    final multiplier = enteredAmount / servingSize;

    final calories =
        ((food['calories'] as num?)?.toDouble() ?? 0) * multiplier;
    final protein =
        ((food['protein_g'] as num?)?.toDouble() ?? 0) * multiplier;
    final carbs = ((food['carbs_g'] as num?)?.toDouble() ?? 0) * multiplier;
    final fat = ((food['fat_g'] as num?)?.toDouble() ?? 0) * multiplier;
    final unit = food['serving_unit'] as String? ?? 'g';
    final source = food['_source'] as String? ?? 'Local';
    final brand = food['brand'] as String?;

    return ListTile(
      title: Text(
        food['name'] as String? ?? '',
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (brand != null && brand.isNotEmpty)
            Text(
              brand,
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          SizedBox(height: 0.3.h),
          _buildSourceBadge(source),
          SizedBox(height: 0.4.h),
          Text(
            '${calories.round()} kcal | P: ${protein.toStringAsFixed(1)}g | C: ${carbs.toStringAsFixed(1)}g | F: ${fat.toStringAsFixed(1)}g',
            style: TextStyle(
              fontSize: 11.sp,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
            ),
          ),
          Text(
            'Per ${enteredAmount.toStringAsFixed(0)}$unit',
            style: TextStyle(
              fontSize: 10.sp,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
      trailing: _isFoodSelected(food)
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 20.sp,
            )
          : null,
      onTap: () => setState(() {
        _selectedFood = food;
        _servingController.text =
            (food['serving_size'] as num?)?.toStringAsFixed(0) ?? '100';
      }),
    );
  }

  Widget _buildSkeletonRow() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return Opacity(
          opacity: _shimmerAnimation.value,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 1.8.h,
                        width: 50.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 0.8.h),
                      Container(
                        height: 1.4.h,
                        width: 70.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final hasTyped = _searchController.text.length >= 2;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasTyped ? Icons.search_off : Icons.search,
              size: 12.w,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              hasTyped
                  ? 'No results found.\nTry a different spelling or scan the barcode.'
                  : 'Start searching for foods',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
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

          // ── Search bar ────────────────────────────────────────────────────
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
              onChanged: _searchFood,
            ),
          ),

          // ── Amount + Add button (shown when a food is selected) ───────────
          if (_selectedFood != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _servingController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        suffix: Text(
                          _selectedFood!['serving_unit'] as String? ?? 'g',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
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

          // ── Results list ──────────────────────────────────────────────────
          Expanded(
            child: _searchResults.isEmpty && !_isLoadingExternal
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _searchResults.length +
                        (_isLoadingExternal ? 3 : 0) +
                        (_hasMoreOffPages && !_isLoadingExternal ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Real result rows
                      if (index < _searchResults.length) {
                        return Column(
                          children: [
                            _buildFoodListItem(_searchResults[index]),
                            if (index < _searchResults.length - 1 ||
                                _isLoadingExternal ||
                                _hasMoreOffPages)
                              const Divider(height: 1),
                          ],
                        );
                      }

                      // Skeleton rows while external APIs load
                      if (_isLoadingExternal) {
                        return _buildSkeletonRow();
                      }

                      // "Load more" button
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 1.5.h,
                          horizontal: 4.w,
                        ),
                        child: OutlinedButton(
                          onPressed: _loadMoreOff,
                          child: const Text('Load more results'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
