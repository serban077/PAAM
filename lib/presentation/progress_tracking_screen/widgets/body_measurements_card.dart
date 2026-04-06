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

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                color: Colors.grey.withValues(alpha: 0.2),
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
                  color: theme.colorScheme.primary.withValues(alpha:0.1),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.straighten,
                    color: theme.colorScheme.primary, size: 20),
              ),
              SizedBox(width: 3.w),
              Text(
                'Body Measurements',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: theme.colorScheme.primary),
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
      height: 65.h,
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final H = constraints.maxHeight;
            return Stack(
              children: [
                // 3D body silhouette
                Positioned.fill(
                  child: CustomPaint(
                    painter: _Body3DPainter(
                        primaryColor: theme.colorScheme.primary),
                  ),
                ),
                // Measurement dots + connector lines
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MeasLinePainter(
                        color: theme.colorScheme.primary),
                  ),
                ),
                // Label pills
                ..._kMeasPoints.map((p) {
                  const pillH = 22.0;
                  const pillW = 72.0;
                  final dotY = p.fracY * H;
                  return Positioned(
                    top: dotY - pillH / 2,
                    left: p.onLeft ? 2 : null,
                    right: p.onLeft ? null : 2,
                    child: GestureDetector(
                      onTap: () =>
                          _showAddMeasurementDialog(measurementType: p.type),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: pillW,
                        height: pillH,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface
                              .withValues(alpha: 0.93),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
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
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.straighten,
                  color: theme.colorScheme.primary, size: 20),
            ),
            title: Text(_measurementLabels[type] ?? type),
            subtitle: Text(formattedDate),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.5),
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
        }),
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
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.4),
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
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha:0.7),
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

// ─────────────────────────────────────────────────────────────────────────────
// Measurement point data
// ─────────────────────────────────────────────────────────────────────────────

class _MeasPt {
  final String type;
  final String label;
  final double fracX; // fraction of container width (dot position)
  final double fracY; // fraction of container height (dot + label position)
  final bool onLeft;  // label on left side?
  const _MeasPt(this.type, this.label, this.fracX, this.fracY, this.onLeft);
}

const List<_MeasPt> _kMeasPoints = [
  _MeasPt('head',      'Head',       0.50,  0.075, true),
  _MeasPt('neck',      'Neck',       0.50,  0.150, false),
  _MeasPt('shoulders', 'Shoulders',  0.50,  0.182, true),
  _MeasPt('chest',     'Chest',      0.50,  0.257, false),
  _MeasPt('arm',       'Arm',        0.31,  0.290, true),
  _MeasPt('waist',     'Waist',      0.50,  0.375, true),
  _MeasPt('forearm',   'Forearm',    0.31,  0.452, true),
  _MeasPt('hips',      'Hips',       0.50,  0.480, false),
  _MeasPt('thigh',     'Thigh',      0.435, 0.618, true),
  _MeasPt('calf',      'Calf',       0.435, 0.790, true),
];

// ─────────────────────────────────────────────────────────────────────────────
// 3D body silhouette painter
// ─────────────────────────────────────────────────────────────────────────────

