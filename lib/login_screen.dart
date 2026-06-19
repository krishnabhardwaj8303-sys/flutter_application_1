import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';
import 'customer_profile_setup.dart';
import 'otp_screen.dart';
import 'main.dart';

class _K {
  static const cyan = Color(0xFF06B6D4);
  static const cyan2 = Color(0xFF0E7490);
  static const dark = Color(0xFF031B22);
  static const dark2 = Color(0xFF052A33);
  static const muted = Color(0xFF7DD3E8);
  static const red = Color(0xFFEF4444);
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const _LoginPage();
}

class _LoginPage extends StatefulWidget {
  const _LoginPage();
  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  bool _isSignUp = false;
  bool _obscure = true;
  bool _busy = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(_fadeAnim);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool err = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: err ? _K.red : _K.cyan2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _waitForAuthToken(User user) async {
    await user.getIdToken(true);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _goHome(User user) async {
    await _waitForAuthToken(user);
    Map<String, dynamic>? data;
    try {
      data = await UserService().getUser(user.uid);
    } catch (e) {
      debugPrint('getUser error: $e');
    }
    if (!mounted) return;
    final needsSetup =
        data == null || (data['name'] ?? '').toString().trim().isEmpty;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => needsSetup
            ? const CustomerProfileSetup()
            : const CustomerBottomNav(),
      ),
      (_) => false,
    );
  }

  Future<void> _emailAuth() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _snack('Enter your email and password.');
      return;
    }
    setState(() => _busy = true);
    try {
      UserCredential cred;
      if (_isSignUp) {
        cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: pass);
        await _waitForAuthToken(cred.user!);
        await UserService()
            .createUser(uid: cred.user!.uid, phone: '', role: 'customer');
      } else {
        cred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: pass);
      }
      await _goHome(cred.user!);
    } on FirebaseAuthException catch (e) {
      _snack(_mapError(e.code));
    } catch (e) {
      debugPrint('emailAuth error: $e');
      _snack('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showForgotPassword() {
    final resetEmailCtrl = TextEditingController();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _K.cyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset_rounded,
                        color: _K.cyan, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reset Password',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A))),
                      Text("We'll send a reset link to your email",
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ]),
                const SizedBox(height: 24),
                const Text('Email address',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF334155))),
                const SizedBox(height: 8),
                TextField(
                  controller: resetEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: _K.cyan, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF7F9FA),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _K.cyan, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: sending
                        ? null
                        : () async {
                            final email = resetEmailCtrl.text.trim();
                            if (email.isEmpty) {
                              _snack('Please enter your email.');
                              return;
                            }
                            setSheetState(() => sending = true);
                            try {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: email);
                              if (ctx.mounted) Navigator.pop(ctx);
                              _snack('Reset link sent! Check your inbox.',
                                  err: false);
                            } on FirebaseAuthException catch (e) {
                              setSheetState(() => sending = false);
                              _snack(e.code == 'user-not-found'
                                  ? 'No account found with this email.'
                                  : e.code == 'invalid-email'
                                      ? 'Please enter a valid email.'
                                      : 'Failed to send reset email.');
                            } catch (e) {
                              setSheetState(() => sending = false);
                              _snack('Error: ${e.toString()}');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _K.cyan,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Send Reset Link',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      _snack('Enter a valid 10-digit phone number.');
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential cred) async {
          final result = await FirebaseAuth.instance.signInWithCredential(cred);
          final user = result.user;
          if (user != null && mounted) await _goHome(user);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) _snack(e.message ?? 'Verification failed.');
        },
        codeSent: (String verificationId, int? _) {
          if (!mounted) return;
          setState(() => _busy = false);
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpScreen(
                    role: 'customer',
                    verificationId: verificationId,
                    phoneNumber: '+91$phone'),
              ));
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      debugPrint('sendOtp error: $e');
      if (mounted) _snack('Failed to send OTP. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _busy = true);
    try {
      // ✅ FIX: Force fresh sign-in every time
      final gs = GoogleSignIn(scopes: ['email']);
      await gs.signOut();

      final googleUser = await gs.signIn();
      if (googleUser == null) {
        // User cancelled
        setState(() => _busy = false);
        return;
      }

      // ✅ FIX: Get auth tokens with proper error
      final GoogleSignInAuthentication auth;
      try {
        auth = await googleUser.authentication;
      } catch (e) {
        _snack('Google auth failed: ${e.toString()}');
        setState(() => _busy = false);
        return;
      }

      // ✅ FIX: Check token exists
      if (auth.idToken == null) {
        _snack('Missing ID token. Please try again.');
        setState(() => _busy = false);
        return;
      }

      // ✅ Sign in to Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user!;
      await _waitForAuthToken(user);

      // ✅ FIX: Save user to Firestore with proper error handling
      try {
        final exists = await UserService().userExists(user.uid);
        if (!exists) {
          await UserService().createUser(
            uid: user.uid,
            phone: '',
            role: 'customer',
            name: user.displayName ?? '',
            email: user.email ?? '',
            photoUrl: user.photoURL ?? '',
          );
        }
      } catch (e) {
        // ✅ Show exact Firestore save error
        debugPrint('Firestore save error: $e');
        _snack('Data save failed: ${e.toString()}');
        setState(() => _busy = false);
        return;
      }

      if (mounted) await _goHome(user);
    } on FirebaseAuthException catch (e) {
      debugPrint('googleSignIn FirebaseAuthException: ${e.code}');
      switch (e.code) {
        case 'account-exists-with-different-credential':
          _snack('Account exists with a different sign-in method.');
          break;
        case 'network-request-failed':
          _snack('No internet connection.');
          break;
        case 'sign_in_failed':
          _snack(
              'Google Sign-In failed. Check SHA1 is added in Firebase Console.');
          break;
        default:
          _snack('Auth error: ${e.code} - ${e.message}');
      }
    } catch (e) {
      debugPrint('googleSignIn error: $e');
      // ✅ FIX: Show real error instead of generic message
      if (mounted) _snack('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Wrong password. Try again.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'Account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong. Try again.';
    }
  }

  void _switchTab(int t) {
    if (_tab == t) return;
    setState(() => _tab = t);
    _fadeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _K.dark,
        body: Stack(children: [
          Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_K.dark, _K.dark2, Color(0xFF073B47)],
            stops: [0.0, 0.45, 1.0],
          ))),
          Positioned(
              top: -80,
              right: -80,
              child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _K.cyan.withOpacity(0.08)))),
          Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _K.cyan.withOpacity(0.06)))),
          SafeArea(
              child: Column(
                  children: [_buildHeader(), Expanded(child: _buildSheet())])),
          if (_busy)
            Container(
                color: Colors.black38,
                child: const Center(
                    child: CircularProgressIndicator(color: _K.cyan))),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
      child: Column(children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
                colors: [_K.cyan, _K.cyan2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            boxShadow: [
              BoxShadow(
                  color: _K.cyan.withOpacity(0.40),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
            ],
          ),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.asset('assets/logooo.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.home_repair_service_rounded,
                      color: Colors.white,
                      size: 40))),
        ),
        const SizedBox(height: 16),
        const Text('Ajoomi',
            style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text('Trusted local services at your doorstep',
            style: TextStyle(
                color: _K.muted, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildSheet() {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
              child: Text(_isSignUp ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A)))),
          const SizedBox(height: 24),
          _buildTabs(),
          const SizedBox(height: 24),
          FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                  position: _slideAnim,
                  child: _tab == 0 ? _emailForm() : _phoneForm())),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or continue with',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12))),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ]),
          const SizedBox(height: 20),
          _googleBtn(),
          const SizedBox(height: 28),
          if (_tab == 0) _toggleRow(),
        ]),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [_tabBtn('Email', 0), _tabBtn('Phone', 1)]),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final active = _tab == idx;
    return Expanded(
        child: GestureDetector(
            onTap: () => _switchTab(idx),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: active ? _K.cyan : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: _K.cyan.withOpacity(0.30), blurRadius: 8)
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(label,
                    style: TextStyle(
                        color: active ? Colors.white : Colors.grey.shade500,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)))));
  }

  Widget _emailForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Email address'),
      const SizedBox(height: 8),
      _input(
          controller: _emailCtrl,
          hint: 'you@example.com',
          icon: Icons.email_outlined,
          keyboard: TextInputType.emailAddress),
      const SizedBox(height: 16),
      _label('Password'),
      const SizedBox(height: 8),
      TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          decoration: _deco(hint: 'Min 6 characters', icon: Icons.lock_outline)
              .copyWith(
                  suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey.shade400,
                          size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure)))),
      const SizedBox(height: 10),
      if (!_isSignUp)
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _showForgotPassword,
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                color: _K.cyan,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      const SizedBox(height: 16),
      _cta(label: _isSignUp ? 'Create Account' : 'Login', onTap: _emailAuth),
    ]);
  }

  Widget _phoneForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Phone number'),
      const SizedBox(height: 8),
      Row(children: [
        Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFF7F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            alignment: Alignment.center,
            child: const Text('+91',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
        const SizedBox(width: 10),
        Expanded(
            child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    _deco(hint: '9876543210', icon: Icons.phone_outlined)
                        .copyWith(counterText: ''))),
      ]),
      const SizedBox(height: 22),
      _cta(label: 'Send OTP', onTap: _sendOtp),
      const SizedBox(height: 14),
      Center(
          child: Text("We'll send a 6-digit OTP to your number",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
    ]);
  }

  Widget _googleBtn() {
    return GestureDetector(
        onTap: _googleSignIn,
        child: Container(
            height: 52,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('assets/google.webp',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => const Text('G',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4285F4)))),
              const SizedBox(width: 10),
              const Text('Continue with Google',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1E293B))),
            ])));
  }

  Widget _toggleRow() {
    return Center(
        child: RichText(
            text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                children: [
          TextSpan(
              text: _isSignUp
                  ? "Already have an account? "
                  : "Don't have an account? "),
          TextSpan(
              text: _isSignUp ? 'Sign In' : 'Sign Up',
              style:
                  const TextStyle(color: _K.cyan, fontWeight: FontWeight.w700),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _emailCtrl.clear();
                    _passCtrl.clear();
                  });
                  _fadeCtrl.forward(from: 0);
                }),
        ])));
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)));

  Widget _input(
          {required TextEditingController controller,
          required String hint,
          required IconData icon,
          TextInputType keyboard = TextInputType.text}) =>
      TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: _deco(hint: hint, icon: icon));

  InputDecoration _deco({required String hint, required IconData icon}) =>
      InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: _K.cyan, size: 20),
          filled: true,
          fillColor: const Color(0xFFF7F9FA),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _K.cyan, width: 1.5)));

  Widget _cta({required String label, required VoidCallback onTap}) => SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
          onPressed: _busy ? null : onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: _K.cyan,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.3))));
}
