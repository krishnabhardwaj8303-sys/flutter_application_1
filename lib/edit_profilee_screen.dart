import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'user_service.dart';
import 'services/cloudinary_service.dart';

// ─────────────────────────────────────────────
//  CYAN DESIGN TOKENS
// ─────────────────────────────────────────────
const _kDark = Color(0xFF0D2626);
const _kCyan = Color(0xFF00BCD4);
const _kCyanDark = Color(0xFF00838F);
const _kCyanLight = Color(0xFFE0F7FA);
const _kCyanBg = Color(0xFFB2EBF2);
const _kSurface = Color(0xFFF4FDFD);
const _kBorder = Color(0xFFC8EDEF);
const _kMuted = Color(0xFF5E8080);
const _kWhite = Colors.white;

// ─────────────────────────────────────────────
//  EDIT PROFILE SCREEN
// ─────────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, Map<String, dynamic>? userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ──
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // ── Focus nodes ──
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _expFocus = FocusNode();
  final _addrFocus = FocusNode();

  String _selectedService = 'Plumber';
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  String _imageUrl = '';

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static const _services = [
    {'icon': '🔧', 'label': 'Plumber'},
    {'icon': '⚡', 'label': 'Electrician'},
    {'icon': '🪚', 'label': 'Carpenter'},
    {'icon': '🧹', 'label': 'Cleaning'},
    {'icon': '🖌️', 'label': 'Painter'},
    {'icon': '❄️', 'label': 'AC Repair'},
    {'icon': '📱', 'label': 'Phone Repair'},
    {'icon': '✂️', 'label': 'Salon'},
    {'icon': '👕', 'label': 'Laundry'},
    {'icon': '🧴', 'label': 'Maid'},
  ];

  // ── Lifecycle ──
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadUserData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _expCtrl.dispose();
    _addressCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _expFocus.dispose();
    _addrFocus.dispose();
    super.dispose();
  }

  // ── Load ──
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await UserService().getUser(user.uid);
      if (data != null && mounted) {
        _nameCtrl.text = data['name'] ?? '';
        _emailCtrl.text = data['email'] ?? '';
        _phoneCtrl.text = data['altPhone'] ?? '';
        _expCtrl.text = data['experience'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
        _selectedService = data['skills'] ?? 'Plumber';
        _imageUrl = data['imageUrl'] ?? '';
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeCtrl.forward();
    }
  }

  // ── Image ──
  Future<void> _pickImage(ImageSource source) async {
    final img = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (img != null && mounted) setState(() => _selectedImage = File(img.path));
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                  color: _kBorder, borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Update Photo',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _kDark)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: _imgSourceBtn(Icons.camera_alt_rounded, 'Camera', () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              })),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _imgSourceBtn(Icons.photo_library_rounded, 'Gallery', () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              })),
            ]),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _imgSourceBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Column(children: [
          Icon(icon, color: _kCyan, size: 30),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kMuted)),
        ]),
      ),
    );
  }

  // ── Save ──
  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Name cannot be empty.', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String finalUrl = _imageUrl;
      if (_selectedImage != null) {
        finalUrl =
            await CloudinaryService.uploadImage(_selectedImage!) ?? _imageUrl;
      }

      await UserService().updateProfile(user.uid, {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'altPhone': _phoneCtrl.text.trim(),
        'skills': _selectedService,
        'experience': _expCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'imageUrl': finalUrl,
      });

      _showSnack('Profile updated successfully!');
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _showSnack('Update failed. Please try again.', isError: true);
    }
    if (mounted) setState(() => _isSaving = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.red[700] : _kCyanDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kWhite,
        body: _isLoading
            ? _buildLoader()
            : FadeTransition(
                opacity: _fadeAnim,
                child: Column(children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      physics: const BouncingScrollPhysics(),
                      child: Column(children: [
                        _buildAvatarSection(),
                        const SizedBox(height: 20),
                        _buildSectionLabel(
                            Icons.person_outline_rounded, 'Personal Info'),
                        const SizedBox(height: 10),
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        _buildSectionLabel(
                            Icons.home_repair_service_rounded, 'Your Skill'),
                        const SizedBox(height: 10),
                        _buildSkillCard(),
                        const SizedBox(height: 16),
                        _buildSectionLabel(
                            Icons.location_on_outlined, 'Work Location'),
                        const SizedBox(height: 10),
                        _buildAddressCard(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
                      ]),
                    ),
                  ),
                ]),
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  LOADER
  // ─────────────────────────────────────────────
  Widget _buildLoader() => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: _kCyan, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text('Loading profile...',
              style: TextStyle(color: _kMuted, fontSize: 14)),
        ]),
      );

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _kDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Edit Profile',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 2),
            Text('Update your worker profile',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: _kCyan, borderRadius: BorderRadius.circular(20)),
          child: const Text('WORKER',
              style: TextStyle(
                  color: _kDark,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  AVATAR SECTION
  // ─────────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          // Ring
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kCyan, width: 2.5),
              color: _kCyanLight,
            ),
          ),
          // Avatar
          Positioned(
            top: 4,
            left: 4,
            child: ClipOval(
              child: SizedBox(
                width: 102,
                height: 102,
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : (_imageUrl.isNotEmpty
                        ? Image.network(_imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarFallback())
                        : _avatarFallback()),
              ),
            ),
          ),
          // Camera badge
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageOptions,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _kCyan,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Text(
          _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your Name',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _kDark),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _kCyanLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kCyan),
          ),
          child: Text(_selectedService,
              style: const TextStyle(
                  color: _kCyanDark,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _avatarFallback() => Container(
        color: _kCyanLight,
        child: const Center(
          child: Icon(Icons.person_rounded, size: 48, color: _kCyan),
        ),
      );

  // ─────────────────────────────────────────────
  //  SECTION LABEL
  // ─────────────────────────────────────────────
  Widget _buildSectionLabel(IconData icon, String title) {
    return Row(children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            color: _kCyanLight, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 15, color: _kCyanDark),
      ),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: _kDark)),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1, color: _kBorder)),
    ]);
  }

  // ─────────────────────────────────────────────
  //  INFO CARD
  // ─────────────────────────────────────────────
  Widget _buildInfoCard() {
    return _Card(
      child: Column(children: [
        _InputRow(
          icon: Icons.person_outline_rounded,
          label: 'Full Name',
          controller: _nameCtrl,
          focus: _nameFocus,
          next: _emailFocus,
        ),
        _Divider(),
        _InputRow(
          icon: Icons.email_outlined,
          label: 'Email',
          controller: _emailCtrl,
          focus: _emailFocus,
          next: _phoneFocus,
          keyboard: TextInputType.emailAddress,
        ),
        _Divider(),
        _InputRow(
          icon: Icons.phone_outlined,
          label: 'Alternate Phone',
          controller: _phoneCtrl,
          focus: _phoneFocus,
          next: _expFocus,
          keyboard: TextInputType.phone,
        ),
        _Divider(),
        _InputRow(
          icon: Icons.star_outline_rounded,
          label: 'Years of Experience',
          controller: _expCtrl,
          focus: _expFocus,
          keyboard: TextInputType.number,
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  SKILL CARD
  // ─────────────────────────────────────────────
  Widget _buildSkillCard() {
    return _Card(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _services.map((s) {
          final active = _selectedService == s['label'];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedService = s['label']!);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active ? _kCyanLight : _kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? _kCyan : _kBorder, width: active ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(s['icon']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(s['label']!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? _kCyanDark : _kMuted)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ADDRESS CARD
  // ─────────────────────────────────────────────
  Widget _buildAddressCard() {
    return _Card(
      child: TextField(
        controller: _addressCtrl,
        focusNode: _addrFocus,
        maxLines: 3,
        style: const TextStyle(fontSize: 13, color: _kDark),
        decoration: InputDecoration(
          hintText: 'Enter your work area or full address...',
          hintStyle: const TextStyle(color: _kMuted, fontSize: 13),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(bottom: 44),
            child: Icon(Icons.location_on_outlined, color: _kCyan, size: 20),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 0),
          filled: true,
          fillColor: _kSurface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _kCyan, width: 1.5)),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SAVE BUTTON
  // ─────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kDark,
          disabledBackgroundColor: _kDark.withOpacity(0.45),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(color: _kCyan, strokeWidth: 2.5))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, color: _kCyan, size: 20),
                  SizedBox(width: 8),
                  Text('Save Changes',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: _kBorder,
      );
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.icon,
    required this.label,
    required this.controller,
    required this.focus,
    this.next,
    this.keyboard = TextInputType.text,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final FocusNode focus;
  final FocusNode? next;
  final TextInputType keyboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(icon, color: _kCyan, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focus,
            keyboardType: keyboard,
            textInputAction:
                next != null ? TextInputAction.next : TextInputAction.done,
            onSubmitted: (_) => next != null
                ? FocusScope.of(context).requestFocus(next)
                : FocusScope.of(context).unfocus(),
            style: const TextStyle(
                fontSize: 14, color: _kDark, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: _kMuted, fontSize: 12),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _kCyan, width: 1.5),
              ),
              enabledBorder: InputBorder.none,
            ),
          ),
        ),
      ]),
    );
  }
}
