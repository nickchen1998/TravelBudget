import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageStorageService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'trip-covers';

  /// 將圖片壓縮為 WebP 並持久化到 App 文件目錄。
  /// 回傳永久路徑，或在失敗時回傳原始路徑。
  static Future<String> persistLocalCover(String tempPath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${dir.path}/trip_covers');
      if (!coverDir.existsSync()) coverDir.createSync(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final destPath = '${coverDir.path}/$timestamp.webp';

      final Uint8List? compressed =
          await FlutterImageCompress.compressWithFile(
        tempPath,
        format: CompressFormat.webp,
        quality: 82,
        minWidth: 1200,
        minHeight: 1,
      );

      if (compressed != null) {
        await File(destPath).writeAsBytes(compressed);
        return destPath;
      }
    } catch (_) {}
    // 壓縮失敗時 fallback：直接複製原始檔案
    try {
      final dir = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${dir.path}/trip_covers');
      if (!coverDir.existsSync()) coverDir.createSync(recursive: true);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = tempPath.split('.').last;
      final destPath = '${coverDir.path}/$timestamp.$ext';
      await File(tempPath).copy(destPath);
      return destPath;
    } catch (_) {
      return tempPath;
    }
  }

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
