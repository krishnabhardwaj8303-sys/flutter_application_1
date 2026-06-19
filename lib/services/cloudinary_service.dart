import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // ─── Your Cloudinary free-tier credentials ───────────────────────────────
  // Go to: https://console.cloudinary.com → Dashboard → copy these values
  static const String _cloudName = "doeswlkl3"; // e.g. "dxyz123abc"
  static const String _uploadPreset =
      "worker_upload"; // create an UNSIGNED preset in Settings → Upload

  // ─── Upload any image file and return its secure URL ─────────────────────
  static Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = _uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath("file", imageFile.path),
      );

    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 60), // fail cleanly on slow connections
          onTimeout: () =>
              throw Exception("Upload timed out. Check your internet."),
        );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final url = json["secure_url"] as String?;
      if (url == null || url.isEmpty) {
        throw Exception("Cloudinary returned no URL.");
      }
      return url; // ← this is what gets saved in Firestore
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        "Cloudinary upload failed: ${error["error"]?["message"] ?? response.statusCode}",
      );
    }
  }
}
