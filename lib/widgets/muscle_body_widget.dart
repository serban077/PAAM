import 'package:flutter/material.dart';
import 'package:muscle_selector/muscle_selector.dart';
import 'package:sizer/sizer.dart';

/// Displays a professional anatomical body diagram with targeted muscle groups
/// highlighted in hot pink. Shows both front and back views simultaneously.
/// Powered by muscle_selector's real anatomical SVG (no custom SVG needed).
///
/// [targetMuscles] accepts a comma-separated string in English or Romanian.
class MuscleBodyWidget extends StatelessWidget {
  final String targetMuscles;

  const MuscleBodyWidget({super.key, required this.targetMuscles});

  // ── Map our parsed muscle string → muscle_selector group keys ──────
  static List<String> _parse(String raw) {
    final lower = raw.toLowerCase();
    final result = <String>[];

    if (lower.contains('chest') || lower.contains('pec') ||
        lower.contains('piept') || lower.contains('pectoral')) {
      result.add('chest');
    }
    if (lower.contains('shoulder') || lower.contains('delt') ||
        lower.contains('umar') || lower.contains('umeri')) {
      result.add('shoulders');
    }
    if (lower.contains('bicep') || lower.contains('bicepsi')) {
      result.add('biceps');
    }
    if (lower.contains('tricep') || lower.contains('tricepsi')) {
      result.add('triceps');
    }
    if (lower.contains('forearm') || lower.contains('antebrat')) {
      result.add('forearm');
    }
    if (lower.contains('abs') || lower.contains('core') ||
        lower.contains('abdominal') || lower.contains('abdominali')) {
      result.add('abs');
    }
    if (lower.contains('oblique') || lower.contains('oblici')) {
      result.add('obliques');
    }
    if (lower.contains('lat') || lower.contains('dorsal') ||
        lower.contains('latissimus')) {
      result.add('lats');
    }
    // 'spate' = Romanian for 'back' — avoid matching 'spate superior' again
    if (lower.contains('spate') && !lower.contains('superior')) {
      result.add('lats');
    }
    if (lower.contains('trap') || lower.contains('trapez') ||
        lower.contains('upper back') || lower.contains('spate superior')) {
      result.add('trapezius');
      result.add('upper_back');
    }
    if (lower.contains('lower back') || lower.contains('lombar') ||
        lower.contains('erector') || lower.contains('lombari')) {
      result.add('lower_back');
    }
    if (lower.contains('glute') || lower.contains('fesier') ||
        lower.contains('gluteus') || lower.contains('fese')) {
      result.add('glutes');
    }
    if (lower.contains('quad') || lower.contains('cvadricep') ||
        lower.contains('thigh') || lower.contains('coapsa') ||
        lower.contains('picioare') || lower.contains('leg')) {
      result.add('quads');
    }
    // 'harmstrings' — intentional typo matching the package's enum key
    if (lower.contains('hamstring') || lower.contains('ischiogambian') ||
        lower.contains('biceps femural')) {
      result.add('harmstrings');
    }
    if (lower.contains('calf') || lower.contains('calves') ||
        lower.contains('gambe') || lower.contains('triceps sural') ||
        lower.contains('mollet')) {
      result.add('calves');
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = _parse(targetMuscles);
    final hasTargets = groups.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Anatomical body diagram — front + back in one SVG
        SizedBox(
          height: 38.h,
          child: LayoutBuilder(
            builder: (context, constraints) => ClipRect(
              child: MusclePickerMap(
                // Keyed by targetMuscles so it rebuilds when exercise changes
                key: ValueKey(targetMuscles),
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                map: Maps.BODY,
                initialSelectedGroups: groups,
                onChanged: (_) {}, // display-only, ignore selection changes
                actAsToggle: false,
                isEditing: true, // disables tap selection
                selectedColor: const Color(0xFFE91E8C), // hot pink
                strokeColor: Colors.white54,            // visible on dark bg
                dotColor: const Color(0xFFE91E8C),
              ),
            ),
          ),
        ),
        SizedBox(height: 0.8.h),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFE91E8C),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(width: 1.5.w),
            Text(
              hasTargets ? 'Targeted muscles' : 'No muscle data',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
