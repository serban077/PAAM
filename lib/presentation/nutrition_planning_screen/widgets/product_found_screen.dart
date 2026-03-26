import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../services/nutrition_service.dart';
import '../../../../services/supabase_service.dart';
import '../../../../widgets/custom_image_widget.dart';

/// Full-screen page shown after a successful barcode scan.
/// Displays product macros, quantity input, meal type selector and Add button.
class ProductFoundScreen extends StatefulWidget {
  /// Row from `food_database` — must include `id`, `name`, `calories`,
  /// `protein_g`, `carbs_g`, `fat_g`, `serving_size`, `serving_unit`.
  final Map<String, dynamic> food;

  /// Called after the meal is successfully logged so the parent refreshes.
  final VoidCallback onFoodAdded;

  const ProductFoundScreen({
    super.key,
    required this.food,
    required this.onFoodAdded,
  });

  @override
  State<ProductFoundScreen> createState() => _ProductFoundScreenState();
}

class _ProductFoundScreenState extends State<ProductFoundScreen> {
  final _nutritionService =
      NutritionService(SupabaseService.instance.client);
  final _qtyController = TextEditingController();

  String? _selectedMealType;
  bool _isAdding = false;

  static const _mealTypes = [
    ('Breakfast', 'mic_dejun'),
    ('Lunch', 'pranz'),
    ('Dinner', 'cina'),
    ('Snack', 'gustare_dimineata'),
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────
  double get _servingSize =>
      (widget.food['serving_size'] as num? ?? 100).toDouble();
  double get _kcalPer100 =>
      (widget.food['calories'] as num? ?? 0).toDouble();
  double get _proteinPer100 =>
      (widget.food['protein_g'] as num? ?? 0).toDouble();
  double get _carbsPer100 =>
      (widget.food['carbs_g'] as num? ?? 0).toDouble();
  double get _fatPer100 =>
      (widget.food['fat_g'] as num? ?? 0).toDouble();

  double get _qty => double.tryParse(_qtyController.text) ?? _servingSize;
  double _scaled(double per100) => per100 * _qty / _servingSize;

  @override
  void initState() {
    super.initState();
    _qtyController.text = _servingSize.toStringAsFixed(0);
    _qtyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  // ── Add meal ──────────────────────────────────────────────────────────────
  Future<void> _addToMeal() async {
    if (_selectedMealType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meal type.')),
      );
      return;
    }
    final qty = double.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity.')),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      await _nutritionService.logMeal(
        foodId: widget.food['id'] as String,
        mealType: _selectedMealType!,
        servingQuantity: qty,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      widget.onFoodAdded();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAdding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = widget.food;
    final unit = food['serving_unit'] as String? ?? 'g';
    final imageUrl = food['image_front_url'] as String?;
    final name = food['name'] as String? ?? 'Unknown product';
    final brand = (food['brand'] as String? ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Scrollable content ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product header
                  _buildProductHeader(
                      theme, name, brand, imageUrl, unit),
                  SizedBox(height: 2.5.h),

                  // "User Added" badge
                  if (food['is_user_contributed'] == true) ...[
                    SizedBox(height: 1.h),
                    Chip(
                      label: const Text('User Added'),
                      labelStyle: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onTertiary,
                      ),
                      backgroundColor: theme.colorScheme.tertiary,
                      padding: EdgeInsets.symmetric(
                          horizontal: 1.w, vertical: 0),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    SizedBox(height: 1.h),
                  ],

                  // Macro chips — per 100g reference
                  Text(
                    'Per 100$unit',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  SizedBox(height: 0.8.h),
                  _MacroChipsRow(
                    kcal: _kcalPer100,
                    protein: _proteinPer100,
                    carbs: _carbsPer100,
                    fat: _fatPer100,
                  ),

                  // Detailed macros expandable (only when present)
                  if (food['detailed_macros'] != null) ...[
                    SizedBox(height: 1.h),
                    _DetailedMacrosExpansion(
                      detailedMacros: food['detailed_macros']
                          as Map<String, dynamic>,
                      qty: _qty,
                      servingSize: _servingSize,
                    ),
                  ],

                  SizedBox(height: 3.h),
                  Divider(color: theme.dividerColor),
                  SizedBox(height: 2.h),

                  // Quantity input
                  Text('Quantity', style: theme.textTheme.labelLarge),
                  SizedBox(height: 1.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: InputDecoration(
                            suffixText: unit,
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 3.w, vertical: 1.5.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_scaled(_kcalPer100).toStringAsFixed(0)} kcal',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'for ${_qty.toStringAsFixed(0)}$unit',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 1.5.h),

                  // Live macro breakdown for current qty
                  Row(
                    children: [
                      _MiniMacro(
                          'Protein', _scaled(_proteinPer100), theme),
                      SizedBox(width: 4.w),
                      _MiniMacro('Carbs', _scaled(_carbsPer100), theme),
                      SizedBox(width: 4.w),
                      _MiniMacro('Fat', _scaled(_fatPer100), theme),
                    ],
                  ),
                  SizedBox(height: 3.h),

                  // Meal type
                  Text('Meal', style: theme.textTheme.labelLarge),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 0.8.h,
                    children: _mealTypes.map((pair) {
                      final (label, key) = pair;
                      final selected = _selectedMealType == key;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedMealType = key),
                        selectedColor: theme.colorScheme.tertiary
                            .withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selected
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.onSurface,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),

          // ── Fixed bottom CTA ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 2.h),
              child: SizedBox(
                width: double.infinity,
                height: 6.5.h,
                child: ElevatedButton(
                  onPressed: _isAdding ? null : _addToMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                    foregroundColor: theme.colorScheme.onTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isAdding
                      ? SizedBox(
                          height: 3.h,
                          width: 3.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onTertiary,
                          ),
                        )
                      : Text(
                          'Add to Meal',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader(ThemeData theme, String name, String brand,
      String? imageUrl, String unit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: CustomImageWidget(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fastfood_outlined,
                    size: 9.w,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (brand.isNotEmpty) ...[
                SizedBox(height: 0.5.h),
                Text(
                  brand,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _MacroChipsRow extends StatelessWidget {
  final double kcal, protein, carbs, fat;
  const _MacroChipsRow(
      {required this.kcal,
      required this.protein,
      required this.carbs,
      required this.fat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 1.5.w,
      runSpacing: 0.6.h,
      children: [
        _Chip('${kcal.toStringAsFixed(0)} kcal', theme.colorScheme.primary),
        _Chip('P ${protein.toStringAsFixed(1)}g', const Color(0xFF1565C0)),
        _Chip('C ${carbs.toStringAsFixed(1)}g', const Color(0xFFFF6F00)),
        _Chip('F ${fat.toStringAsFixed(1)}g', theme.colorScheme.error),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniMacro extends StatelessWidget {
  final String label;
  final double value;
  final ThemeData theme;
  const _MiniMacro(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${value.toStringAsFixed(1)}g',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Expandable tile showing detailed macros from JSONB `detailed_macros`.
/// Values are shown per 100g and scaled to the current entered quantity.
class _DetailedMacrosExpansion extends StatelessWidget {
  final Map<String, dynamic> detailedMacros;
  final double qty;
  final double servingSize;

  const _DetailedMacrosExpansion({
    required this.detailedMacros,
    required this.qty,
    required this.servingSize,
  });

  double _scaled(String key) {
    final v = (detailedMacros[key] as num?)?.toDouble() ?? 0;
    return v * qty / servingSize;
  }

  double _per100(String key) =>
      (detailedMacros[key] as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rows = <({String label, String key, String unit})>[
      (label: 'Sugar', key: 'sugar_g', unit: 'g'),
      (label: 'Saturated Fat', key: 'saturated_fat_g', unit: 'g'),
      (label: 'Unsaturated Fat', key: 'unsaturated_fat_g', unit: 'g'),
      (label: 'Fiber', key: 'fiber_g', unit: 'g'),
      (label: 'Sodium', key: 'sodium_mg', unit: 'mg'),
    ].where((r) => detailedMacros[r.key] != null).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          'Full Nutrition Info',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(bottom: 0.5.h),
        children: rows.map((r) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 0.3.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.label, style: theme.textTheme.bodySmall),
                Text(
                  '${_per100(r.key).toStringAsFixed(1)}${r.unit} '
                  '(${_scaled(r.key).toStringAsFixed(1)}${r.unit})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
