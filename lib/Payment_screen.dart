import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

// ─────────────────────────────────────────────
// 🎨 CYAN THEME
// ─────────────────────────────────────────────
class _G {
  static const bg = Color(0xFFF4FCFD);
  static const white = Colors.white;

  static const cyan1 = Color(0xFF06B6D4);
  static const cyan2 = Color(0xFF0891B2);
  static const cyanBg = Color(0xFFECFEFF);
  static const cyanText = Color(0xFF0E7490);

  static const dark = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFD9F3F7);
  static const red = Color(0xFFDC2626);
}

// ─────────────────────────────────────────────
// 💳 PAYMENTS SCREEN
// ─────────────────────────────────────────────
class PaymentsScreen extends StatefulWidget {
  final double amount;
  final String serviceName;

  const PaymentsScreen({
    super.key,
    required this.amount,
    required this.serviceName,
  });

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late final Razorpay _razorpay;

  bool _isProcessing = false;
  String _userPhone = '';
  String _userEmail = '';

  static const _merchantName = 'Ajoomi';

  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);
    _loadUserInfo();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // 👤 LOAD USER INFO
  // ─────────────────────────────────────────────
  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _userPhone = user.phoneNumber ?? '';
      _userEmail = user.email ?? '';

      if (_userPhone.isEmpty || _userEmail.isEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data() ?? {};
        if (_userPhone.isEmpty) _userPhone = data['phone'] ?? '';
        if (_userEmail.isEmpty) _userEmail = data['email'] ?? '';
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Load user info error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // 💳 RAZORPAY CHECKOUT
  // ─────────────────────────────────────────────
  void _openCheckout() {
    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    final options = {
      'key': 'rzp_test_SZK7rl7uxB88NP',
      'amount': (widget.amount * 100).round(),
      'currency': 'INR',
      'name': _merchantName,
      'description': widget.serviceName,
      'prefill': {'contact': _userPhone, 'email': _userEmail},
      'theme': {'color': '#06B6D4'},
      'retry': {'enabled': true, 'max_count': 2},
      'notes': {'service': widget.serviceName},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
      setState(() => _isProcessing = false);
      _snack('Unable to open payment gateway', isError: true);
    }
  }

  // ─────────────────────────────────────────────
  // ✅ RAZORPAY SUCCESS
  // ─────────────────────────────────────────────
  void _onSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    HapticFeedback.heavyImpact();
    _savePaymentRecord(response.paymentId ?? '', response.orderId ?? '');
    _showSuccessSheet(response.paymentId ?? 'N/A');
  }

  Future<void> _savePaymentRecord(String paymentId, String orderId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('payments').add({
        'userId': uid,
        'paymentId': paymentId,
        'orderId': orderId,
        'amount': widget.amount,
        'service': widget.serviceName,
        'status': 'success',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Save Payment Error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // ❌ RAZORPAY ERROR
  // ─────────────────────────────────────────────
  void _onError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _snack('Payment failed. Please try again.', isError: true);
  }

  // ─────────────────────────────────────────────
  // 👛 EXTERNAL WALLET
  // ─────────────────────────────────────────────
  void _onWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _snack('Opening ${response.walletName}');
  }

  // ─────────────────────────────────────────────
  // 🎉 SUCCESS SHEET
  // ─────────────────────────────────────────────
  void _showSuccessSheet(String paymentId) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: _G.cyanBg,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: _G.cyan1,
                    size: 55,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _G.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${widget.amount.toStringAsFixed(0)} paid successfully',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _G.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _G.cyanBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Payment ID: $paymentId',
                  style: const TextStyle(
                    color: _G.cyanText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_G.cyan1, _G.cyan2],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _G.cyan1.withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // 🔔 SNACKBAR
  // ─────────────────────────────────────────────
  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? _G.red : _G.cyan2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🏗️ BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _G.bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 18),
                      _buildOrderCard(),
                      const SizedBox(height: 16),
                      _buildUserInfo(),
                      const SizedBox(height: 16),
                      _buildSecurityNote(),
                      const SizedBox(height: 24),
                      _buildPayButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🖼️ LOGO
  // ─────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 95,
          height: 95,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_G.cyan1, _G.cyan2]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _G.cyan1.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.payments_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'DonIn10 Payments',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _G.dark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Fast • Secure • Trusted',
          style: TextStyle(color: _G.muted, fontSize: 13),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // 🔝 HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _G.white,
        border: Border(bottom: BorderSide(color: _G.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _G.cyanBg,
                shape: BoxShape.circle,
                border: Border.all(color: _G.cyan1.withOpacity(0.25)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _G.cyan2,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: TextStyle(
                    color: _G.dark,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Powered by Razorpay',
                  style: TextStyle(color: _G.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _G.cyanBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: _G.cyan2, size: 14),
                SizedBox(width: 4),
                Text(
                  'SSL',
                  style: TextStyle(
                    color: _G.cyanText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🧾 ORDER CARD
  // ─────────────────────────────────────────────
  Widget _buildOrderCard() {
    final serviceCharge = widget.amount - 49;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _G.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _G.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _G.cyanBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.serviceName,
              style: const TextStyle(
                color: _G.cyanText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '₹',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _G.dark,
                ),
              ),
              Text(
                widget.amount.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: _G.dark,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Total amount payable',
            style: TextStyle(color: _G.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          _billRow('Service charge', '₹${serviceCharge.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _billRow('Platform fee', '₹49'),
          Divider(height: 24, color: Colors.grey.shade200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: _G.dark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_G.cyan1, _G.cyan2]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '₹${widget.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _G.muted, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(
            color: _G.dark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // 👤 USER INFO
  // ─────────────────────────────────────────────
  Widget _buildUserInfo() {
    if (_userPhone.isEmpty && _userEmail.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _G.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _G.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Information',
            style: TextStyle(
              color: _G.dark,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          if (_userPhone.isNotEmpty) _infoTile(Icons.phone_rounded, _userPhone),
          if (_userEmail.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoTile(Icons.email_rounded, _userEmail),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _G.cyan2, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _G.muted, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // 🔒 SECURITY NOTE
  // ─────────────────────────────────────────────
  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _G.cyanBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: _G.cyan2, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your payment is protected with 256-bit SSL encryption. Payments are processed securely via Razorpay.',
              style: TextStyle(color: _G.cyanText, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🚀 RAZORPAY PAY BUTTON
  // ─────────────────────────────────────────────
  Widget _buildPayButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _openCheckout,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_G.cyan1, _G.cyan2]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _G.cyan1.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isProcessing
              ? const SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Pay ₹${widget.amount.toStringAsFixed(0)} via Razorpay',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}
