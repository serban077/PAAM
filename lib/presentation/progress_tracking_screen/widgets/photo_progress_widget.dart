import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Photo progress widget — before/after comparison with camera/gallery upload.
/// Uses image_picker (native camera UI) — no in-widget camera preview needed.
class PhotoProgressWidget extends StatefulWidget {
  const PhotoProgressWidget({super.key});

  @override
  State<PhotoProgressWidget> createState() => _PhotoProgressWidgetState();
}

class _PhotoProgressWidgetState extends State<PhotoProgressWidget> {
  final _imagePicker = ImagePicker();

  /// Each entry: { date, beforePath, afterPath?, notes }
  /// `beforePath` / `afterPath` can be a remote URL or a local file path.
  final List<Map<String, dynamic>> _photoProgress = [
    {
      'date': 'Jan 01, 2026',
      'beforePath':
          'https://img.rocket.new/generatedImages/rocket_gen_img_16a84649c-1767572170096.png',
      'afterPath':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1c20541c9-1766847286174.png',
      'notes': 'Week 1',
    },
    {
      'date': 'Jan 15, 2026',
      'beforePath':
          'https://images.unsplash.com/photo-1585484205460-3f479e63ce60',
      'afterPath':
          'https://img.rocket.new/generatedImages/rocket_gen_img_16a84649c-1767572170096.png',
      'notes': 'Week 3',
    },
  ];

  // ── Photo picking ─────────────────────────────────────────────────────────

