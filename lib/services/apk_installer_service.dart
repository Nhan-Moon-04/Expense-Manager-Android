import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ApkInstallerService {
  final Dio _dio = Dio();

  /// Download APK từ URL và install
  /// [url]: URL tới file APK trên Armbian server
  /// [onProgress]: Callback để cập nhật progress (0.0 - 1.0)
  Future<bool> downloadAndInstallApk(
    String url, {
    Function(double)? onProgress,
  }) async {
    try {
      // 1. Request storage permission (Android 10+)
      if (await _requestPermission()) {
        debugPrint('✅ Storage permission granted');
      } else {
        debugPrint('❌ Storage permission denied');
        return false;
      }

      // 2. Get download directory
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        debugPrint('❌ Cannot get storage directory');
        return false;
      }

      final filePath = '${dir.path}/expense_manager_update.apk';
      final file = File(filePath);

      // 3. Delete old APK if exists
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Deleted old APK');
      }

      debugPrint('📥 Downloading APK from: $url');
      debugPrint('💾 Saving to: $filePath');

      // 4. Download APK with progress
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress?.call(progress);
            debugPrint(
              '⬇️ Download progress: ${(progress * 100).toStringAsFixed(1)}%',
            );
          }
        },
      );

      debugPrint('✅ Download completed');

      // 5. Install APK
      final result = await OpenFile.open(filePath);
      debugPrint('📱 Install result: ${result.message}');

      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('❌ Error downloading/installing APK: $e');
      return false;
    }
  }

  /// Request install packages permission (Android 8+)
  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      // Android 10+ cần REQUEST_INSTALL_PACKAGES permission
      // Được handle tự động bởi open_file package

      // Nếu cần storage permission (Android < 13)
      if (await Permission.storage.isDenied) {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
      return true;
    }
    return false;
  }

  /// Cancel download (nếu cần)
  void cancelDownload() {
    _dio.close(force: true);
  }
}
