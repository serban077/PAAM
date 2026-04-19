import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../services/gemini_nutrition_label_service.dart';
import '../../services/nutrition_service.dart';
import '../../services/supabase_service.dart';
import '../nutrition_planning_screen/widgets/product_found_screen.dart';

/// 3-step wizard for submitting a missing food product or correcting an
/// existing one.
///
/// Step 1 — Product Info: name, brand, barcode (pre-filled from scan)
/// Step 2 — Nutritional Label Photo + Gemini Vision extraction
/// Step 3 — Review & Submit macros
///
/// **Edit mode:** Pass [existingFood] to correct an existing product.
/// In edit mode the wizard starts at Step 2 (label photo) and submits
/// an UPDATE instead of INSERT.
class UserFoodSubmissionScreen extends StatefulWidget {
  final String barcode;

  /// Optional pre-filled product name (e.g. from a failed search query).
  final String productName;

  /// When non-null the wizard runs in **edit mode** — corrects the existing
  /// food row instead of creating a new one.
  final Map<String, dynamic>? existingFood;

  const UserFoodSubmissionScreen({
    super.key,
    required this.barcode,
    this.productName = '',
    this.existingFood,
  });

  @override
  State<UserFoodSubmissionScreen> createState() =>
      _UserFoodSubmissionScreenState();
}

class _UserFoodSubmissionScreenState extends State<UserFoodSubmissionScreen> {
  final _nutritionService = NutritionService(SupabaseService.instance.client);
  final _geminiService = GeminiNutritionLabelService();
  final _imagePicker = ImagePicker();
  final _pageController = PageController();

  bool get _isEditMode => widget.existingFood != null;
  int _currentStep = 0;

  // Step 1 fields
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _step1Key = GlobalKey<FormState>();

  // Step 2 state
  Uint8List? _imageBytes;
  String? _imagePath;
  bool _isExtracting = false;