  Future<String?> _pickPhoto(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      return file?.path;
    } catch (_) {
      return null;
    }
  }

  void _showAddPhotoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddPhotoSheet(
        onPhotosSelected: (before, after, note) {
          setState(() {
            final now = DateTime.now();
            final label =
                '${_monthName(now.month)} ${now.day.toString().padLeft(2, '0')}, ${now.year}';
            _photoProgress.insert(0, {
              'date': label,
              'beforePath': before,
              'afterPath': after,
              'notes': note,
            });
          });
        },
        pickPhoto: _pickPhoto,
      ),
    );
  }

  String _monthName(int m) => const [
        '',
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec',
      ][m];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── CTA row ────────────────────────────────────────────────────────
        _AddPhotoButton(onTap: _showAddPhotoSheet),
        SizedBox(height: 3.h),

        // ── Photo list ────────────────────────────────────────────────────
        if (_photoProgress.isEmpty)
          _buildEmptyState(theme)
        else
          ...List.generate(_photoProgress.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: 3.h),
              child: _PhotoCard(entry: _photoProgress[i], theme: theme),
            );
          }),

        // ── Tips ─────────────────────────────────────────────────────────
        SizedBox(height: 1.h),
        _buildTipsCard(theme),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 4.h),
          CustomIconWidget(
            iconName: 'photo_camera',
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'No progress photos yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            'Tap "Add Progress Photo" to start tracking\nyour visual transformation.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildTipsCard(ThemeData theme) {
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
              CustomIconWidget(
                iconName: 'lightbulb_outline',
                color: theme.colorScheme.primary,
                size: 18,
              ),
              SizedBox(width: 2.w),
              Text(
                'Photo Tips',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          for (final tip in [
            'Use the same lighting and background each time',
            'Take photos in the morning on an empty stomach',
            'Maintain the same pose and camera distance',
            'Take photos weekly for best consistency',
          ])
            Padding(
              padding: EdgeInsets.only(top: 0.6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Add Photo Button ──────────────────────────────────────────────────────────

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 2.2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'add_a_photo',
                color: theme.colorScheme.onPrimary,
                size: 22,
              ),
              SizedBox(width: 3.w),
              Text(
                'Add Progress Photo',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Photo Card ────────────────────────────────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final ThemeData theme;

  const _PhotoCard({required this.entry, required this.theme});

  bool get _hasAfter =>
      entry['afterPath'] != null &&
      (entry['afterPath'] as String).isNotEmpty;

  // Builds a photo from a URL or local file path, always fills its parent.
  Widget _buildPhoto(String path, String label) {
    if (path.startsWith('http')) {
      return CustomImageWidget(
        imageUrl: path,
        fit: BoxFit.cover,
        semanticLabel: label,
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      semanticLabel: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = entry['date'] as String;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row ────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'calendar_today',
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Text(
                  date,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry['notes'] as String,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Photo section ─────────────────────────────────────────────
          // Row → Expanded → Stack(expand) gives each image tight,
          // bounded constraints — always renders correctly.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: _hasAfter
                ? _buildSplitView(date)
                : _buildSingleView(date),
          ),
        ],
      ),
    );
  }

  // Side-by-side before | divider | after
  Widget _buildSplitView(String date) {
    return SizedBox(
      height: 36.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Before half
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPhoto(
                  entry['beforePath'] as String,
                  'Before — $date',
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _LabelChip(
                    label: 'BEFORE',
                    color: theme.colorScheme.error,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
          // White divider
          Container(width: 2, color: Colors.white),
          // After half
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPhoto(
                  entry['afterPath'] as String,
                  'After — $date',
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _LabelChip(
                    label: 'AFTER',
                    color: theme.colorScheme.primary,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Full-width before + "Add After" hint
  Widget _buildSingleView(String date) {
    return SizedBox(
      height: 32.h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPhoto(entry['beforePath'] as String, 'Before — $date'),
          // Before chip (top-left)
          Positioned(
            top: 8,
            left: 8,
            child: _LabelChip(
              label: 'BEFORE',
              color: theme.colorScheme.error,
              theme: theme,
            ),
          ),
          // Add After hint (top-right)
          Positioned(
            top: 8,
            right: 8,
            child: _LabelChip(
              label: '+ Add After',
              color: theme.colorScheme.onSurfaceVariant,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;
  final Color color;
  final ThemeData theme;

  const _LabelChip({
    required this.label,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Add Photo Bottom Sheet ────────────────────────────────────────────────────

class _AddPhotoSheet extends StatefulWidget {
  final void Function(String before, String? after, String note) onPhotosSelected;
  final Future<String?> Function(ImageSource) pickPhoto;

  const _AddPhotoSheet({
    required this.onPhotosSelected,
    required this.pickPhoto,
  });

  @override
  State<_AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends State<_AddPhotoSheet> {
  String? _beforePath;
  String? _afterPath;
  final _noteController = TextEditingController();
  bool _isPickingBefore = false;
  bool _isPickingAfter = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source, bool isBefore) async {
    setState(() {
      if (isBefore) {
        _isPickingBefore = true;
      } else {
        _isPickingAfter = true;
      }
    });
    final path = await widget.pickPhoto(source);
    if (!mounted) return;
    setState(() {
      if (isBefore) {
        _beforePath = path;
        _isPickingBefore = false;
      } else {
        _afterPath = path;
        _isPickingAfter = false;
      }
    });
  }

  void _showSourcePicker(bool isBefore) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera, isBefore);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_library',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery, isBefore);
              },
            ),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_beforePath == null) return;
    widget.onPhotosSelected(
      _beforePath!,
      _afterPath,
      _noteController.text.trim().isEmpty
          ? 'Progress'
          : _noteController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = _beforePath != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        5.w,
        0,
        5.w,
        MediaQuery.of(context).viewInsets.bottom + 3.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 12.w,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Add Progress Photo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 0.6.h),
            Text(
              'Add a before photo (required) and optionally an after photo to compare your progress.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),

            // Before / After photo pickers side by side
            Row(
              children: [
                Expanded(
                  child: _PhotoPickerTile(
                    label: 'Before',
                    required: true,
                    imagePath: _beforePath,
                    isLoading: _isPickingBefore,
                    accentColor: theme.colorScheme.error,
                    theme: theme,
                    onTap: () => _showSourcePicker(true),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _PhotoPickerTile(
                    label: 'After',
                    required: false,
                    imagePath: _afterPath,
                    isLoading: _isPickingAfter,
                    accentColor: theme.colorScheme.primary,
                    theme: theme,
                    onTap: () => _showSourcePicker(false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Note field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Week 4, End of cut…',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'edit_note',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLength: 40,
            ),
            SizedBox(height: 2.h),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  disabledBackgroundColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  canSubmit ? 'Save Progress Photo' : 'Pick a Before photo first',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: canSubmit
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo Picker Tile ─────────────────────────────────────────────────────────

class _PhotoPickerTile extends StatelessWidget {
  final String label;
  final bool required;
  final String? imagePath;
  final bool isLoading;
  final Color accentColor;
  final ThemeData theme;
  final VoidCallback onTap;

  const _PhotoPickerTile({
    required this.label,
    required this.required,
    required this.imagePath,
    required this.isLoading,
    required this.accentColor,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: theme.textTheme.labelLarge?.copyWith(color: accentColor),
              ),
          ],
        ),
        SizedBox(height: 1.h),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 22.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: hasImage
                  ? Colors.transparent
                  : accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasImage
                    ? accentColor.withValues(alpha: 0.5)
                    : accentColor.withValues(alpha: 0.3),
                width: hasImage ? 2 : 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: 2.5,
                      ),
                    )
                  : hasImage
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            imagePath!.startsWith('http')
                                ? CustomImageWidget(
                                    imageUrl: imagePath!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(imagePath!),
                                    fit: BoxFit.cover,
                                  ),
                            // Change overlay
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 0.8.h),
                                color: Colors.black.withValues(alpha: 0.45),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'edit',
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      'Change',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'add_photo_alternate',
                              color: accentColor.withValues(alpha: 0.7),
                              size: 36,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Tap to add',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: accentColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ],
    );
  }
}
