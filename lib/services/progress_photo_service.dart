import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Service for persisting progress photos to Supabase Storage + metadata table.
class ProgressPhotoService {
  final _client = SupabaseService.instance.client;
  static const _bucket = 'progress-photos';
  static const _signedUrlExpiry = 604800; // 7 days

  String get _userId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  // ── Upload ──────────────────────────────────────────────────────────────────

  /// Uploads a local file to Supabase Storage.
  /// Returns the storage path (userId/timestamp_label.jpg).
  Future<String> _uploadFile(String localPath, String label) async {
    final file = File(localPath);
    final bytes = await file.readAsBytes().timeout(const Duration(seconds: 15));

    final isPng = localPath.toLowerCase().endsWith('.png');
    final ext = isPng ? 'png' : 'jpg';
    final contentType = isPng ? 'image/png' : 'image/jpeg'; // must match bucket allowed_mime_types
    final ts = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$_userId/${ts}_$label.$ext';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        )
        .timeout(const Duration(seconds: 30));

    return storagePath;
  }

  // ── Signed URL ──────────────────────────────────────────────────────────────

  Future<String> getSignedUrl(String storagePath) async {
    try {
      return await _client.storage
          .from(_bucket)
          .createSignedUrl(storagePath, _signedUrlExpiry)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return '';
    }
  }

  // ── Save entry ──────────────────────────────────────────────────────────────

  /// Uploads before (and optionally after) photos, then inserts metadata row.
  /// Returns the newly created entry with signed URLs ready for display.
  Future<Map<String, dynamic>> saveEntry({
    required String localBeforePath,
    String? localAfterPath,
    required String dateLabel,
    required String notes,
  }) async {
    try {
      final beforePath = await _uploadFile(localBeforePath, 'before');
      final afterPath = localAfterPath != null
          ? await _uploadFile(localAfterPath, 'after')
          : null;

      final row = await _client
          .from('progress_photos')
          .insert({
            'user_id': _userId,
            'date_label': dateLabel,
            'notes': notes,
            'before_path': beforePath,
            'after_path': afterPath,
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 15));

      return await _attachSignedUrls(row);
    } catch (e) {
      throw Exception('saveEntry failed: $e');
    }
  }

  // ── Load ────────────────────────────────────────────────────────────────────

  /// Returns all entries for the current user, newest first, with signed URLs.
  Future<List<Map<String, dynamic>>> getUserPhotos() async {
    try {
      final rows = await _client
          .from('progress_photos')
          .select('id, date_label, notes, before_path, after_path, created_at')
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 15));

      final results = <Map<String, dynamic>>[];
      for (final row in rows) {
        results.add(await _attachSignedUrls(row));
      }
      return results;
    } catch (e) {
      throw Exception('getUserPhotos failed: $e');
    }
  }

  Future<Map<String, dynamic>> _attachSignedUrls(Map<String, dynamic> row) async {
    final beforeUrl = await getSignedUrl(row['before_path'] as String);
    final afterPath = row['after_path'] as String?;
    final afterUrl = afterPath != null ? await getSignedUrl(afterPath) : null;

    return {
      'id': row['id'],
      'date_label': row['date_label'],
      'notes': row['notes'],
      'before_url': beforeUrl,
      'after_url': afterUrl,
      'before_path': row['before_path'],
      'after_path': afterPath,
    };
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<void> deleteEntry(String id, String beforePath, String? afterPath) async {
    try {
      await _client
          .from('progress_photos')
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 15));

      final paths = [beforePath, if (afterPath != null) afterPath];
      await _client.storage
          .from(_bucket)
          .remove(paths)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('deleteEntry failed: $e');
    }
  }
}
