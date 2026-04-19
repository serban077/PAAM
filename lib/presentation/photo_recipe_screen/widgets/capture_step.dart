import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Step 1: Camera/gallery photo capture with image preview.
class CaptureStep extends StatefulWidget {
  final void Function(Uint8List imageBytes) onPhotoCaptured;

  const CaptureStep({super.key, required this.onPhotoCaptured});

  @override
  State<CaptureStep> createState() => _CaptureStepState();
}

class _CaptureStepState extends State<CaptureStep> {
  final _imagePicker = ImagePicker();
  Uint8List? _previewBytes;
  bool _isPicking = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked == null) {
        setState(() => _isPicking = false);
        return;
      }

      final rawBytes = await picked.readAsBytes();
      final bytes = await FlutterImageCompress.compressWithList(
        rawBytes,
        minWidth: 1024,
        minHeight: 1024,
        quality: 75,
        format: CompressFormat.jpeg,
      );
      if (!mounted) return;
      setState(() {
        _previewBytes = bytes;
        _isPicking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPicking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  void _analyzeImage() {
    if (_previewBytes == null) return;
    HapticFeedback.lightImpact();
    widget.onPhotoCaptured(_previewBytes!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        children: [
          // Hero area
          Container(
            width: double.infinity,
            height: 45.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: _previewBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.memory(
                      _previewBytes!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'camera_alt',
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Take a photo of your ingredients',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Spread items on a table for best results',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(height: 3.h),

          // Action buttons
          if (_previewBytes == null) ...[
            _ActionButton(
              onTap: () => _pickImage(ImageSource.camera),
              icon: 'camera_alt',
              label: 'Take Photo',
              isPrimary: true,
              isLoading: _isPicking,
              theme: theme,
            ),
            SizedBox(height: 1.5.h),
            _ActionButton(
              onTap: () => _pickImage(ImageSource.gallery),
              icon: 'photo_library',
              label: 'Choose from Gallery',
              isPrimary: false,
              isLoading: false,
              theme: theme,
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: FilledButton.icon(
                onPressed: _analyzeImage,
                icon: const CustomIconWidget(
                  iconName: 'auto_awesome',
                  size: 20,
                  color: Colors.white,
                ),
                label: Text(
                  'Analyze Ingredients',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 1.5.h),
            TextButton.icon(
              onPressed: () => setState(() => _previewBytes = null),
              icon: const CustomIconWidget(iconName: 'refresh', size: 18),
              label: const Text('Retake Photo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final String icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final ThemeData theme;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isLoading,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: isPrimary
          ? FilledButton.icon(
              onPressed: isLoading ? null : onTap,
              icon: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : CustomIconWidget(
                      iconName: icon,
                      size: 20,
                      color: theme.colorScheme.onPrimary,
                    ),
              label: Text(
                label,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: CustomIconWidget(iconName: icon, size: 20),
              label: Text(
                label,
                style: TextStyle(fontSize: 14.sp),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}