class _Body3DPainter extends CustomPainter {
  final Color primaryColor;
  const _Body3DPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final fill = primaryColor.withValues(alpha: 0.60);
    final light = primaryColor.withValues(alpha: 0.28);
    final dark = primaryColor.withValues(alpha: 0.85);
    final outline = primaryColor.withValues(alpha: 0.80);
    final detail = primaryColor.withValues(alpha: 0.22);

    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final detailPaint = Paint()
      ..color = detail
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // Helper: horizontal gradient rect shader
    Shader grad(Rect r) => LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [light, fill, dark],
      stops: const [0.0, 0.42, 1.0],
    ).createShader(r);

    Paint fillPaint(Rect r) => Paint()..shader = grad(r);

    // ── HEAD ──
    final headR = h * 0.065;
    final headC = Offset(cx, h * 0.075);
    final headRect = Rect.fromCircle(center: headC, radius: headR);
    canvas.drawCircle(
      headC, headR,
      Paint()..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.75,
        colors: [Colors.white.withValues(alpha: 0.28), fill],
      ).createShader(headRect),
    );
    canvas.drawCircle(headC, headR, outlinePaint);

    // ── NECK ──
    final nW = w * 0.046;
    final neckRect = Rect.fromLTRB(cx - nW, h * 0.132, cx + nW, h * 0.168);
    final neckPath = Path()
      ..moveTo(cx - nW, h * 0.132)
      ..lineTo(cx - nW * 0.82, h * 0.168)
      ..lineTo(cx + nW * 0.82, h * 0.168)
      ..lineTo(cx + nW, h * 0.132)
      ..close();
    canvas.drawPath(neckPath, fillPaint(neckRect));
    canvas.drawPath(neckPath, outlinePaint);

    // ── LEFT ARM ──
    final laRect = Rect.fromLTRB(cx - w * 0.26, h * 0.170, cx - w * 0.11, h * 0.540);
    final laPath = Path()
      ..moveTo(cx - w * 0.136, h * 0.175)
      ..cubicTo(cx - w * 0.190, h * 0.190, cx - w * 0.220, h * 0.235, cx - w * 0.225, h * 0.310)
      ..cubicTo(cx - w * 0.228, h * 0.365, cx - w * 0.215, h * 0.425, cx - w * 0.200, h * 0.535)
      ..lineTo(cx - w * 0.172, h * 0.535)
      ..cubicTo(cx - w * 0.185, h * 0.425, cx - w * 0.172, h * 0.365, cx - w * 0.168, h * 0.310)
      ..cubicTo(cx - w * 0.162, h * 0.235, cx - w * 0.130, h * 0.190, cx - w * 0.114, h * 0.175)
      ..close();
    canvas.drawPath(laPath, fillPaint(laRect));
    canvas.drawPath(laPath, outlinePaint);

    // ── RIGHT ARM (mirror) ──
    final raRect = Rect.fromLTRB(cx + w * 0.11, h * 0.170, cx + w * 0.26, h * 0.540);
    final raPath = Path()
      ..moveTo(cx + w * 0.114, h * 0.175)
      ..cubicTo(cx + w * 0.130, h * 0.190, cx + w * 0.162, h * 0.235, cx + w * 0.168, h * 0.310)
      ..cubicTo(cx + w * 0.172, h * 0.365, cx + w * 0.185, h * 0.425, cx + w * 0.172, h * 0.535)
      ..lineTo(cx + w * 0.200, h * 0.535)
      ..cubicTo(cx + w * 0.215, h * 0.425, cx + w * 0.228, h * 0.365, cx + w * 0.225, h * 0.310)
      ..cubicTo(cx + w * 0.220, h * 0.235, cx + w * 0.190, h * 0.190, cx + w * 0.136, h * 0.175)
      ..close();
    canvas.drawPath(raPath, fillPaint(raRect));
    canvas.drawPath(raPath, outlinePaint);

    // ── TORSO ──
    final torsoRect = Rect.fromLTRB(cx - w * 0.155, h * 0.168, cx + w * 0.155, h * 0.530);
    final torsoPath = Path()
      ..moveTo(cx - w * 0.114, h * 0.175)
      ..cubicTo(cx - w * 0.155, h * 0.245, cx - w * 0.135, h * 0.310, cx - w * 0.112, h * 0.378)
      ..cubicTo(cx - w * 0.100, h * 0.422, cx - w * 0.125, h * 0.480, cx - w * 0.130, h * 0.530)
      ..lineTo(cx + w * 0.130, h * 0.530)
      ..cubicTo(cx + w * 0.125, h * 0.480, cx + w * 0.100, h * 0.422, cx + w * 0.112, h * 0.378)
      ..cubicTo(cx + w * 0.135, h * 0.310, cx + w * 0.155, h * 0.245, cx + w * 0.114, h * 0.175)
      ..close();
    canvas.drawPath(torsoPath, fillPaint(torsoRect));
    canvas.drawPath(torsoPath, outlinePaint);

    // ── LEFT LEG ──
    final llRect = Rect.fromLTRB(cx - w * 0.150, h * 0.530, cx, h * 0.970);
    final llPath = Path()
      ..moveTo(cx - w * 0.130, h * 0.530)
      ..lineTo(cx - w * 0.014, h * 0.530)
      ..cubicTo(cx - w * 0.025, h * 0.615, cx - w * 0.052, h * 0.665, cx - w * 0.052, h * 0.705)
      ..cubicTo(cx - w * 0.052, h * 0.745, cx - w * 0.040, h * 0.842, cx - w * 0.038, h * 0.915)
      ..lineTo(cx - w * 0.063, h * 0.915)
      ..cubicTo(cx - w * 0.065, h * 0.842, cx - w * 0.078, h * 0.745, cx - w * 0.080, h * 0.705)
      ..cubicTo(cx - w * 0.082, h * 0.665, cx - w * 0.115, h * 0.615, cx - w * 0.130, h * 0.530)
      ..close();
    canvas.drawPath(llPath, fillPaint(llRect));
    canvas.drawPath(llPath, outlinePaint);

    // ── RIGHT LEG (mirror) ──
    final rlRect = Rect.fromLTRB(cx, h * 0.530, cx + w * 0.150, h * 0.970);
    final rlPath = Path()
      ..moveTo(cx + w * 0.014, h * 0.530)
      ..lineTo(cx + w * 0.130, h * 0.530)
      ..cubicTo(cx + w * 0.115, h * 0.615, cx + w * 0.082, h * 0.665, cx + w * 0.080, h * 0.705)
      ..cubicTo(cx + w * 0.078, h * 0.745, cx + w * 0.065, h * 0.842, cx + w * 0.063, h * 0.915)
      ..lineTo(cx + w * 0.038, h * 0.915)
      ..cubicTo(cx + w * 0.040, h * 0.842, cx + w * 0.052, h * 0.745, cx + w * 0.052, h * 0.705)
      ..cubicTo(cx + w * 0.052, h * 0.665, cx + w * 0.025, h * 0.615, cx + w * 0.014, h * 0.530)
      ..close();
    canvas.drawPath(rlPath, fillPaint(rlRect));
    canvas.drawPath(rlPath, outlinePaint);

    // ── MUSCLE DETAIL LINES ──
    // Chest center separation
    canvas.drawLine(Offset(cx, h * 0.182), Offset(cx, h * 0.298), detailPaint);
    // Abs horizontal lines
    for (int i = 0; i < 3; i++) {
      final y = h * (0.272 + i * 0.030);
      canvas.drawLine(Offset(cx - w * 0.072, y), Offset(cx + w * 0.072, y), detailPaint);
    }
    // Abs vertical
    canvas.drawLine(Offset(cx, h * 0.300), Offset(cx, h * 0.376), detailPaint);
    // Left bicep
    canvas.drawLine(Offset(cx - w * 0.190, h * 0.248), Offset(cx - w * 0.180, h * 0.305), detailPaint);
    // Left quad
    canvas.drawLine(Offset(cx - w * 0.053, h * 0.560), Offset(cx - w * 0.047, h * 0.682), detailPaint);
    // Left calf
    canvas.drawLine(Offset(cx - w * 0.056, h * 0.720), Offset(cx - w * 0.054, h * 0.810), detailPaint);

    // ── HEAD HIGHLIGHT ──
    canvas.drawCircle(
      Offset(cx - headR * 0.32, headC.dy - headR * 0.32),
      headR * 0.38,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(_Body3DPainter old) => old.primaryColor != primaryColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Measurement dot + connector line painter
// ─────────────────────────────────────────────────────────────────────────────

class _MeasLinePainter extends CustomPainter {
  final Color color;
  const _MeasLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const pillW = 72.0;
    const dotR = 4.5;
    const gap = 4.0;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final dotRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final p in _kMeasPoints) {
      final dotX = p.fracX * size.width;
      final dotY = p.fracY * size.height;

      // Line goes from dot edge to pill edge
      final lineEndX = p.onLeft ? pillW + gap : size.width - pillW - gap;

      final fromX = p.onLeft ? dotX - dotR : dotX + dotR;
      final toX = lineEndX;

      if (p.onLeft && toX < fromX) {
        canvas.drawLine(Offset(fromX, dotY), Offset(toX, dotY), linePaint);
      } else if (!p.onLeft && toX > fromX) {
        canvas.drawLine(Offset(fromX, dotY), Offset(toX, dotY), linePaint);
      }

      canvas.drawCircle(Offset(dotX, dotY), dotR, dotFill);
      canvas.drawCircle(Offset(dotX, dotY), dotR, dotRing);
    }
  }

  @override
  bool shouldRepaint(_MeasLinePainter old) => old.color != color;
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
              initialValue: _selectedType,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.straighten,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
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
