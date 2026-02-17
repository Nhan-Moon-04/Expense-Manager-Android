import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfo {
  final String latestVersion;
  final String minVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  VersionInfo({
    required this.latestVersion,
    required this.minVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  factory VersionInfo.fromMap(Map<String, dynamic> map) {
    return VersionInfo(
      latestVersion: map['latestVersion'] ?? '1.0.0',
      minVersion: map['minVersion'] ?? '1.0.0',
      downloadUrl: map['downloadUrl'] ?? '',
      releaseNotes: map['releaseNotes'] ?? '',
      forceUpdate: map['forceUpdate'] ?? false,
    );
  }
}

enum UpdateStatus {
  upToDate, // App đã mới nhất
  optionalUpdate, // Có bản mới, người dùng chọn cập nhật hoặc bỏ qua
  forceUpdate, // Bắt buộc cập nhật, không thể bỏ qua
}

class VersionCheckResult {
  final UpdateStatus status;
  final VersionInfo? versionInfo;
  final String currentVersion;

  VersionCheckResult({
    required this.status,
    this.versionInfo,
    required this.currentVersion,
  });
}

class VersionService {
  // URL tới file version.json trên Armbian server
  static const String versionUrl =
      'http://nthiennhan.ddns.net:90/app/version.json';
  static const String apkBaseUrl = 'http://nthiennhan.ddns.net:90/app/';

  /// So sánh 2 version string (vd: "1.2.3" vs "1.3.0")
  /// Trả về: -1 nếu v1 < v2, 0 nếu bằng, 1 nếu v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    // Đảm bảo cả 2 có 3 phần (major.minor.patch)
    while (parts1.length < 3) {
      parts1.add(0);
    }
    while (parts2.length < 3) {
      parts2.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  /// Kiểm tra phiên bản từ Armbian server
  /// Fetch từ: http://nthiennhan.ddns.net:90/app/version.json
  Future<VersionCheckResult> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // vd: "1.0.0"

      print('🔍 Checking for updates...');
      print('📱 Current version: $currentVersion');
      print('🌐 Fetching from: $versionUrl');

      // Fetch version info từ Armbian server
      final response = await http
          .get(Uri.parse(versionUrl))
          .timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('❌ Server returned ${response.statusCode}');
        return VersionCheckResult(
          status: UpdateStatus.upToDate,
          currentVersion: currentVersion,
        );
      }

      print('📄 Response body: ${response.body}');
      final data = json.decode(response.body) as Map<String, dynamic>;
      final versionInfo = VersionInfo.fromMap(data);

      print('🆕 Latest version: ${versionInfo.latestVersion}');
      print('⚙️  Min version: ${versionInfo.minVersion}');

      // Nếu version hiện tại < minVersion → bắt buộc cập nhật
      if (_compareVersions(currentVersion, versionInfo.minVersion) < 0) {
        print('⚠️  Force update required (current < min)');
        return VersionCheckResult(
          status: UpdateStatus.forceUpdate,
          versionInfo: versionInfo,
          currentVersion: currentVersion,
        );
      }

      // Nếu version hiện tại < latestVersion → có bản mới (tùy chọn hoặc force)
      if (_compareVersions(currentVersion, versionInfo.latestVersion) < 0) {
        print(
          '✨ Update available: $currentVersion → ${versionInfo.latestVersion}',
        );
        return VersionCheckResult(
          status: versionInfo.forceUpdate
              ? UpdateStatus.forceUpdate
              : UpdateStatus.optionalUpdate,
          versionInfo: versionInfo,
          currentVersion: currentVersion,
        );
      }

      // Đã mới nhất
      print('✅ Already up to date');
      return VersionCheckResult(
        status: UpdateStatus.upToDate,
        versionInfo: versionInfo,
        currentVersion: currentVersion,
      );
    } catch (e, stackTrace) {
      // Nếu lỗi (offline, etc.) → bỏ qua, cho dùng app bình thường
      print('❌ Error checking for updates: $e');
      print('Stack trace: $stackTrace');
      return VersionCheckResult(
        status: UpdateStatus.upToDate,
        currentVersion: '?.?.?',
      );
    }
  }
}
