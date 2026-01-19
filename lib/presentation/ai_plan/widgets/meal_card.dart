import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/ai_plan_models.dart';

class MealCard extends StatefulWidget {
  final Meal meal;
  final Function(MealOption) onLogMealOption;

  const MealCard({
    super.key,
    required this.meal,
    required this.onLogMealOption,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                _getMealIcon(widget.meal.mealName),
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              widget.meal.mealName,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${widget.meal.options.length} options available',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
          ),
          
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 1.h),
              child: Column(
                children: widget.meal.options.map((option) {
                  return _buildMealOption(option);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMealOption(MealOption option) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(1.5.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Option ${option.optionId}',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            option.description,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 1.h),
          
          // Macros row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroChip('${option.calories} cal', Icons.local_fire_department, Colors.orange),
              _buildMacroChip('${option.proteinG}g protein', Icons.fitness_center, Colors.red),
              _buildMacroChip('${option.carbsG}g carbs', Icons.grain, Colors.brown),
              _buildMacroChip('${option.fatG}g fat', Icons.opacity, Colors.yellow[700]!),
            ],
          ),
          
          SizedBox(height: 1.h),
          
          // Log button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onLogMealOption(option);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged ${option.calories} calories'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Log this Meal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 9.sp),
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  IconData _getMealIcon(String mealName) {
    final name = mealName.toLowerCase();
    if (name.contains('breakfast')) return Icons.free_breakfast;
    if (name.contains('lunch')) return Icons.lunch_dining;
    if (name.contains('dinner')) return Icons.dinner_dining;
    if (name.contains('snack')) return Icons.cookie;
    return Icons.restaurant;
  }
}
