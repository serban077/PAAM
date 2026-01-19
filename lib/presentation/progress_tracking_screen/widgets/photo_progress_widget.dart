import 'package:before_after/before_after.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Photo progress widget with before/after comparison
class PhotoProgressWidget extends StatefulWidget {
  const PhotoProgressWidget({super.key});

  @override
  State<PhotoProgressWidget> createState() => _PhotoProgressWidgetState();
}

class _PhotoProgressWidgetState extends State<PhotoProgressWidget> {
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  XFile? _capturedImage;
  bool _isCameraInitialized = false;
  bool _showCamera = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Mock photo progress data
  final List<Map<String, dynamic>> _photoProgress = [
    {
      "date": "2026-01-01",
      "beforeImage":
          "https://img.rocket.new/generatedImages/rocket_gen_img_16a84649c-1767572170096.png",
      "afterImage":
          "https://img.rocket.new/generatedImages/rocket_gen_img_16a84649c-1767572170096.png",
      "beforeSemanticLabel":
          "Fotografie progres înainte - bărbat în tricou alb, poziție frontală",
      "afterSemanticLabel":
          "Fotografie progres după - bărbat în tricou alb, poziție frontală, musculatură mai definită",
      "notes": "Început program antrenament",
    },
    {
      "date": "2026-01-15",
      "beforeImage":
          "https://images.unsplash.com/photo-1585484205460-3f479e63ce60",
      "afterImage":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1c20541c9-1766847286174.png",
      "beforeSemanticLabel":
          "Fotografie progres înainte - bărbat în tricou alb, poziție laterală",
      "afterSemanticLabel":
          "Fotografie progres după - bărbat în tricou alb, poziție laterală, abdomen mai plat",
      "notes": "După 2 săptămâni",
    },
  ];

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    return (await Permission.camera.request()).isGranted;
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      final camera = kIsWeb
          ? _cameras!.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras!.first,
            )
          : _cameras!.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras!.first,
            );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      );

      await _cameraController!.initialize();

      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (e) {}

      if (!kIsWeb) {
        try {
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (e) {}
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nu s-a putut inițializa camera'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = photo;
        _showCamera = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotografie salvată cu succes!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eroare la capturarea fotografiei'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          _capturedImage = image;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fotografie selectată cu succes!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eroare la selectarea fotografiei'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_showCamera && _isCameraInitialized && _cameraController != null) {
      return _buildCameraView(theme);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add photo buttons
            _buildAddPhotoButtons(theme),
            SizedBox(height: 3.h),
            // Photo comparison grid
            _buildPhotoComparisonGrid(theme),
            SizedBox(height: 3.h),
            // Tips card
            _buildTipsCard(theme),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(ThemeData theme) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(_cameraController!),
        ),
        // Pose guidance overlay
        Center(
          child: Container(
            width: 70.w,
            height: 60.h,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 100,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Poziționează-te în cadru',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Controls
        Positioned(
          bottom: 4.h,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
                onPressed: () {
                  setState(() {
                    _showCamera = false;
                  });
                },
              ),
              GestureDetector(
                onTap: _capturePhoto,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final hasPermission = await _requestCameraPermission();
              if (hasPermission) {
                await _initializeCamera();
                setState(() {
                  _showCamera = true;
                });
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permisiune cameră necesară'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            icon: CustomIconWidget(
              iconName: 'camera_alt',
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
            label: const Text('Cameră'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickImageFromGallery,
            icon: CustomIconWidget(
              iconName: 'photo_library',
              color: theme.colorScheme.primary,
              size: 20,
            ),
            label: const Text('Galerie'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoComparisonGrid(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparații Progres',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ..._photoProgress.map((progress) {
          return Padding(
            padding: EdgeInsets.only(bottom: 3.h),
            child: _buildPhotoComparisonCard(theme, progress),
          );
        }),
      ],
    );
  }

  Widget _buildPhotoComparisonCard(
    ThemeData theme,
    Map<String, dynamic> progress,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progress["date"] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    progress["notes"] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Before/After comparison
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: SizedBox(
              height: 40.h,
              child: BeforeAfter(
                before: Image.network(
                  progress["beforeImage"] as String,
                  fit: BoxFit.cover,
                  semanticLabel: progress["beforeSemanticLabel"] as String,
                ),
                after: Image.network(
                  progress["afterImage"] as String,
                  fit: BoxFit.cover,
                  semanticLabel: progress["afterSemanticLabel"] as String,
                ),
                thumbColor: theme.colorScheme.primary,
              ),
            ),
          ),
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
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Sfaturi pentru Fotografii',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildTipItem(theme, 'Folosește aceeași lumină și fundal'),
          _buildTipItem(theme, 'Fotografiază-te dimineața, pe stomacul gol'),
          _buildTipItem(theme, 'Menține aceeași poziție și distanță'),
          _buildTipItem(theme, 'Fă fotografii săptămânal pentru consistență'),
        ],
      ),
    );
  }

  Widget _buildTipItem(ThemeData theme, String text) {
    return Padding(
      padding: EdgeInsets.only(top: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 0.5.h),
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
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
