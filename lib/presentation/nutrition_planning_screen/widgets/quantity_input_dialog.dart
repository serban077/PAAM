import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

/// Quantity Input Dialog - Enter food quantity
class QuantityInputDialog extends StatefulWidget {
  final Map<String, dynamic> food;

  const QuantityInputDialog({super.key, required this.food});

  @override
  State<QuantityInputDialog> createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<QuantityInputDialog> {
  final _quantityController = TextEditingController(text: '100');
  double _calculatedCalories = 0;
  double _calculatedProtein = 0;
  double _calculatedCarbs = 0;
  double _calculatedFat = 0;

  @override
  void initState() {
    super.initState();
    _calculateNutrition();
  }

  void _calculateNutrition() {
    final quantity = double.tryParse(_quantityController.text) ?? 100;
    final servingSize = (widget.food['serving_size'] as num?)?.toDouble() ?? 100;
    final multiplier = quantity / servingSize;

    setState(() {
      _calculatedCalories = ((widget.food['calories'] ?? 0) * multiplier);
      _calculatedProtein = ((widget.food['protein_g'] ?? 0) * multiplier);
      _calculatedCarbs = ((widget.food['carbs_g'] ?? 0) * multiplier);
      _calculatedFat = ((widget.food['fat_g'] ?? 0) * multiplier);
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servingUnit = widget.food['serving_unit'] ?? 'g';

    return AlertDialog(
      title: Text(widget.food['name'] ?? 'Aliment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: InputDecoration(
              labelText: 'Cantitate',
              suffixText: servingUnit,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => _calculateNutrition(),
            autofocus: true,
          ),
          SizedBox(height: 3.h),
          
          // Nutrition summary
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildNutritionRow(
                  'Calorii',
                  '${_calculatedCalories.toStringAsFixed(0)} kcal',
                  Colors.orange,
                ),
                SizedBox(height: 1.h),
                _buildNutritionRow(
                  'Proteine',
                  '${_calculatedProtein.toStringAsFixed(1)} g',
                  Colors.blue,
                ),
                SizedBox(height: 1.h),
                _buildNutritionRow(
                  'Carbohidrați',
                  '${_calculatedCarbs.toStringAsFixed(1)} g',
                  Colors.green,
                ),
                SizedBox(height: 1.h),
                _buildNutritionRow(
                  'Grăsimi',
                  '${_calculatedFat.toStringAsFixed(1)} g',
                  Colors.red,
                ),
              ],
            ),
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
            final quantity = double.tryParse(_quantityController.text);
            if (quantity != null && quantity > 0) {
              Navigator.pop(context, {
                'food': widget.food,
                'quantity': quantity,
                'calories': _calculatedCalories,
                'protein': _calculatedProtein,
                'carbs': _calculatedCarbs,
                'fat': _calculatedFat,
              });
            }
          },
          child: const Text('Adaugă'),
        ),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
          ),
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
