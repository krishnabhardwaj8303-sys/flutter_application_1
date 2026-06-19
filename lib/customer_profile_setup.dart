import 'dart:convert';
import 'dart:io';

import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'user_service.dart';

// ─────────────────────────────────────────────
// CLOUDINARY CONFIG
// ─────────────────────────────────────────────
const _kCloudName = 'doeswlkl3';
const _kUploadPreset = 'worker_upload';

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
const _kCyan = Color(0xFF00BCD4);
const _kCyanDark = Color(0xFF00838F);
const _kCyanLight = Color(0xFFE0F7FA);
const _kBg = Color(0xFFF0FAFB);

// ─────────────────────────────────────────────
// PROFILE SCREEN
// ─────────────────────────────────────────────
class CustomerProfileSetup extends StatefulWidget {
  const CustomerProfileSetup({super.key});

  @override
  State<CustomerProfileSetup> createState() => _CustomerProfileSetupState();
}

class _CustomerProfileSetupState extends State<CustomerProfileSetup> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _picker = ImagePicker();

  File? _profileImage;
  String? _existingImageUrl; // from Firebase photoURL
  String? _gender;

  bool _isLoading = false;
  double _uploadProgress = 0;
  String _progressLabel = '';

  // ─── max retries for Firestore writes ───────
  static const _kMaxRetries = 3;

  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _prefillFromAuth();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // PREFILL FROM FIREBASE AUTH + FIRESTORE
  // ─────────────────────────────────────────────
  Future<void> _prefillFromAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Auth fields
    if (user.displayName?.isNotEmpty == true)
      _nameCtrl.text = user.displayName!;
    if (user.email?.isNotEmpty == true) _emailCtrl.text = user.email!;
    if (user.phoneNumber?.isNotEmpty == true) {
      _phoneCtrl.text = user.phoneNumber!.replaceAll('+91', '').trim();
    }
    _existingImageUrl = user.photoURL; // carry existing photo

    // Merge any already-saved Firestore data (e.g. partial save)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final d = doc.data()!;
        if (_nameCtrl.text.isEmpty && (d['name'] ?? '').isNotEmpty)
          _nameCtrl.text = d['name'];
        if (_emailCtrl.text.isEmpty && (d['email'] ?? '').isNotEmpty)
          _emailCtrl.text = d['email'];
        if (_phoneCtrl.text.isEmpty && (d['phone'] ?? '').isNotEmpty)
          _phoneCtrl.text = d['phone'];
        if (_addressCtrl.text.isEmpty && (d['address'] ?? '').isNotEmpty)
          _addressCtrl.text = d['address'];
        if (d['gender'] != null && (d['gender'] as String).isNotEmpty) {
          setState(() => _gender = d['gender'] as String);
        }
        if (_existingImageUrl == null && (d['imageUrl'] ?? '').isNotEmpty) {
          _existingImageUrl = d['imageUrl'] as String;
        }
      }
    } catch (e) {
      debugPrint('Prefill Firestore error (non-fatal): $e');
    }

    if (mounted) setState(() {});
  }

  // ─────────────────────────────────────────────
  // PICK IMAGE — gallery or camera
  // ─────────────────────────────────────────────
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_rounded, color: _kCyanDark),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _kCyanDark),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (file != null && mounted)
        setState(() => _profileImage = File(file.path));
    } on PlatformException catch (e) {
      _showSnack('Camera/gallery permission denied: ${e.message}', true);
    } catch (e) {
      _showSnack('Image selection failed', true);
    }
  }

  // ─────────────────────────────────────────────
  // CLOUDINARY UPLOAD — with timeout
  // ─────────────────────────────────────────────
  Future<String> _uploadToCloudinary() async {
    if (_profileImage == null) return _existingImageUrl ?? '';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_kCloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _kUploadPreset
      ..fields['folder'] = 'customer_profiles'
      ..files
          .add(await http.MultipartFile.fromPath('file', _profileImage!.path));

    // FIX: hard timeout so it never hangs forever
    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () =>
              throw Exception('Image upload timed out. Check your connection.'),
        );

    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      debugPrint('Cloudinary error: $responseBody');
      throw Exception('Image upload failed (${streamedResponse.statusCode})');
    }

    final data = jsonDecode(responseBody);
    return (data['secure_url'] as String?) ?? _existingImageUrl ?? '';
  }

  // ─────────────────────────────────────────────
  // ENSURE AUTH TOKEN — reliable approach
  // ─────────────────────────────────────────────
  Future<String> _getFreshToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    // getIdToken(true) force-refreshes; returns the token directly
    final token = await user.getIdToken(true);
    return token ?? '';
  }

  // ─────────────────────────────────────────────
  // FIRESTORE WRITE — with retry
  // ─────────────────────────────────────────────
  Future<void> _writeWithRetry(
    Future<void> Function() operation, {
    int maxRetries = _kMaxRetries,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        await operation().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Firestore write timed out'),
        );
        return; // success
      } catch (e) {
        attempt++;
        debugPrint('Firestore write attempt $attempt failed: $e');
        if (attempt >= maxRetries) rethrow;
        // exponential back-off: 500ms, 1000ms, 2000ms …
        await Future.delayed(Duration(milliseconds: 500 * attempt));
        // refresh token before retry
        await _getFreshToken();
      }
    }
  }

  // ─────────────────────────────────────────────
  // SAVE PROFILE
  // ─────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
      _progressLabel = 'Preparing…';
    });

    try {
      // Step 1 — Refresh auth token
      _setProgress(0.05, 'Authenticating…');
      await _getFreshToken();

      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;

      // Step 2 — Upload image (if new one selected)
      _setProgress(0.15, 'Uploading photo…');
      String imageUrl = _existingImageUrl ?? '';
      if (_profileImage != null) {
        imageUrl = await _uploadToCloudinary();
        _setProgress(0.50, 'Photo uploaded!');
      } else {
        _setProgress(0.50, 'Skipping photo…');
      }

      // Step 3 — Write main profile doc (merge:true so existing fields survive)
      _setProgress(0.60, 'Saving profile…');
      final profileData = {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        if (_gender != null && _gender!.isNotEmpty) 'gender': _gender,
        'imageUrl': imageUrl,
        'role': 'customer',
        'profileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _writeWithRetry(
          () => UserService().updateProfile(uid, profileData));

      // Step 4 — Write stats subcollection (set with merge so existing data is kept)
      _setProgress(0.85, 'Finishing up…');
      await _writeWithRetry(() async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('stats')
            .doc('summary')
            .set(
          {'totalBookings': 0, 'totalSpent': 0},
          SetOptions(merge: true), // FIX: don't wipe existing stats
        );
      });

      _setProgress(1.0, 'Done!');
      _showSnack('Profile saved successfully!', false);

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerBottomNav()),
        (_) => false,
      );
    } catch (e) {
      debugPrint('saveProfile error: $e');
      // FIX: always reset progress on error
      if (mounted) {
        setState(() {
          _uploadProgress = 0;
          _progressLabel = '';
        });
        _showSnack(_friendlyError(e.toString()), true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setProgress(double value, String label) {
    if (mounted)
      setState(() {
        _uploadProgress = value;
        _progressLabel = label;
      });
  }

  // Convert raw exceptions to user-friendly messages
  String _friendlyError(String raw) {
    if (raw.contains('timed out'))
      return 'Connection timed out. Please check your internet and try again.';
    if (raw.contains('permission-denied'))
      return 'Permission denied. Please log out and log in again.';
    if (raw.contains('network'))
      return 'Network error. Please check your connection.';
    if (raw.contains('upload failed'))
      return 'Photo upload failed. Try a smaller image or skip the photo.';
    return 'Something went wrong. Please try again.';
  }

  // ─────────────────────────────────────────────
  // SKIP
  // ─────────────────────────────────────────────
  void _skip() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerBottomNav()),
      (_) => false,
    );
  }

  // ─────────────────────────────────────────────
  // SNACK
  // ─────────────────────────────────────────────
  void _showSnack(String msg, bool error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: error ? Colors.red.shade600 : _kCyanDark,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: error ? 4 : 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCyanDark,
        foregroundColor: Colors.white,
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _skip,
            child: const Text('Skip',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Profile Image ─────────────────────────────
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: _kCyanLight,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!) as ImageProvider
                          : (_existingImageUrl != null &&
                                  _existingImageUrl!.isNotEmpty)
                              ? NetworkImage(_existingImageUrl!)
                              : null,
                      child: (_profileImage == null &&
                              (_existingImageUrl == null ||
                                  _existingImageUrl!.isEmpty))
                          ? const Icon(Icons.camera_alt,
                              size: 35, color: _kCyanDark)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: _kCyan, shape: BoxShape.circle),
                        child: const Icon(Icons.edit,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('Tap to add profile photo',
                  style: TextStyle(color: _kCyanDark, fontSize: 12)),
              const SizedBox(height: 25),

              // ── Name ─────────────────────────────────────
              _buildField(
                controller: _nameCtrl,
                label: 'Full Name *',
                icon: Icons.person,
                required: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]")),
                ],
              ),
              const SizedBox(height: 15),

              // ── Email ─────────────────────────────────────
              _buildField(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.email,
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
                  if (!emailRegex.hasMatch(v.trim()))
                    return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // ── Phone ─────────────────────────────────────
              _buildField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboard: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  if (v.trim().length != 10)
                    return 'Enter a valid 10-digit phone number';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // ── Address ───────────────────────────────────
              _buildField(
                controller: _addressCtrl,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // ── Gender Dropdown ───────────────────────────
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.people, color: _kCyanDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kCyan, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged:
                    _isLoading ? null : (v) => setState(() => _gender = v),
              ),

              const SizedBox(height: 30),

              // ── Progress ──────────────────────────────────
              if (_isLoading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 8,
                    color: _kCyan,
                    backgroundColor: _kCyanLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _progressLabel,
                  style: const TextStyle(color: _kCyanDark, fontSize: 13),
                ),
                const SizedBox(height: 10),
              ],

              // ── Save Button ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kCyanDark,
                    disabledBackgroundColor: _kCyanDark.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: _isLoading ? null : _skip,
                child: const Text('Skip for now',
                    style: TextStyle(
                        color: _kCyanDark, fontWeight: FontWeight.w500)),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FIELD BUILDER
  // ─────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool required = false,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      enabled: !_isLoading,
      inputFormatters: inputFormatters,
      validator: validator ??
          (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'Please enter your ${label.replaceAll(' *', '')}';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kCyanDark),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kCyan, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
