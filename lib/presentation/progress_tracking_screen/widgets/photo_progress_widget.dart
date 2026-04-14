import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/progress_photo_service.dart';

/// Photo progress widget — persists before/after photos to Supabase Storage.
class PhotoProgressWidget extends StatefulWidget {
  const PhotoProgressWidget({super.key});

  @override
  State<PhotoProgressWidget> createState() => _PhotoProgressWidgetState();
}

class _PhotoProgressWidgetState extends State<PhotoProgressWidget> {
  final _service = ProgressPhotoService();
  final _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final entries = await _service.getUserPhotos();
      if (mounted) setState(() => _entries = entries);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load photos. Tap to retry.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  // ── Save (upload + persist) ───────────────────────────────────────────────

  Future<void> _onPhotosSelected(
    String localBefore,
    String? localAfter,
    String note,
  ) async {
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final label =
          '${_monthName(now.month)} ${now.day.toString().padLeft(2, '0')}, ${now.year}';

      await _service.saveEntry(
        localBeforePath: localBefore,
        localAfterPath: localAfter,
        dateLabel: label,
        notes: note,
      );
      await _loadPhotos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This will permanently remove the photo from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteEntry(
        entry['id'] as String,
        entry['before_path'] as String,
        entry['after_path'] as String?,
      );
      await _loadPhotos();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete photo')),
        );
      }
    }
  }

  // ── Bottom sheet ──────────────────────────────────────────────────────────

  void _showAddPhotoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddPhotoSheet(
        onPhotosSelected: _onPhotosSelected,
        pickPhoto: _pickPhoto,
      ),
    );
  }

  // ── Full-screen viewer ────────────────────────────────────────────────────

  void _openViewer(String url, String label) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (ctx, _, __) => _PhotoViewer(url: url, label: label),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _monthName(int m) => const [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CTA
        _AddPhotoButton(
          onTap: _isSaving ? null : _showAddPhotoSheet,
          isSaving: _isSaving,
        ),
        SizedBox(height: 3.h),

        // Body
        if (_isLoading)
          _buildSkeleton(theme)
        else if (_error != null)
          _buildError(theme)
        else if (_entries.isEmpty)
          _buildEmptyState(theme)
        else
          ..._entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: 3.h),
                child: _PhotoCard(
                  entry: entry,
                  theme: theme,
                  onPhotoTap: _openViewer,
                  onDelete: () => _deleteEntry(entry),
                ),
              )),

        SizedBox(height: 1.h),
        _buildTipsCard(theme),
      ],
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return Column(
      children: List.generate(2, (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: 3.h),
          child: Container(
            height: 32.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'cloud_off',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 48,
            ),
            SizedBox(height: 1.5.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            OutlinedButton.icon(
              onPressed: _loadPhotos,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: theme.colorScheme.primary,
                size: 18,
              ),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Column(
          children: [
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
          ],
        ),
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
                      style: theme.textTheme.bodySmall,
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
  final VoidCallback? onTap;
  final bool isSaving;

  const _AddPhotoButton({required this.onTap, required this.isSaving});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap == null) return;
          HapticFeedback.lightImpact();
          onTap!();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 2.2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: isSaving ? 0.5 : 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSaving
                ? null
                : [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: isSaving
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Uploading photos…',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
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
  final void Function(String url, String label) onPhotoTap;
  final VoidCallback onDelete;

  const _PhotoCard({
    required this.entry,
    required this.theme,
    required this.onPhotoTap,
    required this.onDelete,
  });

  bool get _hasAfter =>
      entry['after_url'] != null && (entry['after_url'] as String).isNotEmpty;

  Widget _buildPhoto(String url, String label) {
    if (url.startsWith('http')) {
      return CustomImageWidget(
        imageUrl: url,
        fit: BoxFit.cover,
        semanticLabel: label,
      );
    }
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      semanticLabel: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = entry['date_label'] as String;

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
          // ── Header ────────────────────────────────────────────────────
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
                SizedBox(width: 2.w),
                // Delete button
                GestureDetector(
                  onTap: onDelete,
                  child: CustomIconWidget(
                    iconName: 'delete_outline',
                    color: theme.colorScheme.error.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // ── Photos ────────────────────────────────────────────────────
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

  Widget _buildSplitView(String date) {
    final beforeUrl = entry['before_url'] as String;
    final afterUrl = entry['after_url'] as String;

    return SizedBox(
      height: 36.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onPhotoTap(beforeUrl, 'Before — $date'),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPhoto(beforeUrl, 'Before — $date'),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _LabelChip(
                      label: 'BEFORE',
                      color: theme.colorScheme.error,
                      theme: theme,
                    ),
                  ),
                  // Tap-to-expand hint
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _ExpandHint(theme: theme),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 2, color: Colors.white),
          Expanded(
            child: GestureDetector(
              onTap: () => onPhotoTap(afterUrl, 'After — $date'),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPhoto(afterUrl, 'After — $date'),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _LabelChip(
                      label: 'AFTER',
                      color: theme.colorScheme.primary,
                      theme: theme,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _ExpandHint(theme: theme),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleView(String date) {
    final beforeUrl = entry['before_url'] as String;

    return GestureDetector(
      onTap: () => onPhotoTap(beforeUrl, 'Before — $date'),
      child: SizedBox(
        height: 32.h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPhoto(beforeUrl, 'Before — $date'),
            Positioned(
              top: 8,
              left: 8,
              child: _LabelChip(
                label: 'BEFORE',
                color: theme.colorScheme.error,
                theme: theme,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _LabelChip(
                label: '+ Add After',
                color: theme.colorScheme.onSurfaceVariant,
                theme: theme,
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: _ExpandHint(theme: theme),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandHint extends StatelessWidget {
  final ThemeData theme;
  const _ExpandHint({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_full, color: Colors.white, size: 10.sp),
          const SizedBox(width: 3),
          Text(
            'Tap to expand',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontSize: 8.sp,
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
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 8.5.sp,
        ),
      ),
    );
  }
}

// ── Full-screen Photo Viewer ──────────────────────────────────────────────────

class _PhotoViewer extends StatelessWidget {
  final String url;
  final String label;

  const _PhotoViewer({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black87,
          child: Stack(
            children: [
              // Pinch-to-zoom image
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: url.startsWith('http')
                      ? CustomImageWidget(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          semanticLabel: label,
                        )
                      : Image.file(
                          File(url),
                          fit: BoxFit.contain,
                          semanticLabel: label,
                        ),
                ),
              ),
              // Close button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ),
              // Label
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
              'Before is required. After is optional — add it once you have results to compare.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),

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
                  canSubmit
                      ? 'Save Progress Photo'
                      : 'Pick a Before photo first',
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
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accentColor,
                ),
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
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding:
                                    EdgeInsets.symmetric(vertical: 0.8.h),
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
