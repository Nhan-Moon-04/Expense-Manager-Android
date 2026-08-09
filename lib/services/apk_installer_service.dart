import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
      // 1. Check Android version và request permission nếu cần
      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        debugPrint('❌ Storage permission denied');
        return false;
      }

      // 2. Get download directory (ưu tiên External Storage, fallback sang Temporary)
      Directory? dir = await getExternalStorageDirectory();
      dir ??= await getTemporaryDirectory();

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

      debugPrint('✅ Download completed: $filePath');

      // 5. Verify file exists
      if (!await file.exists()) {
        debugPrint('❌ Downloaded file not found!');
        return false;
      }

      final fileSize = await file.length();
      debugPrint(
        '📦 APK size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // 6. Install APK
      debugPrint('📱 Opening APK installer...');
      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      debugPrint('📱 Install result: ${result.type} - ${result.message}');

      return result.type == ResultType.done;
    } catch (e, stackTrace) {
      debugPrint('❌ Error downloading/installing APK: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Request storage & install permissions
  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      debugPrint('📱 Android SDK: $sdkInt');

      // 1. Check & request install packages permission (Android 8.0+ / API 26+)
      if (sdkInt >= 26) {
        final installStatus = await Permission.requestInstallPackages.status;
        debugPrint('📋 Install packages permission status: $installStatus');
        if (!installStatus.isGranted) {
          debugPrint('📋 Requesting install packages permission...');
          final status = await Permission.requestInstallPackages.request();
          if (!status.isGranted) {
            debugPrint('❌ Install packages permission denied');
            if (status.isPermanentlyDenied) {
              await openAppSettings();
            }
            return false;
          }
        }
      }

      // 2. Android 13+ (API 33+): Không cần storage permission cho app-specific directory
      if (sdkInt >= 33) {
        debugPrint('✅ Android 13+: No storage permission needed');
        return true;
      }

      // 3. Android < 33: Check storage permission
      if (await Permission.storage.isGranted) {
        debugPrint('✅ Storage permission already granted');
        return true;
      }

      debugPrint('📋 Requesting storage permission...');
      final status = await Permission.storage.request();

      if (status.isGranted) {
        debugPrint('✅ Storage permission granted');
        return true;
      } else if (status.isPermanentlyDenied) {
        debugPrint(
          '⚠️ Storage permission permanently denied, opening settings...',
        );
        await openAppSettings();
        return false;
      } else {
        debugPrint('❌ Storage permission denied');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error requesting permission: $e');
      // Nếu lỗi, cho phép tiếp tục
      return true;
    }
  }

  /// Cancel download (nếu cần)
  void cancelDownload() {
    _dio.close(force: true);
  }
}
