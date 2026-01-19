import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/ai_plan_models.dart';
import '../../../data/services/ai_plan_service.dart';
import 'grammage_input_dialog.dart';

class FoodSearchDialog extends StatefulWidget {
  final Function(LoggedFood) onLogFood;

  const FoodSearchDialog({
    super.key,
    required this.onLogFood,
  });

  @override
  State<FoodSearchDialog> createState() => _FoodSearchDialogState();
}

class _FoodSearchDialogState extends State<FoodSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final AIPlanService _aiPlanService = AIPlanService();
  
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  Future<void> _searchFood(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _aiPlanService.searchFood(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSearching = false;
      });
    }
  }

  void _selectFood(FoodItem food) {
    showDialog(
      context: context,
      builder: (context) => GrammageInputDialog(
        foodItem: food,
        onConfirm: (loggedFood) {
          widget.onLogFood(loggedFood);
          Navigator.pop(context); // Close grammage dialog
          Navigator.pop(context); // Close search dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logged ${loggedFood.calories} calories'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 70.h,
        padding: EdgeInsets.all(2.h),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Search Food',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
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
            
            SizedBox(height: 1.h),
            
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for food...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchFood(value);
                  }
                });
              },
            ),
            
            SizedBox(height: 2.h),
            
            // Search results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 1.h),
            Text('Error: $_errorMessage'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey),
            SizedBox(height: 1.h),
            Text(
              _searchController.text.isEmpty
                  ? 'Start typing to search for food'
                  : 'No results found',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.restaurant,
              color: Theme.of(context).primaryColor,
            ),
          ),
          title: Text(
            food.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${food.caloriesPer100g} cal per 100g',
            style: GoogleFonts.inter(fontSize: 11.sp),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _selectFood(food),
        );
      },
    );
  }
}
