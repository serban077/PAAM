import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../../services/open_food_facts_service.dart';
import '../../../../services/supabase_service.dart';
import 'product_found_screen.dart';

/// Barcode Scanner Page
///
/// Lookup chain (15.2):
///   1. Query local `food_database` by barcode (Supabase)
///   2. If not found → Open Food Facts API
///   3. If found via OFF → cache in Supabase (`is_verified = false`)
///   4. If still not found → pop back with [_kNotFound] so the caller
///      can show a "not found" message. Camera stops, no infinite loop.
///   5. If found → [Navigator.pushReplacement] to [ProductFoundScreen]
///
/// UX (15.3 + 15.5): animated scan-line, scan cooldown,
/// permission-denied empty state.
class BarcodeScannerPage extends StatefulWidget {
  /// Called after a product is successfully logged in [ProductFoundScreen].
  final VoidCallback onFoodAdded;

  const BarcodeScannerPage({super.key, required this.onFoodAdded});

  /// Sentinel value returned via [Navigator.pop] when barcode was scanned
  /// but the product was not found in either Supabase or Open Food Facts.
  static const String kNotFound = 'not_found';

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with SingleTickerProviderStateMixin {
  // ── Camera ────────────────────────────────────────────────────────────────
  final MobileScannerController _controller = MobileScannerController();

  // ── Scan state ────────────────────────────────────────────────────────────
  bool _isProcessing = false;
  String? _lastBarcode;
  String _statusMessage = 'Point camera at a food barcode';

  // ── Scan-line animation ───────────────────────────────────────────────────
  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;

  static const double _guideHeightFraction = 0.25;
  static const double _guideWidthFraction = 0.70;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnimation = CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ── Barcode detection ─────────────────────────────────────────────────────

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode == _lastBarcode) return;

    setState(() {
      _isProcessing = true;
      _lastBarcode = barcode;
      _statusMessage = 'Looking up barcode…';
    });

    // Stop scanning immediately — no more detections while we work.
    await _controller.stop();

    try {
      // Step 1 — local Supabase cache
      Map<String, dynamic>? food = await SupabaseService.instance.client
          .from('food_database')
          .select()
          .eq('barcode', barcode)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      // Step 2 — Open Food Facts fallback
      if (food == null) {
        setState(() => _statusMessage = 'Searching Open Food Facts…');
        final offData = await OpenFoodFactsService().lookupBarcode(barcode);

        if (!mounted) return;

        if (offData != null) {
          // Step 3 — cache to Supabase, get back the row with its new `id`
          food = await SupabaseService.instance.client
              .from('food_database')
              .insert(offData)
              .select()
              .single()
              .timeout(const Duration(seconds: 15));
        }
      }

      if (!mounted) return;

      // Step 4 — not found anywhere → go back, let caller show message
      if (food == null) {
        Navigator.pop(context, BarcodeScannerPage.kNotFound);
        return;
      }

      // Step 5 — found → navigate to full product page (replaces scanner)
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductFoundScreen(
            food: food!,
            onFoodAdded: widget.onFoodAdded,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // On error, resume camera and let user try again
      await _controller.start();
      setState(() {
        _isProcessing = false;
        _lastBarcode = null;
        _statusMessage = 'Point camera at a food barcode';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final guideH = screenH * _guideHeightFraction;
    final guideW = screenW * _guideWidthFraction;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onBarcodeDetected,
        errorBuilder: (context, error) =>
            _buildPermissionDeniedState(theme),
        overlayBuilder: (context, constraints) => _buildOverlay(
          theme,
          guideH: guideH,
          guideW: guideW,
        ),
      ),
    );
  }

  Widget _buildOverlay(
    ThemeData theme, {
    required double guideH,
    required double guideW,
  }) {
    return Stack(
      children: [
        // Guide rectangle + animated scan-line
        Center(
          child: SizedBox(
            width: guideW,
            height: guideH,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                AnimatedBuilder(
                  animation: _scanLineAnimation,
                  builder: (_, __) {
                    final top = _scanLineAnimation.value * (guideH - 4);
                    return Positioned(
                      top: top,
                      left: 8,
                      right: 8,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.85),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Status chip
        Positioned(
          bottom: 8.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isProcessing) ...[
                    SizedBox(
                      width: 4.w,
                      height: 4.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 2.w),
                  ],
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
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

  Widget _buildPermissionDeniedState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_outlined,
                size: 15.w, color: Colors.white54),
            SizedBox(height: 2.h),
            const Text(
              'Camera permission required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            const Text(
              'Grant camera access to scan food barcodes.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: 6.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
