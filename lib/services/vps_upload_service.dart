import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'cloudinary_service.dart';

class VpsUploadService {
  static const String baseUrl = 'http://nthiennhan.ddns.net:90';
  static const String uploadEndpoint = '$baseUrl/api/upload.php';

  final CloudinaryService _cloudinaryFallback = CloudinaryService();

  /// Upload ảnh hóa đơn / biên lai lên VPS của bạn
  /// [imageFile]: File ảnh cần upload
  /// [folder]: Thư mục lưu trữ (mặc định là 'receipts')
  /// [useFallback]: Nếu upload VPS thất bại, tự động fallback sang Cloudinary để đảm bảo không mất ảnh
  Future<String?> uploadImage(
    File imageFile, {
    String folder = 'receipts',
    bool useFallback = true,
  }) async {
    try {
      debugPrint('🚀 Đang upload ảnh lên VPS: $uploadEndpoint (folder: $folder)...');
      
      final uri = Uri.parse(uploadEndpoint);
      final request = http.MultipartRequest('POST', uri);
      
      request.fields['folder'] = folder;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Timeout sau 12 giây nếu server VPS không phản hồi
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 12),
      );
      
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['url'] != null) {
          final imageUrl = data['url'] as String;
          debugPrint('✅ Upload VPS thành công: $imageUrl');
          return imageUrl;
        }
      }

      debugPrint('⚠️ VPS upload trả về mã lỗi: ${response.statusCode}, body: ${response.body}');
    } catch (e) {
      debugPrint('⚠️ Lỗi upload lên VPS ($e)');
    }

    // Nếu upload VPS không thành công và bật fallback
    if (useFallback) {
      debugPrint('🔄 Đang thử fallback upload sang Cloudinary...');
      try {
        final fallbackUrl = await _cloudinaryFallback.uploadImage(
          imageFile,
          folder: 'expense_manager/$folder',
        );
        if (fallbackUrl != null) {
          debugPrint('✅ Fallback upload Cloudinary thành công: $fallbackUrl');
          return fallbackUrl;
        }
      } catch (e) {
        debugPrint('❌ Fallback Cloudinary cũng thất bại: $e');
      }
    }

    return null;
  }

  /// Upload ảnh đại diện nhóm / cá nhân
  Future<String?> uploadAvatar(File imageFile, String subFolder) async {
    return uploadImage(imageFile, folder: 'avatars/$subFolder');
  }

  /// Kiểm tra kết nối tới server VPS port 90
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/app/version.json'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
