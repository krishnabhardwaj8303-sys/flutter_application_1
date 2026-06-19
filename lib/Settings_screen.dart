import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ───────────────── COLORS ─────────────────
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanDark = Color(0xFF0891B2);
  static const Color cyanLight = Color(0xFFECFEFF);
  static const Color bgColor = Color(0xFFF5FCFD);

  // ───────────────── SETTINGS ─────────────────
  bool notificationsEnabled = true;
  bool emailNotifications = false;
  bool smsNotifications = true;
  bool locationEnabled = true;
  bool biometricLogin = false;
  bool darkMode = false;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ───────────────── LOAD SETTINGS ─────────────────
  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snap.data();

      if (data != null && data['settings'] != null) {
        final settings = data['settings'];

        notificationsEnabled = settings['notifications'] ?? true;
        emailNotifications = settings['emailNotifications'] ?? false;
        smsNotifications = settings['smsNotifications'] ?? true;
        locationEnabled = settings['location'] ?? true;
        biometricLogin = settings['biometric'] ?? false;
        darkMode = settings['darkMode'] ?? false;
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // ───────────────── SAVE SETTINGS ─────────────────
  Future<void> _saveSetting(String key, bool value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'settings': {key: value}
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving setting: $e");
    }
  }

  // ───────────────── CHANGE PASSWORD ─────────────────
  Future<void> _changePassword() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      if (user.email == null || user.email!.isEmpty) {
        _showSnack(
          "No email linked with this account.",
          Colors.orange,
        );
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);

      _showSnack(
        "Password reset email sent to ${user.email}",
        cyanDark,
      );
    } catch (e) {
      _showSnack(
        "Failed to send reset email",
        Colors.red,
      );
    }
  }

  // ───────────────── DELETE ACCOUNT ─────────────────
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Delete Account",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "This action will permanently delete your account and all associated data.",
        ),
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
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => isLoading = true);

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      // Delete Firestore data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete Auth account
      await user.delete();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } catch (e) {
      debugPrint("Delete error: $e");

      if (!mounted) return;

      setState(() => isLoading = false);

      _showSnack(
        "Please login again before deleting account.",
        Colors.red,
      );
    }
  }

  // ───────────────── LOGOUT ─────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
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
              backgroundColor: cyanDark,
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
      '/',
      (route) => false,
    );
  }

  // ───────────────── URL LAUNCH ─────────────────
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ───────────────── SNACKBAR ─────────────────
  void _showSnack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
      ),
    );
  }

  // ───────────────── UI ─────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cyanDark,
        foregroundColor: Colors.white,
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: cyan,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ───────────────── NOTIFICATIONS ─────────────────
                _sectionHeader("NOTIFICATIONS"),

                _buildSwitchTile(
                  icon: Icons.notifications_active_rounded,
                  title: "Push Notifications",
                  subtitle: "Receive booking alerts & updates",
                  value: notificationsEnabled,
                  onChanged: (val) {
                    setState(() => notificationsEnabled = val);
                    _saveSetting('notifications', val);
                  },
                ),

                _buildSwitchTile(
                  icon: Icons.email_rounded,
                  title: "Email Notifications",
                  subtitle: "Receive updates via email",
                  value: emailNotifications,
                  onChanged: (val) {
                    setState(() => emailNotifications = val);
                    _saveSetting('emailNotifications', val);
                  },
                ),

                _buildSwitchTile(
                  icon: Icons.sms_rounded,
                  title: "SMS Notifications",
                  subtitle: "Receive SMS alerts",
                  value: smsNotifications,
                  onChanged: (val) {
                    setState(() => smsNotifications = val);
                    _saveSetting('smsNotifications', val);
                  },
                ),

                const SizedBox(height: 18),

                // ───────────────── PRIVACY ─────────────────
                _sectionHeader("PRIVACY & SECURITY"),

                _buildSwitchTile(
                  icon: Icons.location_on_rounded,
                  title: "Location Access",
                  subtitle: "Allow app to access location",
                  value: locationEnabled,
                  onChanged: (val) {
                    setState(() => locationEnabled = val);
                    _saveSetting('location', val);
                  },
                ),

                _buildSwitchTile(
                  icon: Icons.fingerprint_rounded,
                  title: "Biometric Login",
                  subtitle: "Use fingerprint or face unlock",
                  value: biometricLogin,
                  onChanged: (val) {
                    setState(() => biometricLogin = val);
                    _saveSetting('biometric', val);
                  },
                ),

                _buildArrowTile(
                  icon: Icons.lock_reset_rounded,
                  title: "Change Password",
                  subtitle: "Send password reset email",
                  onTap: _changePassword,
                ),

                const SizedBox(height: 18),

                // ───────────────── APP ─────────────────
                _sectionHeader("APP"),

                _buildArrowTile(
                  icon: Icons.language_rounded,
                  title: "Language",
                  subtitle: "English",
                  onTap: () {
                    _showSnack(
                      "Language feature coming soon",
                      cyanDark,
                    );
                  },
                ),

                _buildArrowTile(
                  icon: Icons.privacy_tip_rounded,
                  title: "Privacy Policy",
                  subtitle: "Read privacy policy",
                  onTap: () {
                    _openUrl("https://example.com/privacy");
                  },
                ),

                _buildArrowTile(
                  icon: Icons.description_rounded,
                  title: "Terms & Conditions",
                  subtitle: "Read terms & conditions",
                  onTap: () {
                    _openUrl("https://example.com/terms");
                  },
                ),

                _buildArrowTile(
                  icon: Icons.info_outline_rounded,
                  title: "About App",
                  subtitle: "Ajoomi Worker App",
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: "Ajoomi Worker",
                      applicationVersion: "1.0.0",
                      applicationLegalese: "© 2026 Ajoomi",
                    );
                  },
                ),

                const SizedBox(height: 18),

                // ───────────────── ACCOUNT ─────────────────
                _sectionHeader(
                  "ACCOUNT",
                  color: Colors.red,
                ),

                _buildArrowTile(
                  icon: Icons.logout_rounded,
                  title: "Logout",
                  subtitle: "Sign out from this account",
                  onTap: _logout,
                ),

                _buildArrowTile(
                  icon: Icons.delete_forever_rounded,
                  title: "Delete Account",
                  subtitle: "Permanently delete account",
                  iconColor: Colors.red,
                  titleColor: Colors.red,
                  onTap: _deleteAccount,
                ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }

  // ───────────────── SECTION HEADER ─────────────────
  Widget _sectionHeader(
    String title, {
    Color color = cyanDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ───────────────── SWITCH TILE ─────────────────
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: cyanLight,
          child: Icon(icon, color: cyanDark),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: cyanDark,
        ),
      ),
    );
  }

  // ───────────────── ARROW TILE ─────────────────
  Widget _buildArrowTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = cyanDark,
    Color titleColor = Colors.black87,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor:
              iconColor == Colors.red ? Colors.red.shade50 : cyanLight,
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
        ),
      ),
    );
  }
}
