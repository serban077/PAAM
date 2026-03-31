import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../services/body_measurements_service.dart';
import '../../../services/app_cache_service.dart';

/// Body Measurements Card with improved design and positioned buttons
class BodyMeasurementsCard extends StatefulWidget {
  const BodyMeasurementsCard({super.key});

  @override
  State<BodyMeasurementsCard> createState() => _BodyMeasurementsCardState();
}

class _BodyMeasurementsCardState extends State<BodyMeasurementsCard> {
  final _measurementsService = BodyMeasurementsService();
  List<Map<String, dynamic>> _recentMeasurements = [];
  List<Map<String, dynamic>> _chartData = [];
  String _selectedChartMetric = 'waist';
  bool _isLoading = true;

  final Map<String, String> _measurementLabels = {
    'head': 'Head',
    'neck': 'Neck',
    'shoulders': 'Shoulders',
    'chest': 'Chest',
    'waist': 'Waist',
    'hips': 'Hips',
    'arm': 'Arm',
    'forearm': 'Forearm',
    'thigh': 'Thigh',
    'calf': 'Calf',
  };

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
    _loadChartData();
  }

  Future<void> _loadMeasurements() async {
    final cached = AppCacheService.instance.getBodyMeasurements();
    if (cached != null) {
      setState(() {
        _recentMeasurements = cached;
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final measurements = await _measurementsService.getMeasurements(limit: 5);
      AppCacheService.instance.setBodyMeasurements(measurements);
      setState(() {
        _recentMeasurements = measurements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading measurements: $e')),
        );
      }
    }
  }

  Future<void> _loadChartData() async {
    try {
      final data = await _measurementsService.getMeasurementHistory(
        _selectedChartMetric,
        limit: 30,
      );
      // Reverse to chronological order for chart
      if (mounted) {
        setState(() => _chartData = data.reversed.toList());
      }
    } catch (_) {
      // Chart data failure is non-critical
    }
  }

  void _selectChartMetric(String metric) {
    setState(() {
      _selectedChartMetric = metric;
      _chartData = [];
    });
    _loadChartData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          _buildBodyModel(theme),
          _buildMetricChips(theme),
          _buildChart(theme),
          if (!_isLoading && _recentMeasurements.isNotEmpty)
            _buildRecentMeasurements(theme),
          if (!_isLoading && _recentMeasurements.isEmpty)
            _buildEmptyState(theme),
        ],
      ),
    );
  }

  Widget _buildMetricChips(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Chart',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _measurementLabels.entries.map((entry) {
                final isSelected = _selectedChartMetric == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) => _selectChartMetric(entry.key),
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontSize: 12.sp,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    if (_chartData.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Center(
          child: Text(
            'No data yet for ${_measurementLabels[_selectedChartMetric] ?? _selectedChartMetric}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    final spots = _chartData.asMap().entries.map((e) {
      final value = (e.value['value'] as num).toDouble();
      return FlSpot(e.key.toDouble(), value);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return Padding(
      padding: EdgeInsets.fromLTRB(2.w, 0, 4.w, 2.h),
      child: SizedBox(
        height: 22.h,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: _chartData.length <= 6
                      ? 1
                      : (_chartData.length / 5).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= _chartData.length) {
                      return const SizedBox.shrink();
                    }
                    final date = DateTime.parse(
                      _chartData[idx]['measured_at'] as String,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('dd/MM').format(date),
                        style: TextStyle(fontSize: 8.sp, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: theme.colorScheme.primary,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: theme.colorScheme.primary,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
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
            'Body Measurements',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.cyan.shade600],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () => _showAddMeasurementDialog(),
              tooltip: 'Add measurement',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyModel(ThemeData theme) {
    return Container(
      height: 55.h,
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.cyan.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Body silhouette with CustomPaint
            Positioned.fill(
              child: CustomPaint(
                painter: BodySilhouettePainter(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                ),
              ),
            ),
            
            // Measurement buttons positioned on body
            ..._buildMeasurementButtons(theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMeasurementButtons(ThemeData theme) {
    // Staggered positions - trunk buttons alternating left/right for clarity
    final measurementPoints = [
      {'type': 'head', 'top': 0.04, 'left': 0.50, 'label': 'Head'},
      {'type': 'neck', 'top': 0.11, 'left': 0.42, 'label': 'Neck'},
      {'type': 'shoulders', 'top': 0.16, 'left': 0.58, 'label': 'Shoulders'},
      {'type': 'chest', 'top': 0.24, 'left': 0.38, 'label': 'Chest'},
      {'type': 'waist', 'top': 0.36, 'left': 0.62, 'label': 'Waist'},
      {'type': 'hips', 'top': 0.46, 'left': 0.38, 'label': 'Hips'},
      {'type': 'arm', 'top': 0.28, 'left': 0.22, 'label': 'Arm'},
      {'type': 'forearm', 'top': 0.40, 'left': 0.18, 'label': 'Forearm'},
      {'type': 'thigh', 'top': 0.56, 'left': 0.40, 'label': 'Thigh'},
      {'type': 'calf', 'top': 0.72, 'left': 0.42, 'label': 'Calf'},
    ];

    return measurementPoints.map((point) {
      return Positioned(
        top: (point['top'] as double) * 55.h,
        left: (point['left'] as double) * 96.w - 25,
        child: _buildMeasurementButton(
          point['type'] as String,
          point['label'] as String,
          theme,
        ),
      );
    }).toList();
  }

  Widget _buildMeasurementButton(String type, String label, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showAddMeasurementDialog(measurementType: type),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Button with gradient and shadow
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade400,
                  Colors.cyan.shade600,
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 3,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(height: 6),
          // Label with background
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue.shade50],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMeasurements(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Text(
            'Recent Measurements',
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
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.cyan.shade500],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.straighten, color: Colors.white, size: 20),
            ),
            title: Text(_measurementLabels[type] ?? type),
            subtitle: Text(formattedDate),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.cyan.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${value.toStringAsFixed(1)} cm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                ),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.cyan.shade100],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.straighten,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'No measurements added yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Tap the + buttons to add measurements',
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
    // Capture ScaffoldMessenger before showing dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
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
            AppCacheService.instance.invalidateBodyMeasurements();
            await _loadMeasurements();
            
            // Use captured scaffoldMessenger instead of context
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Measurement saved successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            // Use captured scaffoldMessenger instead of context
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}

/// Custom painter for body silhouette with arms down
class BodySilhouettePainter extends CustomPainter {
  final Color color;

  BodySilhouettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;

    // Head (circle)
    canvas.drawCircle(
      Offset(centerX, size.height * 0.06),
      size.width * 0.065,
      paint,
    );

    // Neck
    final neckPath = Path();
    neckPath.moveTo(centerX - size.width * 0.025, size.height * 0.10);
    neckPath.lineTo(centerX - size.width * 0.025, size.height * 0.14);
    neckPath.lineTo(centerX + size.width * 0.025, size.height * 0.14);
    neckPath.lineTo(centerX + size.width * 0.025, size.height * 0.10);
    neckPath.close();
    canvas.drawPath(neckPath, paint);

    // Torso (trapezoid shape - shoulders to hips)
    final torsoPath = Path();
    torsoPath.moveTo(centerX - size.width * 0.13, size.height * 0.16); // Left shoulder
    torsoPath.lineTo(centerX - size.width * 0.10, size.height * 0.36); // Left waist
    torsoPath.lineTo(centerX - size.width * 0.12, size.height * 0.46); // Left hip
    torsoPath.lineTo(centerX + size.width * 0.12, size.height * 0.46); // Right hip
    torsoPath.lineTo(centerX + size.width * 0.10, size.height * 0.36); // Right waist
    torsoPath.lineTo(centerX + size.width * 0.13, size.height * 0.16); // Right shoulder
    torsoPath.close();
    canvas.drawPath(torsoPath, paint);

    // Left arm (down along body)
    final leftArmPath = Path();
    // Upper arm (shoulder to elbow)
    leftArmPath.moveTo(centerX - size.width * 0.13, size.height * 0.17);
    leftArmPath.lineTo(centerX - size.width * 0.16, size.height * 0.34);
    leftArmPath.lineTo(centerX - size.width * 0.14, size.height * 0.35);
    leftArmPath.lineTo(centerX - size.width * 0.11, size.height * 0.18);
    leftArmPath.close();
    canvas.drawPath(leftArmPath, paint);

    // Left forearm (elbow to wrist)
    final leftForearmPath = Path();
    leftForearmPath.moveTo(centerX - size.width * 0.16, size.height * 0.34);
    leftForearmPath.lineTo(centerX - size.width * 0.17, size.height * 0.48);
    leftForearmPath.lineTo(centerX - size.width * 0.15, size.height * 0.48);
    leftForearmPath.lineTo(centerX - size.width * 0.14, size.height * 0.35);
    leftForearmPath.close();
    canvas.drawPath(leftForearmPath, paint);

    // Right arm (down along body)
    final rightArmPath = Path();
    // Upper arm (shoulder to elbow)
    rightArmPath.moveTo(centerX + size.width * 0.13, size.height * 0.17);
    rightArmPath.lineTo(centerX + size.width * 0.16, size.height * 0.34);
    rightArmPath.lineTo(centerX + size.width * 0.14, size.height * 0.35);
    rightArmPath.lineTo(centerX + size.width * 0.11, size.height * 0.18);
    rightArmPath.close();
    canvas.drawPath(rightArmPath, paint);

    // Right forearm (elbow to wrist)
    final rightForearmPath = Path();
    rightForearmPath.moveTo(centerX + size.width * 0.16, size.height * 0.34);
    rightForearmPath.lineTo(centerX + size.width * 0.17, size.height * 0.48);
    rightForearmPath.lineTo(centerX + size.width * 0.15, size.height * 0.48);
    rightForearmPath.lineTo(centerX + size.width * 0.14, size.height * 0.35);
    rightForearmPath.close();
    canvas.drawPath(rightForearmPath, paint);

    // Left leg (thigh)
    final leftThighPath = Path();
    leftThighPath.moveTo(centerX - size.width * 0.10, size.height * 0.46);
    leftThighPath.lineTo(centerX - size.width * 0.08, size.height * 0.68);
    leftThighPath.lineTo(centerX - size.width * 0.05, size.height * 0.68);
    leftThighPath.lineTo(centerX - size.width * 0.03, size.height * 0.46);
    leftThighPath.close();
    canvas.drawPath(leftThighPath, paint);

    // Left leg (calf)
    final leftCalfPath = Path();
    leftCalfPath.moveTo(centerX - size.width * 0.08, size.height * 0.68);
    leftCalfPath.lineTo(centerX - size.width * 0.07, size.height * 0.82);
    leftCalfPath.lineTo(centerX - size.width * 0.04, size.height * 0.82);
    leftCalfPath.lineTo(centerX - size.width * 0.05, size.height * 0.68);
    leftCalfPath.close();
    canvas.drawPath(leftCalfPath, paint);

    // Right leg (thigh)
    final rightThighPath = Path();
    rightThighPath.moveTo(centerX + size.width * 0.03, size.height * 0.46);
    rightThighPath.lineTo(centerX + size.width * 0.05, size.height * 0.68);
    rightThighPath.lineTo(centerX + size.width * 0.08, size.height * 0.68);
    rightThighPath.lineTo(centerX + size.width * 0.10, size.height * 0.46);
    rightThighPath.close();
    canvas.drawPath(rightThighPath, paint);

    // Right leg (calf)
    final rightCalfPath = Path();
    rightCalfPath.moveTo(centerX + size.width * 0.05, size.height * 0.68);
    rightCalfPath.lineTo(centerX + size.width * 0.04, size.height * 0.82);
    rightCalfPath.lineTo(centerX + size.width * 0.07, size.height * 0.82);
    rightCalfPath.lineTo(centerX + size.width * 0.08, size.height * 0.68);
    rightCalfPath.close();
    canvas.drawPath(rightCalfPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Add Measurement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.measurementType == null)
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Measurement Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.cyan.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
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
              labelText: 'Value',
              suffixText: 'cm',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'Ex: 75.5',
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            final value = double.tryParse(_valueController.text);
            if (value != null && _selectedType != null) {
              widget.onSave(_selectedType!, value);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please enter a valid value'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
