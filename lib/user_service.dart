import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔍 Check user exists
  Future<bool> userExists(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    return doc.exists;
  }

  // 🆕 Create user (called after signup)
  Future<void> createUser({
    required String uid,
    required String phone,
    required String role,
    String name = '',
    String email = '',
    String photoUrl = '',
  }) async {
    await _db.collection("users").doc(uid).set({
      "phone": phone,
      "role": role,
      "profileCompleted": false,
      "createdAt": FieldValue.serverTimestamp(),
      if (name.isNotEmpty) "name": name,
      if (email.isNotEmpty) "email": email,
      if (photoUrl.isNotEmpty) "photoUrl": photoUrl,
    }, SetOptions(merge: true));
  }

  // 📥 Get user
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // ✏️ Update profile
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection("users").doc(uid).set({
      ...data,
      "profileCompleted": true,
    }, SetOptions(merge: true));
  }

  // ⭐ Check Gold membership — FIXED: was empty, now reads Firestore field
  Future<bool> isGoldMember(String uid) async {
    try {
      final doc = await _db.collection("users").doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['isGoldMember'] == true;
    } catch (e) {
      return false;
    }
  }
}
