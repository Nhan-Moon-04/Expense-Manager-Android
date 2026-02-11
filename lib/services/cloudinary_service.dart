import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dfjf8fez3';
  static const String apiKey = '132588679561889';
  static const String apiSecret = 'mupBpneSN1qHq4ue3-YSUS_Gf94';

  /// Upload image to Cloudinary
  /// Returns the secure URL of the uploaded image or null if failed
  Future<String?> uploadImage(File imageFile, {String? folder}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Create signature
      String toSign = 'timestamp=$timestamp';
      if (folder != null) {
        toSign = 'folder=$folder&timestamp=$timestamp';
      }
      toSign += apiSecret;

      final signature = sha1.convert(utf8.encode(toSign)).toString();

      // Prepare upload request
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['secure_url'];
      } else {
        print('Cloudinary upload error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload exception: $e');
      return null;
    }
  }

  /// Upload user avatar
  Future<String?> uploadUserAvatar(File imageFile, String userId) async {
    return uploadImage(imageFile, folder: 'expense_manager/avatars/$userId');
  }

  /// Upload group avatar
  Future<String?> uploadGroupAvatar(File imageFile, String groupId) async {
    return uploadImage(imageFile, folder: 'expense_manager/groups/$groupId');
  }

  /// Delete image from Cloudinary by public ID
  Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final toSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(toSign)).toString();

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
      );

      final response = await http.post(
        uri,
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] == 'ok';
      }
      return false;
    } catch (e) {
      print('Cloudinary delete exception: $e');
      return false;
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedUrl(
    String url, {
    int? width,
    int? height,
    String quality = 'auto',
  }) {
    // Parse the original URL and add transformations
    if (!url.contains('cloudinary.com')) return url;

    final parts = url.split('/upload/');
    if (parts.length != 2) return url;

    String transformation = 'q_$quality,f_auto';
    if (width != null) transformation += ',w_$width';
    if (height != null) transformation += ',h_$height';
    transformation += ',c_fill';

    return '${parts[0]}/upload/$transformation/${parts[1]}';
  }

  /// Get circular cropped avatar URL
  String getAvatarUrl(String url, {int size = 200}) {
    if (!url.contains('cloudinary.com')) return url;

    final parts = url.split('/upload/');
    if (parts.length != 2) return url;

    return '${parts[0]}/upload/w_$size,h_$size,c_fill,g_face,r_max,q_auto,f_auto/${parts[1]}';
  }
}
