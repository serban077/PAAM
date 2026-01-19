import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';

/// Weight Progress Card - Shows progress towards target weight
class WeightProgressCard extends StatefulWidget {
  const WeightProgressCard({super.key});

  @override
  State<WeightProgressCard> createState() => _WeightProgressCardState();
}

class _WeightProgressCardState extends State<WeightProgressCard> {
  bool _isLoading = true;
  double _startWeight = 0;
  double _currentWeight = 0;
  double _targetWeight = 0;

  @override
  void initState() {
    super.initState();
    _loadWeightData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when widget becomes visible again (e.g., returning from Profile)
    _loadWeightData();
  }

  Future<void> _loadWeightData() async {
    try {
      setState(() => _isLoading = true);
      
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Get profile data
      final profile = await SupabaseService.instance.client
          .from('user_profiles')
          .select('weight_kg, current_weight_kg, target_weight_kg')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _startWeight = (profile['weight_kg'] as num?)?.toDouble() ?? 0;
          // Use current_weight_kg directly from profile (updated when user saves)
          _currentWeight = (profile['current_weight_kg'] as num?)?.toDouble() ?? _startWeight;
          _targetWeight = (profile['target_weight_kg'] as num?)?.toDouble() ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading weight data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Calculate progress
    final totalChange = _startWeight - _targetWeight;
    final currentChange = _startWeight - _currentWeight;
    final progress = totalChange != 0 
        ? (currentChange / totalChange * 100).clamp(0, 100)
        : 0.0;
    final remaining = _currentWeight - _targetWeight;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progres către Obiectiv',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            
            // Target weight (shown as "Start" for goal reference)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Obiectiv:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${_targetWeight.toStringAsFixed(1)} kg',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 20,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 80 ? Colors.green : Colors.blue,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Center(
              child: Text(
                '${progress.toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: progress >= 80 ? Colors.green : Colors.blue,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            
            // Current and target
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curent',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${_currentWeight.toStringAsFixed(1)} kg',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.grey[400],
                  size: 24.sp,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Țintă',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${_targetWeight.toStringAsFixed(1)} kg',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 2.h),
            
            // Remaining
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: remaining > 0 ? Colors.orange[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    remaining > 0 ? Icons.trending_down : Icons.check_circle,
                    color: remaining > 0 ? Colors.orange : Colors.green,
                    size: 20.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    remaining > 0
                        ? 'Rămas: ${remaining.toStringAsFixed(1)} kg'
                        : 'Obiectiv atins! 🎉',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: remaining > 0 ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
