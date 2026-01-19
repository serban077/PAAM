import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/ai_plan_models.dart';

class GrammageInputDialog extends StatefulWidget {
  final FoodItem foodItem;
  final Function(LoggedFood) onConfirm;

  const GrammageInputDialog({
    super.key,
    required this.foodItem,
    required this.onConfirm,
  });

  @override
  State<GrammageInputDialog> createState() => _GrammageInputDialogState();
}

class _GrammageInputDialogState extends State<GrammageInputDialog> {
  final TextEditingController _gramsController = TextEditingController();
  int _calculatedCalories = 0;
  int _calculatedProtein = 0;
  int _calculatedCarbs = 0;
  int _calculatedFat = 0;

  void _calculateNutrition() {
    final grams = int.tryParse(_gramsController.text) ?? 0;
    if (grams > 0) {
      setState(() {
        _calculatedCalories = ((widget.foodItem.caloriesPer100g / 100) * grams).round();
        _calculatedProtein = ((widget.foodItem.proteinPer100g / 100) * grams).round();
        _calculatedCarbs = ((widget.foodItem.carbsPer100g / 100) * grams).round();
        _calculatedFat = ((widget.foodItem.fatPer100g / 100) * grams).round();
      });
    } else {
      setState(() {
        _calculatedCalories = 0;
        _calculatedProtein = 0;
        _calculatedCarbs = 0;
        _calculatedFat = 0;
      });
    }
  }

  void _confirmLog() {
    final grams = int.tryParse(_gramsController.text) ?? 0;
    if (grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final loggedFood = LoggedFood(
      foodName: widget.foodItem.name,
      grams: grams,
      calories: _calculatedCalories,
      protein: _calculatedProtein,
      carbs: _calculatedCarbs,
      fat: _calculatedFat,
      timestamp: DateTime.now(),
    );

    widget.onConfirm(loggedFood);
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        widget.foodItem.name,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How much did you eat?',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 2.h),
          
          // Grammage input
          TextField(
            controller: _gramsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Amount (grams)',
              suffixText: 'g',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => _calculateNutrition(),
          ),
          
          SizedBox(height: 2.h),
          
          // Calculated nutrition
          if (_calculatedCalories > 0) ...[
            Container(
              padding: EdgeInsets.all(1.5.h),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrition Info',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildNutritionRow('Calories', '$_calculatedCalories cal'),
                  _buildNutritionRow('Protein', '${_calculatedProtein}g'),
                  _buildNutritionRow('Carbs', '${_calculatedCarbs}g'),
                  _buildNutritionRow('Fat', '${_calculatedFat}g'),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _confirmLog,
          child: const Text('Log Food'),
        ),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.sp),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
