import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Screens
import 'user_service.dart';
import 'my_booking_screen.dart';
import 'subscription_screen.dart';
import 'rewards_screen.dart';
import 'ReferEarn_screen.dart';
import 'HelpSupport_screen.dart';
import 'safety_screen.dart';
import 'Settings_screen.dart'; // ✅ only one import, capital S
import 'about_screen.dart';
import 'customer_profile_setup.dart';

// Cloudinary Service
import '../services/cloudinary_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;

  bool isLoading = true;
  bool isUploadingImage = false;
  bool isGoldMember = false;

  File? selectedImage;
  String? imageUrl;

  final ImagePicker _picker = ImagePicker();

  // Theme Colors
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanDark = Color(0xFF0891B2);
  static const Color cyanLight = Color(0xFFECFEFF);
  static const Color gold = Color(0xFFFFB800);

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // ---------------- LOAD USER ----------------
  Future<void> loadUser() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() => isLoading = false);
        return;
      }

      final data = await UserService().getUser(user.uid);

      if (!mounted) return;

      bool goldStatus = false;

      if (data?['goldMember'] == true) {
        final until = (data!['goldUntil'] as Timestamp?)?.toDate();

        if (until != null && until.isAfter(DateTime.now())) {
          goldStatus = true;
        }
      }

      setState(() {
        userData = data;
        imageUrl = data?['imageUrl'];
        isGoldMember = goldStatus;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showSnack("Failed to load user data");
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  // ---------------- IMAGE OPTIONS ----------------
  void showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            imageOption(
              icon: Icons.camera_alt,
              title: "Camera",
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
            imageOption(
              icon: Icons.photo_library,
              title: "Gallery",
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget imageOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cyanLight,
            child: Icon(
              icon,
              color: cyanDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PICK IMAGE ----------------
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        selectedImage = File(pickedFile.path);
      });

      await uploadImageToCloudinary();
    } catch (e) {
      if (!mounted) return;
      showSnack("Failed to pick image");
    }
  }

  // ---------------- UPLOAD IMAGE ----------------
  Future<void> uploadImageToCloudinary() async {
    if (selectedImage == null) return;

    try {
      setState(() {
        isUploadingImage = true;
      });

      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) throw Exception("User not logged in");

      final String? cloudinaryUrl =
          await CloudinaryService.uploadImage(selectedImage!);

      if (cloudinaryUrl == null) {
        throw Exception("Upload failed");
      }

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "imageUrl": cloudinaryUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        imageUrl = cloudinaryUrl;
        isUploadingImage = false;
      });

      showSnack("Profile photo updated successfully");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploadingImage = false;
      });

      showSnack("Image upload failed");
    }
  }

  // ---------------- SNACKBAR ----------------
  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cyanDark,
      ),
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    final String name = userData?["name"] ?? "No Name";
    final String email = userData?["email"] ?? "";
    final String phone = userData?["phone"] ??
        FirebaseAuth.instance.currentUser?.phoneNumber ??
        "No Phone";

    return Scaffold(
      backgroundColor: const Color(0xFFF5FCFD),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: cyan,
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 310,
                  pinned: true,
                  backgroundColor: cyanDark,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF0891B2),
                            Color(0xFF06B6D4),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: showImageOptions,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    backgroundImage: selectedImage != null
                                        ? FileImage(selectedImage!)
                                            as ImageProvider
                                        : (imageUrl != null &&
                                                imageUrl!.isNotEmpty)
                                            ? NetworkImage(imageUrl!)
                                                as ImageProvider
                                            : null,
                                    child: selectedImage == null &&
                                            (imageUrl == null ||
                                                imageUrl!.isEmpty)
                                        ? const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: cyanDark,
                                          )
                                        : null,
                                  ),
                                  if (isUploadingImage)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 14,
                                        color: cyanDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              email.isNotEmpty ? email : phone,
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CustomerProfileSetup(),
                                  ),
                                );
                                loadUser();
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text("Edit Profile"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        buildMenuItem(
                          Icons.book_online,
                          "My Bookings",
                          const MyBookingScreen(),
                        ),
                        buildMenuItem(
                          Icons.workspace_premium,
                          "Gold Membership",
                          const SubscriptionScreen(),
                        ),
                        buildMenuItem(
                          Icons.card_giftcard,
                          "Rewards",
                          const RewardsScreen(),
                        ),
                        buildMenuItem(
                          Icons.people,
                          "Refer & Earn",
                          const ReferEarnScreen(),
                        ),
                        buildMenuItem(
                          Icons.support_agent,
                          "Help & Support",
                          const HelpSupportScreen(),
                        ),
                        buildMenuItem(
                          Icons.security,
                          "Safety",
                          const SafetyScreen(),
                        ),
                        buildMenuItem(
                          Icons.settings,
                          "Settings",
                          SettingsScreen(), // ✅ const removed
                        ),
                        buildMenuItem(
                          Icons.info,
                          "About",
                          const AboutAjoomiScreen(),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: logout,
                            icon: const Icon(Icons.logout),
                            label: const Text("Logout"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ---------------- MENU ITEM ----------------
  Widget buildMenuItem(
    IconData icon,
    String title,
    Widget screen,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cyanLight,
          child: Icon(
            icon,
            color: cyanDark,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => screen,
            ),
          );
        },
      ),
    );
  }
}
