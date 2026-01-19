import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/body_measurements_service.dart';
import '../../../services/supabase_service.dart';
import 'package:intl/intl.dart';

/// Body Measurements Card with 3D interactive model
/// Shows measurement points on body with add buttons
class BodyMeasurementsCard extends StatefulWidget {
  const BodyMeasurementsCard({super.key});

  @override
  State<BodyMeasurementsCard> createState() => _BodyMeasurementsCardState();
}

class _BodyMeasurementsCardState extends State<BodyMeasurementsCard> {
  final _measurementsService = BodyMeasurementsService();
  List<Map<String, dynamic>> _recentMeasurements = [];
  bool _isLoading = true;

  // Measurement types with Romanian labels
  final Map<String, String> _measurementLabels = {
    'head': 'Circumferință Cap',
    'neck': 'Circumferință Gât',
    'shoulders': 'Lățime Umeri',
    'chest': 'Circumferință Piept',
    'waist': 'Circumferință Talie',
    'hips': 'Circumferință Șolduri',
    'arm': 'Circumferință Braț',
    'forearm': 'Circumferință Antebraț',
    'thigh': 'Circumferință Coapsă',
    'calf': 'Circumferință Gambă',
  };

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);
    try {
      final measurements = await _measurementsService.getMeasurements(limit: 5);
      setState(() {
        _recentMeasurements = measurements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la încărcarea măsurătorilor: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          _buildBodyModel(theme),
          if (!_isLoading && _recentMeasurements.isNotEmpty)
            _buildRecentMeasurements(theme),
          if (!_isLoading && _recentMeasurements.isEmpty)
            _buildEmptyState(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Măsurători Corporale',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
            onPressed: () => _showAddMeasurementDialog(),
            tooltip: 'Adaugă măsurătoare',
          ),
        ],
      ),
    );
  }

  Widget _buildBodyModel(ThemeData theme) {
    return Container(
      height: 50.h, // 50% of screen height
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.primary.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Placeholder for body image
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.accessibility_new,
                  size: 30.h,
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Model 3D Corp',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Measurement buttons positioned on body
          ..._buildMeasurementButtons(theme),
        ],
      ),
    );
  }

  List<Widget> _buildMeasurementButtons(ThemeData theme) {
    // Positions are relative (0.0 to 1.0) to container size
    final measurementPoints = [
      {'type': 'head', 'top': 0.08, 'left': 0.5},
      {'type': 'neck', 'top': 0.15, 'left': 0.5},
      {'type': 'shoulders', 'top': 0.20, 'left': 0.5},
      {'type': 'chest', 'top': 0.28, 'left': 0.5},
      {'type': 'waist', 'top': 0.40, 'left': 0.5},
      {'type': 'hips', 'top': 0.50, 'left': 0.5},
      {'type': 'arm', 'top': 0.30, 'left': 0.25},
      {'type': 'forearm', 'top': 0.42, 'left': 0.20},
      {'type': 'thigh', 'top': 0.60, 'left': 0.40},
      {'type': 'calf', 'top': 0.75, 'left': 0.45},
    ];

    return measurementPoints.map((point) {
      return Positioned(
        top: (point['top'] as double) * 50.h,
        left: (point['left'] as double) * 92.w - 16, // Center the button
        child: _buildMeasurementButton(
          point['type'] as String,
          theme,
        ),
      );
    }).toList();
  }

  Widget _buildMeasurementButton(String type, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showAddMeasurementDialog(measurementType: type),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildRecentMeasurements(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Text(
            'Măsurători Recente',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ..._recentMeasurements.map((m) {
          final type = m['measurement_type'] as String;
          final value = (m['value'] as num).toDouble();
          final measuredAt = DateTime.parse(m['measured_at'] as String);
          final formattedDate = DateFormat('dd MMM').format(measuredAt);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.straighten,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(_measurementLabels[type] ?? type),
            subtitle: Text(formattedDate),
            trailing: Text(
              '${value.toStringAsFixed(1)} cm',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }).toList(),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.straighten,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            SizedBox(height: 1.h),
            Text(
              'Nicio măsurătoare adăugată încă',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Apasă pe butoanele + pentru a adăuga',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showAddMeasurementDialog({String? measurementType}) {
    showDialog(
      context: context,
      builder: (context) => AddMeasurementDialog(
        measurementType: measurementType,
        measurementLabels: _measurementLabels,
        onSave: (type, value) async {
          try {
            await _measurementsService.addMeasurement(
              measurementType: type,
              value: value,
            );
            await _loadMeasurements();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Măsurătoare salvată cu succes!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Eroare: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

/// Dialog for adding a new measurement
class AddMeasurementDialog extends StatefulWidget {
  final String? measurementType;
  final Map<String, String> measurementLabels;
  final Function(String type, double value) onSave;

  const AddMeasurementDialog({
    super.key,
    this.measurementType,
    required this.measurementLabels,
    required this.onSave,
  });

  @override
  State<AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<AddMeasurementDialog> {
  final _valueController = TextEditingController();
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.measurementType;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Adaugă Măsurătoare'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.measurementType == null)
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Tip Măsurătoare',
                border: OutlineInputBorder(),
              ),
              items: widget.measurementLabels.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedType = value),
            )
          else
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.straighten, color: theme.colorScheme.primary),
                  SizedBox(width: 12),
                  Text(
                    widget.measurementLabels[widget.measurementType] ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 16),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Valoare',
              suffixText: 'cm',
              border: OutlineInputBorder(),
              hintText: 'Ex: 75.5',
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Anulează'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(_valueController.text);
            if (value != null && _selectedType != null) {
              widget.onSave(_selectedType!, value);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Introduceți o valoare validă'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text('Salvează'),
        ),
      ],
    );
  }
}
