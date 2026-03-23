import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';

import '../../../../services/supabase_service.dart';

/// Barcode Scanner Page
/// Scans food barcodes and returns matching food from Supabase food_database
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _isProcessing = false;
  String? _lastBarcode;

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || _isProcessing) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode == _lastBarcode) return;

    setState(() {
      _isProcessing = true;
      _lastBarcode = barcode;
    });

    try {
      final result = await SupabaseService.instance.client
          .from('food_database')
          .select()
          .eq('barcode', barcode)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (result != null) {
        Navigator.pop(context, result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No food found for barcode: $barcode'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isProcessing = false;
          _lastBarcode = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error looking up barcode: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isProcessing = false;
        _lastBarcode = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onBarcodeDetected),
          // Overlay guide
          Center(
            child: Container(
              width: 70.w,
              height: 25.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 8.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isProcessing
                      ? 'Looking up barcode...'
                      : 'Point camera at a food barcode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}
