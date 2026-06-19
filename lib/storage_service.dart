import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(File file, String uid) async {
    try {
      Reference ref = _storage.ref().child("profile_images/$uid.webp");

      await ref.putFile(file);

      String downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception("Image upload failed");
    }
  }
}
