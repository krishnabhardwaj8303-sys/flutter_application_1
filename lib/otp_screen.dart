import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'user_service.dart';
import 'main.dart'; // ✅ CustomerBottomNav
import 'customer_profile_setup.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String role;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.role,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool isLoading = false;
  static const Color cyanDark = Color(0xFF0891B2);

  Future<void> verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      _snack('Enter valid 6-digit OTP');
      return;
    }

    setState(() => isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );
      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = result.user!.uid;

      // ✅ Create user doc if first time
      final exists = await UserService().userExists(uid);
      if (!exists) {
        await UserService().createUser(
          uid: uid,
          phone: widget.phoneNumber,
          role: 'customer',
          name: '',
          email: '',
          photoUrl: '',
        );
      }

      if (!mounted) return;

      final data = await UserService().getUser(uid);
      final needsSetup =
          data == null || (data['name'] ?? '').toString().trim().isEmpty;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => needsSetup
              ? const CustomerProfileSetup()
              : const CustomerBottomNav(), // ✅ real nav
        ),
        (_) => false,
      );
    } catch (_) {
      _snack('Invalid OTP. Try again.');
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: cyanDark),
            const SizedBox(height: 20),
            Text(
              'OTP sent to +91 ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit OTP',
                counterText: '',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyOtp,
                style: ElevatedButton.styleFrom(backgroundColor: cyanDark),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify OTP',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
