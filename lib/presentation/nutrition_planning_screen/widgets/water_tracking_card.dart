import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Water Tracking Card - Track daily water consumption
class WaterTrackingCard extends StatefulWidget {
  const WaterTrackingCard({super.key});

  @override
  State<WaterTrackingCard> createState() => _WaterTrackingCardState();
}

class _WaterTrackingCardState extends State<WaterTrackingCard> {
  int _consumedWater = 0; // ml
  final int _goalWater = 2500; // ml
  static const String _waterKey = 'daily_water_ml';

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString('water_date');
    
    // Reset if it's a new day
    if (savedDate != today) {
      await prefs.setInt(_waterKey, 0);
      await prefs.setString('water_date', today);
      if (mounted) setState(() => _consumedWater = 0);
    } else {
      final water = prefs.getInt(_waterKey) ?? 0;
      if (mounted) setState(() => _consumedWater = water);
    }
  }

  Future<void> _saveWaterData(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setInt(_waterKey, ml);
    await prefs.setString('water_date', today);
  }

  Future<void> _addWater() async {
    final controller = TextEditingController(text: '250');
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adaugă Apă'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: 'Cantitate (ml)',
            suffixText: 'ml',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () {
              final ml = int.tryParse(controller.text);
              if (ml != null && ml > 0) {
                Navigator.pop(context, ml);
              }
            },
            child: const Text('Adaugă'),
          ),
        ],
      ),
    );

    if (result != null) {
      final newTotal = _consumedWater + result;
      setState(() => _consumedWater = newTotal);
      await _saveWaterData(newTotal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_consumedWater / _goalWater * 100).clamp(0, 100);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue, size: 24),
                    SizedBox(width: 2.w),
                    Text(
                      'Apă Consumată',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: Colors.blue,
                    size: 28,
                  ),
                  onPressed: _addWater,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              '$_consumedWater / $_goalWater ml',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 12,
                backgroundColor: Colors.blue[100],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 100 ? Colors.green : Colors.blue,
                ),
              ),
            ),
            SizedBox(height: 0.8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (progress >= 100)
                  Text(
                    'Obiectiv atins! 🎉',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