  // Step 3 fields
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _sugarController = TextEditingController();
  final _starchController = TextEditingController();
  final _polyolsController = TextEditingController();
  final _satFatController = TextEditingController();
  final _monoFatController = TextEditingController();
  final _polyFatController = TextEditingController();
  final _transFatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _cholesterolController = TextEditingController();
  final _sodiumController = TextEditingController();
  final _saltController = TextEditingController();
  final _servingSizeController = TextEditingController(text: '100');
  final _step3Key = GlobalKey<FormState>();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _prefillFromExistingFood();
      // Start at Step 2 (label photo) in edit mode
      _currentStep = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(1);
      });
    } else if (widget.productName.isNotEmpty) {
      _nameController.text = widget.productName;
    }
  }

  void _prefillFromExistingFood() {
    final f = widget.existingFood!;
    _nameController.text = f['name'] as String? ?? '';
    _brandController.text = f['brand'] as String? ?? '';

    _caloriesController.text = _fmtExisting(f['calories']);
    _proteinController.text = _fmtExisting(f['protein_g']);
    _carbsController.text = _fmtExisting(f['carbs_g']);
    _fatController.text = _fmtExisting(f['fat_g']);
    _servingSizeController.text = _fmtExisting(f['serving_size']) .isEmpty
        ? '100'
        : _fmtExisting(f['serving_size']);

    // Top-level optional fields
    _fiberController.text = _fmtExisting(f['fiber_g']);
    _sugarController.text = _fmtExisting(f['sugar_g']);
    _sodiumController.text = _fmtExisting(f['sodium_mg']);

    // Detailed macros JSONB
    final dm = f['detailed_macros'] as Map<String, dynamic>?;
    if (dm != null) {
      _sugarController.text = _fmtExisting(dm['sugar_g'] ?? f['sugar_g']);
      _starchController.text = _fmtExisting(dm['starch_g']);
      _polyolsController.text = _fmtExisting(dm['polyols_g']);
      _satFatController.text = _fmtExisting(dm['saturated_fat_g']);
      _monoFatController.text = _fmtExisting(dm['monounsaturated_fat_g']);
      _polyFatController.text = _fmtExisting(dm['polyunsaturated_fat_g']);
      _transFatController.text = _fmtExisting(dm['trans_fat_g']);
      _fiberController.text = _fmtExisting(dm['fiber_g'] ?? f['fiber_g']);
      _cholesterolController.text = _fmtExisting(dm['cholesterol_mg']);
      _sodiumController.text =
          _fmtExisting(dm['sodium_mg'] ?? f['sodium_mg']);
      _saltController.text = _fmtExisting(dm['salt_g']);
    }
  }

  String _fmtExisting(dynamic v) =>
      v == null ? '' : (v as num).toStringAsFixed(1);

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sugarController.dispose();
    _starchController.dispose();
    _polyolsController.dispose();
    _satFatController.dispose();
    _monoFatController.dispose();
    _polyFatController.dispose();
    _transFatController.dispose();
    _fiberController.dispose();
    _cholesterolController.dispose();
    _sodiumController.dispose();
    _saltController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked == null) return;
      final rawBytes = await picked.readAsBytes();
      final bytes = await FlutterImageCompress.compressWithList(
        rawBytes,
        minWidth: 1024,
        minHeight: 1024,
        quality: 75,
        format: CompressFormat.jpeg,
      );
      setState(() {
        _imageBytes = bytes;
        _imagePath = picked.path;
      });
      // Auto-trigger AI extraction as soon as the photo is captured
      _extractMacros();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access the image.')),
      );
    }
  }

  // ── Gemini extraction ──────────────────────────────────────────────────────

  Future<void> _extractMacros() async {
    if (_imageBytes == null) return;
    setState(() => _isExtracting = true);
    try {
      final result = await _geminiService.extractNutritionLabel(
        _imageBytes!,
        imagePath: _imagePath,
      );
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not extract macros. Please enter them manually.'),
          ),
        );
        _goToStep(2);
        return;
      }
      _fillStep3FromExtraction(result);
      _goToStep(2);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Extraction failed. Please enter macros manually.'),
        ),
      );
      _goToStep(2);
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  void _fillStep3FromExtraction(Map<String, dynamic> data) {
    _caloriesController.text = _fmt(data['calories']);
    _proteinController.text = _fmt(data['protein_g']);
    _carbsController.text = _fmt(data['carbs_g']);
    _fatController.text = _fmt(data['fat_g']);
    _sugarController.text = _fmt(data['sugar_g']);
    _starchController.text = _fmt(data['starch_g']);
    _polyolsController.text = _fmt(data['polyols_g']);
    _satFatController.text = _fmt(data['saturated_fat_g']);
    _monoFatController.text = _fmt(data['monounsaturated_fat_g']);
    _polyFatController.text = _fmt(data['polyunsaturated_fat_g']);
    _transFatController.text = _fmt(data['trans_fat_g']);
    _fiberController.text = _fmt(data['fiber_g']);
    _cholesterolController.text = _fmt(data['cholesterol_mg']);
    _sodiumController.text = _fmt(data['sodium_mg']);
    _saltController.text = _fmt(data['salt_g']);
    if (data['serving_size_g'] != null) {
      _servingSizeController.text = _fmt(data['serving_size_g']);
    }
  }

  String _fmt(dynamic v) =>
      v == null ? '' : (v as num).toStringAsFixed(1);

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_step3Key.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final brand = _brandController.text.trim();
      final detailedMacros = <String, dynamic>{};
      void addDetail(String key, TextEditingController ctrl) {
        final v = double.tryParse(ctrl.text);
        if (v != null) detailedMacros[key] = v;
      }

      addDetail('sugar_g', _sugarController);
      addDetail('starch_g', _starchController);
      addDetail('polyols_g', _polyolsController);
      addDetail('saturated_fat_g', _satFatController);
      addDetail('monounsaturated_fat_g', _monoFatController);
      addDetail('polyunsaturated_fat_g', _polyFatController);
      addDetail('trans_fat_g', _transFatController);
      addDetail('fiber_g', _fiberController);
      addDetail('cholesterol_mg', _cholesterolController);
      addDetail('sodium_mg', _sodiumController);
      addDetail('salt_g', _saltController);

      final foodRow = <String, dynamic>{
        'name': _nameController.text.trim(),
        'brand': brand.isEmpty ? null : brand,
        'barcode': widget.barcode.isEmpty ? null : widget.barcode,
        'calories': double.parse(_caloriesController.text),
        'protein_g': double.parse(_proteinController.text),
        'carbs_g': double.parse(_carbsController.text),
        'fat_g': double.parse(_fatController.text),
        'serving_size':
            double.tryParse(_servingSizeController.text) ?? 100.0,
        'serving_unit': 'g',
        if (detailedMacros.isNotEmpty) 'detailed_macros': detailedMacros,
      };

      Map<String, dynamic> resultFood;

      if (_isEditMode) {
        // Edit mode — update existing food row
        resultFood = await _nutritionService.updateFoodNutrition(
          widget.existingFood!['id'] as String,
          foodRow,
        );
      } else {
        // Create mode — insert new food row
        resultFood = await _nutritionService.submitUserFood(foodRow);
      }
      if (!mounted) return;

      HapticFeedback.lightImpact();

      // Navigate to ProductFoundScreen with the updated/created food
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductFoundScreen(
            food: resultFood,
            onFoodAdded: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submit failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? 'Correct Product — Step ${_currentStep + 1} of 3'
              : 'Add Product — Step ${_currentStep + 1} of 3',
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(currentStep: _currentStep),

          // Page content — physics: NeverScrollable so only programmatic nav
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(theme),
                _buildStep2(theme),
                _buildStep3(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1 — Product Info ──────────────────────────────────────────────────

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Information',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 0.5.h),
            Text(
              'Enter the product name and brand so others can find it.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            SizedBox(height: 2.5.h),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: 2.h),

            // Brand
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: 2.h),

            // Barcode (read-only)
            TextFormField(
              initialValue: widget.barcode.isEmpty ? '—' : widget.barcode,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Barcode',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
              ),
            ),
            SizedBox(height: 4.h),

            SizedBox(
              width: double.infinity,
              height: 6.5.h,
              child: ElevatedButton(
                onPressed: () {
                  if (_step1Key.currentState?.validate() ?? false) {
                    _goToStep(1);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Next',
                    style: TextStyle(
                        fontSize: 13.sp, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2 — Label Photo ───────────────────────────────────────────────────

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nutritional Label',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 0.5.h),
          Text(
            'Take a photo of the nutritional label. AI will extract macros automatically.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          SizedBox(height: 2.5.h),

          // Image preview / placeholder
          GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              width: double.infinity,
              height: 28.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.35),
                ),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            size: 10.w,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.35)),
                        SizedBox(height: 1.h),
                        Text('Tap to take a photo',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 1.5.h),

          // Photo action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(_imageBytes == null ? 'Take Photo' : 'Retake',
                      style: TextStyle(fontSize: 11.sp)),
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text('Gallery',
                      style: TextStyle(fontSize: 11.sp)),
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Extract button
          if (_imageBytes != null && !_isExtracting)
            SizedBox(
              width: double.infinity,
              height: 6.5.h,
              child: ElevatedButton.icon(
                onPressed: _extractMacros,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  'Extract Macros with AI',
                  style: TextStyle(
                      fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

          // Shimmer-style loading during extraction
          if (_isExtracting) ...[
            SizedBox(
              width: double.infinity,
              height: 6.5.h,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: SizedBox(
                  width: 4.w,
                  height: 4.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onTertiary,
                  ),
                ),
                label: Text('Extracting macros…',
                    style: TextStyle(fontSize: 13.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'This may take up to 10 seconds…',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 1.5.h),

          // "Enter Manually" skip link
          Center(
            child: TextButton(
              onPressed: () => _goToStep(2),
              child: Text('Enter Manually',
                  style: TextStyle(fontSize: 12.sp)),
            ),
          ),
          SizedBox(height: 1.h),

          // Back
          Center(
            child: TextButton(
              onPressed: () => _goToStep(0),
              child: Text('Back',
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5))),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3 — Review & Submit ───────────────────────────────────────────────

  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Form(
        key: _step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nutritional Values (per 100g)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 0.5.h),
            Text(
              'Review and correct if needed. Required fields marked *.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            SizedBox(height: 2.h),

            // Required macros
            _NumField(
                controller: _caloriesController,
                label: 'Calories (kcal) *',
                required: true),
            SizedBox(height: 1.5.h),
            _NumField(
                controller: _proteinController,
                label: 'Protein (g) *',
                required: true),
            SizedBox(height: 1.5.h),
            _NumField(
                controller: _carbsController,
                label: 'Carbohydrates (g) *',
                required: true),
            SizedBox(height: 1.5.h),
            _NumField(
                controller: _fatController,
                label: 'Total Fat (g) *',
                required: true),
            SizedBox(height: 1.5.h),
            _NumField(
                controller: _servingSizeController,
                label: 'Serving Size (g)',
                required: false),
            SizedBox(height: 2.h),

            // Detailed nutrition expandable
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text('Detailed Nutrition (optional)',
                    style: theme.textTheme.bodyMedium),
                initiallyExpanded: _sugarController.text.isNotEmpty ||
                    _satFatController.text.isNotEmpty,
                childrenPadding:
                    EdgeInsets.symmetric(horizontal: 0, vertical: 0.5.h),
                children: [
                  // ── Carbohydrate breakdown ──
                  Padding(
                    padding: EdgeInsets.only(top: 0.5.h, bottom: 1.h),
                    child: Text('Carbohydrate Breakdown',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                  _NumField(
                      controller: _sugarController,
                      label: 'Sugar (g)',
                      required: false),
                  SizedBox(height: 1.5.h),
                  _NumField(
                      controller: _starchController,
                      label: 'Starch (g)',
                      required: false),
                  SizedBox(height: 1.5.h),
                  _NumField(
                      controller: _polyolsController,
                      label: 'Polyols (g)',
                      required: false),
                  SizedBox(height: 1.5.h),
                  _NumField(
                      controller: _fiberController,
                      label: 'Fiber (g)',
                      required: false),
                  SizedBox(height: 2.h),

                  // ── Fat breakdown ──
                  Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Text('Fat Breakdown',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                  _NumField(
                      controller: _satFatController,
                      label: 'Saturated Fat (g)',
                      required: false),
                  SizedBox(height: 1.5.h),
                  _NumField(
                      controller: _monoFatController,
                      label: 'Monounsaturated Fat (g)',
                      required: false),
                  SizedBox(height: 1.5.h),
                  _NumField(
                      controller: _polyFatController,
                      label: 'Polyunsaturated Fat (g)',
                      required: false),
                  SizedBox(height: 1.5.h),
                  _NumField(
                      controller: _transFatController,
                      label: 'Trans Fat (g)',
                      required: false),
                  SizedBox(height: 2.h),

                  // ── Other ──
                  Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Text('Other',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                  _NumField(
                      controller: _cholesterolController,
                      label: 'Cholesterol (mg)',
                      required: false),
                  SizedBox(height: 1.5.h),
                  _NumField(
                      controller: _sodiumController,
                      label: 'Sodium (mg)',
                      required: false),
                  SizedBox(height: 1.5.h),
                  _NumField(
                      controller: _saltController,
                      label: 'Salt (g)',
                      required: false),
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 6.5.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 3.h,
                        width: 3.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onTertiary,
                        ),
                      )
                    : Text(_isEditMode ? 'Update Product' : 'Submit Product',
                        style: TextStyle(
                            fontSize: 13.sp, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 1.5.h),

            // Back
            Center(
              child: TextButton(
                onPressed: () => _goToStep(1),
                child: Text('Back',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 5.w),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == currentStep;
          final done = i < currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: done || active
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (i < 2) SizedBox(width: 1.w),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;

  const _NumField({
    required this.controller,
    required this.label,
    required this.required,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      ),
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Enter a valid number';
              return null;
            }
          : (v) {
              if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                return 'Enter a valid number';
              }
              return null;
            },
    );
  }
}
