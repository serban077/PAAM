import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/exercise_db_service.dart';
import '../utils/exercise_gif_utils.dart';

/// Shows an animated 3D exercise demonstration.
///
/// Priority:
/// 1. ExerciseDB animated GIF (if `EXERCISEDB_API_KEY` is in env.json)
/// 2. free-exercise-db 2-frame crossfade fallback
/// 3. Placeholder icon
///
/// Use the same widget in every screen that shows exercise animations
/// to guarantee visual consistency across the app.
class Exercise3DWidget extends StatefulWidget {
  /// Exercise name in English (used for ExerciseDB + free-exercise-db lookup).
  final String exerciseName;

  /// Container height. Defaults to 200 logical pixels.
  final double height;

  const Exercise3DWidget({
    super.key,
    required this.exerciseName,
    this.height = 200,
  });

  @override
  State<Exercise3DWidget> createState() => _Exercise3DWidgetState();
}

class _Exercise3DWidgetState extends State<Exercise3DWidget> {
  final _service = ExerciseDbService();
  String? _exerciseDbId;
  bool _loading = true;
  bool _useFallback = false;

  // Fallback: free-exercise-db 2-frame animation
  Timer? _frameTimer;
  bool _showFrame1 = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant Exercise3DWidget old) {
    super.didUpdateWidget(old);
    if (old.exerciseName != widget.exerciseName) {
      _frameTimer?.cancel();
      _showFrame1 = false;
      _resolve();
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  // ── Resolve exercise → 3D GIF or fallback ──────────────────────────
  Future<void> _resolve() async {
    setState(() {
      _loading = true;
      _useFallback = false;
    });

    if (!_service.isAvailable) {
      _activateFallback();
      return;
    }

    final id = await _service.getExerciseId(widget.exerciseName);
    if (!mounted) return;

    if (id != null) {
      setState(() {
        _exerciseDbId = id;
        _loading = false;
      });
    } else {
      _activateFallback();
    }
  }

  void _activateFallback() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _useFallback = true;
    });

    final f0 = ExerciseGifUtils.getFrame0Url(widget.exerciseName);
    final f1 = ExerciseGifUtils.getFrame1Url(widget.exerciseName);
    if (f0 != null && f1 != null) {
      _frameTimer = Timer.periodic(
        const Duration(milliseconds: 1100),
        (_) {
          if (mounted) setState(() => _showFrame1 = !_showFrame1);
        },
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFF2A2A2A);

    if (_loading) return _box(bg, child: _spinner());

    // ExerciseDB 3D GIF
    if (!_useFallback && _exerciseDbId != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: bg,
          child: CachedNetworkImage(
            imageUrl: _service.gifUrl(_exerciseDbId!),
            httpHeaders: _service.authHeaders,
            width: double.infinity,
            height: widget.height,
            fit: BoxFit.contain,
            fadeInDuration: const Duration(milliseconds: 200),
            memCacheHeight: widget.height.isFinite && widget.height > 0
                ? widget.height.toInt()
                : null,
            placeholder: (_, __) => _box(bg, child: _spinner()),
            errorWidget: (_, __, ___) => _buildFallback(bg),
          ),
        ),
      );
    }

    return _buildFallback(bg);
  }

  Widget _buildFallback(Color bg) {
    final f0 = ExerciseGifUtils.getFrame0Url(widget.exerciseName);
    if (f0 == null) return _box(bg, child: _placeholder());

    final f1 = ExerciseGifUtils.getFrame1Url(widget.exerciseName);
    final url = (_showFrame1 && f1 != null) ? f1 : f0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: CachedNetworkImage(
        key: ValueKey(url),
        imageUrl: url,
        width: double.infinity,
        height: widget.height,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        memCacheHeight: widget.height.isFinite && widget.height > 0
            ? widget.height.toInt()
            : null,
        placeholder: (_, __) => _box(bg, child: _spinner()),
        errorWidget: (_, __, ___) => _box(bg, child: _placeholder()),
      ),
    );
  }

  // ── Tiny helpers ───────────────────────────────────────────────────
  Widget _box(Color bg, {required Widget child}) => Container(
        width: double.infinity,
        height: widget.height,
        color: bg,
        child: Center(child: child),
      );

  Widget _spinner() => const CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white38,
      );

  Widget _placeholder() => const Icon(
        Icons.fitness_center,
        color: Colors.white24,
        size: 48,
      );
}
