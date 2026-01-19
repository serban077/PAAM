import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';
import '../../../core/app_export.dart';

/// Body Measurements Card Widget
/// Displays silhouette with measurement points
class BodyMeasurementsCard extends StatefulWidget {
  const BodyMeasurementsCard({super.key});

  @override
  State<BodyMeasurementsCard> createState() => _BodyMeasurementsCardState();
}

class _BodyMeasurementsCardState extends State<BodyMeasurementsCard> {
  bool _isLoading = true;
  Map<String, double>? _latestMeasurements;

  @override
  void initState() {
    super.initState();
    _loadLatestMeasurements();
  }

  Future<void> _loadLatestMeasurements() async {
    try {
      setState(() => _isLoading = true);
      
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await SupabaseService.instance.client
          .from('body_measurements')
          .select()
          .eq('user_id', userId)
          .order('measurement_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (response != null) {
            _latestMeasurements = {
              'weight': (response['weight_kg'] as num?)?.toDouble() ?? 0,
              'neck': (response['neck_cm'] as num?)?.toDouble() ?? 0,
              'shoulders': (response['shoulders_cm'] as num?)?.toDouble() ?? 0,
              'chest': (response['chest_cm'] as num?)?.toDouble() ?? 0,
              'waist': (response['waist_cm'] as num?)?.toDouble() ?? 0,
              'hips': (response['hips_cm'] as num?)?.toDouble() ?? 0,
            };
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading measurements: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addMeasurement(String bodyPart) async {
    final controller = TextEditingController();
    
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Măsurătoare ${_getBodyPartLabel(bodyPart)}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Valoare (cm)',
            suffixText: 'cm',
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
              final value = double.tryParse(controller.text);
              if (value != null && value > 0 && value < 300) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveMeasurement(bodyPart, result);
    }
  }

  Future<void> _saveMeasurement(String bodyPart, double value) async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Get today's measurement or create new
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final existing = await SupabaseService.instance.client
          .from('body_measurements')
          .select('id')
          .eq('user_id', userId)
          .eq('measurement_date', dateStr)
          .maybeSingle();

      final columnName = '${bodyPart}_cm';

      if (existing != null) {
        // Update existing
        await SupabaseService.instance.client
            .from('body_measurements')
            .update({columnName: value})
            .eq('id', existing['id']);
      } else {
        // Create new
        await SupabaseService.instance.client
            .from('body_measurements')
            .insert({
              'user_id': userId,
              'measurement_date': dateStr,
              columnName: value,
            });
      }

      await _loadLatestMeasurements();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Măsurătoare salvată: ${_getBodyPartLabel(bodyPart)} = ${value.toStringAsFixed(1)} cm'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la salvare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getBodyPartLabel(String bodyPart) {
    const labels = {
      'neck': 'Gât',
      'shoulders': 'Umeri',
      'chest': 'Piept',
      'waist': 'Talie',
      'hips': 'Șolduri',
    };
    return labels[bodyPart] ?? bodyPart;
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

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Măsurători Corporale',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            
            // Silhouette with measurement points
            Center(
              child: SizedBox(
                width: 60.w,
                height: 60.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Real body silhouette image
                    Image.asset(
                      'assets/images/body_silhouette.png',
                      width: 60.w,
                      height: 60.h,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to icon if image not found
                        return Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.accessibility_new,
                            size: 40.w,
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        );
                      },
                    ),
                    
                    // Measurement buttons positioned on body
                    ..._buildMeasurementButtons(),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 3.h),
            
            // Latest measurements summary
            if (_latestMeasurements != null) ...[
              Text(
                'Ultimele măsurători:',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: _latestMeasurements!.entries
                    .where((e) => e.value > 0)
                    .map((e) => Chip(
                          label: Text('${_getBodyPartLabel(e.key)}: ${e.value.toStringAsFixed(1)} cm'),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMeasurementButtons() {
    return [
      // Neck - positioned at neck level
      Positioned(
        top: 10.h,
        child: _buildMeasurementButton('neck'),
      ),
      // Shoulders - positioned at shoulder level
      Positioned(
        top: 14.h,
        child: _buildMeasurementButton('shoulders'),
      ),
      // Chest - positioned at chest level
      Positioned(
        top: 21.h,
        child: _buildMeasurementButton('chest'),
      ),
      // Waist - positioned at waist level
      Positioned(
        top: 30.h,
        child: _buildMeasurementButton('waist'),
      ),
      // Hips - positioned at hip level
      Positioned(
        top: 37.h,
        child: _buildMeasurementButton('hips'),
      ),
    ];
  }

  Widget _buildMeasurementButton(String bodyPart) {
    final value = _latestMeasurements?[bodyPart] ?? 0;
    final hasValue = value > 0;

    return GestureDetector(
      onTap: () => _addMeasurement(bodyPart),
      child: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasValue ? Colors.green : Colors.blue,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          hasValue ? Icons.check : Icons.add,
          color: Colors.white,
          size: 18.sp,
        ),
      ),
    );
  }
}
