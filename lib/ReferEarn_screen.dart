import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────
//  CYAN THEME
// ─────────────────────────────────────────────
const _kDark = Color(0xFF083344);
const _kCyan = Color(0xFF06B6D4);
const _kLightCyan = Color(0xFFECFEFF);
const _kBg = Color(0xFFF4FCFD);

const _kReferralCode = 'AJOOMI50';
const _kAppLink = 'https://yourapp.link/ajoomi';
const _kRewardAmount = 50;
const _kFriendReward = 25;

// ─────────────────────────────────────────────
//  REFER & EARN SCREEN
// ─────────────────────────────────────────────
class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  int _totalReferred = 0;
  double _totalEarned = 0;
  int _pendingRewards = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _fadeCtrl.forward();

    _loadReferralStats();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  LOAD STATS
  // ─────────────────────────────────────────────
  Future<void> _loadReferralStats() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) return;

      final snap = await FirebaseFirestore.instance
          .collection('referrals')
          .where('referrerId', isEqualTo: uid)
          .get();

      int pending = 0;
      double earned = 0;

      for (final doc in snap.docs) {
        final data = doc.data();

        if (data['status'] == 'completed') {
          earned += (data['reward'] ?? _kRewardAmount).toDouble();
        } else if (data['status'] == 'pending') {
          pending++;
        }
      }

      if (!mounted) return;

      setState(() {
        _totalReferred = snap.docs.length;
        _totalEarned = earned;
        _pendingRewards = pending;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Referral stats error: $e');

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─────────────────────────────────────────────
  //  SHARE
  // ─────────────────────────────────────────────
  void _shareApp() {
    final text = '🔥 Join Ajoomi – Book home services instantly!\n\n'
        'Use my referral code *$_kReferralCode* and get '
        '₹$_kFriendReward off your first booking.\n\n'
        'Download now 👉 $_kAppLink';

    Share.share(
      text,
      subject: 'Join Ajoomi & Save ₹$_kFriendReward',
    );
  }

  void _shareWhatsApp() {
    final text = '🔥 Join Ajoomi – Book home services instantly!\n\n'
        'Use my referral code *$_kReferralCode* and get '
        '₹$_kFriendReward off your first booking.\n\n'
        'Download now 👉 $_kAppLink';

    Share.share(text);
  }

  void _copyCode() {
    Clipboard.setData(
      const ClipboardData(text: _kReferralCode),
    );

    HapticFeedback.lightImpact();

    _showSnack('Referral code copied 📋');
  }

  void _showSnack(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _kDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: _kCyan,
                onRefresh: _loadReferralStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    children: [
                      _buildHeroBanner(),
                      const SizedBox(height: 14),
                      _buildStatsRow(),
                      const SizedBox(height: 12),
                      _buildCodeCard(),
                      const SizedBox(height: 12),
                      _buildHowItWorks(),
                      const SizedBox(height: 12),
                      _buildTermsBanner(),
                      const SizedBox(height: 20),
                      _buildShareButton(),
                      const SizedBox(height: 10),
                      _buildWhatsAppButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        bottom: 14,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // LOGO
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _kCyan.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                "A",
                style: TextStyle(
                  color: _kCyan,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          const Text(
            'Refer & Earn',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HERO
  // ─────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF083344),
            Color(0xFF0891B2),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              size: 38,
              color: _kCyan,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Refer Friends & Earn',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Invite friends to Ajoomi & earn ₹50 for\n'
            'every friend who completes their first booking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: _kCyan,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.currency_rupee_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'You earn ₹50 per referral',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
  //  STATS
  // ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: _kCyan),
        ),
      );
    }

    return Row(
      children: [
        _StatCard(
          value: '$_totalReferred',
          label: 'Referred',
        ),
        const SizedBox(width: 8),
        _StatCard(
          value: '₹${_totalEarned.toStringAsFixed(0)}',
          label: 'Earned',
        ),
        const SizedBox(width: 8),
        _StatCard(
          value: '$_pendingRewards',
          label: 'Pending',
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  REFERRAL CODE
  // ─────────────────────────────────────────────
  Widget _buildCodeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFCFFAFE),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR REFERRAL CODE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _kLightCyan,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _kCyan,
                      width: 1.5,
                    ),
                  ),
                  child: const Text(
                    _kReferralCode,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _kDark,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _copyCode,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Tap the copy icon to copy your referral code',
            style: TextStyle(
              fontSize: 11,
              color: _kCyan,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HOW IT WORKS
  // ─────────────────────────────────────────────
  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 14),
          _buildStep(
            "1",
            "Share your code",
            "Send your referral code to friends.",
            false,
          ),
          _buildStep(
            "2",
            "Friend signs up",
            "They register using your referral code.",
            false,
          ),
          _buildStep(
            "3",
            "Earn rewards 🎉",
            "You get ₹50 and your friend gets ₹25 discount.",
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    String number,
    String title,
    String subtitle,
    bool isLast,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: _kDark,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: 4,
              bottom: isLast ? 0 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  TERMS
  // ─────────────────────────────────────────────
  Widget _buildTermsBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kLightCyan,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB6F0FE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _kCyan,
            size: 15,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rewards credited after friend completes first booking.',
              style: TextStyle(
                fontSize: 11,
                color: _kDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SHARE BUTTONS
  // ─────────────────────────────────────────────
  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _shareApp,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.share_rounded, size: 20),
        label: const Text(
          'Invite Friends & Earn ₹50',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _shareWhatsApp,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kCyan,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.chat_rounded, size: 18),
        label: const Text(
          'Share on WhatsApp',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STAT CARD
// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
