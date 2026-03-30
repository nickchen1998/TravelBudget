import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageStorageService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'trip-covers';

  /// Compresses [localPath] to WebP and uploads to Supabase Storage.
  /// Returns the public URL, or null on failure.
  static Future<String?> uploadTripCover(
      String localPath, String tripUuid) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final Uint8List? compressed =
          await FlutterImageCompress.compressWithFile(
        localPath,
        format: CompressFormat.webp,
        quality: 82,
        minWidth: 1200,
        minHeight: 1,
      );
      if (compressed == null) return null;

      final objectPath = '$userId/$tripUuid.webp';
      await _supabase.storage.from(_bucket).uploadBinary(
            objectPath,
            compressed,
            fileOptions: const FileOptions(
              contentType: 'image/webp',
              upsert: true,
            ),
          );

      return _supabase.storage.from(_bucket).getPublicUrl(objectPath);
    } catch (_) {
      return null;
    }
  }

  /// Deletes the trip cover from storage (best-effort).
  static Future<void> deleteTripCover(String tripUuid) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.storage
          .from(_bucket)
          .remove(['$userId/$tripUuid.webp']);
    } catch (_) {}
  }
}
