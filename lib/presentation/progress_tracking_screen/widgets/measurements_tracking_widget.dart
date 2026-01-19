import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

/// Measurements tracking widget with body part inputs
class MeasurementsTrackingWidget extends StatefulWidget {
  const MeasurementsTrackingWidget({super.key});

  @override
  State<MeasurementsTrackingWidget> createState() =>
      _MeasurementsTrackingWidgetState();
}

class _MeasurementsTrackingWidgetState
    extends State<MeasurementsTrackingWidget> {
  String? _selectedBodyPart;

  // Mock measurements data
  final Map<String, List<Map<String, dynamic>>> _measurementsData = {
    "Piept": [
      {"date": "2026-01-01", "value": 102.0},
      {"date": "2026-01-08", "value": 101.5},
      {"date": "2026-01-15", "value": 101.0},
    ],
    "Talie": [
      {"date": "2026-01-01", "value": 92.0},
      {"date": "2026-01-08", "value": 90.5},
      {"date": "2026-01-15", "value": 89.0},
    ],
    "Brațe": [
      {"date": "2026-01-01", "value": 35.0},
      {"date": "2026-01-08", "value": 35.5},
      {"date": "2026-01-15", "value": 36.0},
    ],
    "Coapse": [
      {"date": "2026-01-01", "value": 58.0},
      {"date": "2026-01-08", "value": 57.5},
      {"date": "2026-01-15", "value": 57.0},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Body diagram
            _buildBodyDiagram(theme),
            SizedBox(height: 3.h),
            // Body parts grid
            _buildBodyPartsGrid(theme),
            SizedBox(height: 3.h),
            // Selected body part details
            if (_selectedBodyPart != null) ...[
              _buildBodyPartDetails(theme),
              SizedBox(height: 3.h),
            ],
            // All measurements summary
            _buildMeasurementsSummary(theme),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyDiagram(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Text(
            'Selectează Zona Corpului',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          // Simplified body diagram
          SizedBox(
            height: 35.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Body outline
                CustomImageWidget(
                  imageUrl:
                      "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400",
                  width: 40.w,
                  height: 35.h,
                  fit: BoxFit.contain,
                  semanticLabel:
                      "Siluetă corp uman pentru selectare zone măsurători",
                ),
                // Interactive zones
                Positioned(
                  top: 8.h,
                  child: _buildBodyPartButton(theme, 'Piept', 12.w),
                ),
                Positioned(
                  top: 15.h,
                  child: _buildBodyPartButton(theme, 'Talie', 12.w),
                ),
                Positioned(
                  top: 12.h,
                  left: 20.w,
                  child: _buildBodyPartButton(theme, 'Brațe', 10.w),
                ),
                Positioned(
                  top: 12.h,
                  right: 20.w,
                  child: _buildBodyPartButton(theme, 'Brațe', 10.w),
                ),
                Positioned(
                  top: 22.h,
                  left: 25.w,
                  child: _buildBodyPartButton(theme, 'Coapse', 10.w),
                ),
                Positioned(
                  top: 22.h,
                  right: 25.w,
                  child: _buildBodyPartButton(theme, 'Coapse', 10.w),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPartButton(ThemeData theme, String bodyPart, double size) {
    final isSelected = _selectedBodyPart == bodyPart;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBodyPart = bodyPart;
        });
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.add,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.primary,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildBodyPartsGrid(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zone Măsurate',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 3.w,
          crossAxisSpacing: 3.w,
          childAspectRatio: 1.5,
          children: _measurementsData.keys.map((bodyPart) {
            final measurements =
                _measurementsData[bodyPart] as List<Map<String, dynamic>>;
            final latestValue = measurements.isNotEmpty
                ? (measurements.last["value"] as num).toDouble()
                : 0.0;
            final isSelected = _selectedBodyPart == bodyPart;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBodyPart = bodyPart;
                });
              },
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bodyPart,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        Icon(
                          Icons.straighten,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${latestValue.toStringAsFixed(1)} cm',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${measurements.length} măsurători',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBodyPartDetails(ThemeData theme) {
    final measurements =
        _measurementsData[_selectedBodyPart] as List<Map<String, dynamic>>;
    final latestValue = measurements.isNotEmpty
        ? (measurements.last["value"] as num).toDouble()
        : 0.0;
    final firstValue = measurements.isNotEmpty
        ? (measurements.first["value"] as num).toDouble()
        : 0.0;
    final change = latestValue - firstValue;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedBodyPart!,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: change < 0
                      ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                      : theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      change < 0 ? Icons.trending_down : Icons.trending_up,
                      color: change < 0
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.secondary,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} cm',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: change < 0
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Istoric Măsurători',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ...measurements.map((measurement) {
            final date = measurement["date"] as String;
            final value = (measurement["value"] as num).toDouble();
            return Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date, style: theme.textTheme.bodyMedium),
                  Text(
                    '${value.toStringAsFixed(1)} cm',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMeasurementsSummary(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Sfat pentru Măsurători',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Pentru rezultate consistente, măsoară-te dimineața, înainte de micul dejun, în aceleași condiții.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
