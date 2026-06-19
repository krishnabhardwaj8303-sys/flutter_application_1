import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Payment_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanDark = Color(0xFF0891B2);
  static const Color cyanLight = Color(0xFFECFEFF);
  static const Color gold = Color(0xFFFFB800);
  static const Color goldDark = Color(0xFFCC8800);
  static const Color goldLight = Color(0xFFFFF8E1);

  bool isGoldMember = false;
  bool isLoading = true;
  DateTime? memberSince;
  DateTime? memberUntil;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();
    _loadMembership();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembership() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      final data = doc.data();
      if (data != null && data['goldMember'] == true) {
        final until = (data['goldUntil'] as Timestamp?)?.toDate();
        if (until != null && until.isAfter(DateTime.now())) {
          setState(() {
            isGoldMember = true;
            memberSince = (data['goldSince'] as Timestamp?)?.toDate();
            memberUntil = until;
          });
        }
      }
    } catch (e) {
      debugPrint("Membership load error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _activateGoldMembership() async {
    // Navigate to payment screen with ₹11 amount
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentsScreen(
          amount: 11,
          serviceName: "Gold Membership – 1 Month",
        ),
      ),
    );

    // After payment success, save membership to Firestore
    if (result == true || result == null) {
      // Treat return as success (adjust based on your PaymentsScreen return value)
      await _saveGoldMembership();
    }
  }

  Future<void> _saveGoldMembership() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final now = DateTime.now();
      final until = DateTime(now.year, now.month + 1, now.day);

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "goldMember": true,
        "goldSince": Timestamp.fromDate(now),
        "goldUntil": Timestamp.fromDate(until),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        isGoldMember = true;
        memberSince = now;
        memberUntil = until;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("🎉 Gold Membership Activated! Enjoy zero platform fees."),
          backgroundColor: Color(0xFFCC8800),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Failed to activate membership. Try again.")),
      );
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return "--";
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FCFD),
      appBar: AppBar(
        backgroundColor: cyanDark,
        foregroundColor: Colors.white,
        title: const Text("Membership & Payments",
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: cyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Gold Card ──
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: _buildGoldCard(),
                  ),

                  const SizedBox(height: 28),

                  // ── Benefits ──
                  const Text("Gold Member Benefits",
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D1B1E))),
                  const SizedBox(height: 14),

                  _benefit(Icons.percent_rounded, "Zero Platform Fees",
                      "No extra charges on any booking for 1 month"),
                  _benefit(Icons.priority_high_rounded, "Priority Booking",
                      "Get workers assigned faster than regular users"),
                  _benefit(Icons.support_agent_rounded, "Priority Support",
                      "Dedicated support queue for Gold members"),
                  _benefit(Icons.local_offer_rounded, "Exclusive Offers",
                      "Access to member-only discounts & deals"),
                  _benefit(Icons.verified_rounded, "Verified Badge",
                      "Show Gold badge on your profile"),

                  const SizedBox(height: 28),

                  // ── CTA / Status ──
                  if (!isGoldMember) _buildSubscribeButton(),
                  if (isGoldMember) _buildActiveStatus(),

                  const SizedBox(height: 20),

                  // ── FAQ ──
                  _buildFAQ(),
                ],
              ),
            ),
    );
  }

  // ─── GOLD CARD ────────────────────────────────────────────────────────────────
  Widget _buildGoldCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text("GOLD MEMBER",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                  ],
                ),
              ),
              const Spacer(),
              if (isGoldMember)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("ACTIVE",
                      style: TextStyle(
                          color: Color(0xFFCC8800),
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Zero Platform Fees",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1)),
          const SizedBox(height: 4),
          const Text("for 1 Full Month",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("₹",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const Text("11",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("/ month",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("One-time",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isGoldMember) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: Colors.white, size: 15),
                  const SizedBox(width: 8),
                  Text(
                    "Valid: ${_formatDate(memberSince)} – ${_formatDate(memberUntil)}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── BENEFIT ITEM ─────────────────────────────────────────────────────────────
  Widget _benefit(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldLight),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: goldLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: goldDark, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0D1B1E))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFFFFB800), size: 20),
        ],
      ),
    );
  }

  // ─── SUBSCRIBE BUTTON ─────────────────────────────────────────────────────────
  Widget _buildSubscribeButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _activateGoldMembership,
        icon: const Icon(Icons.workspace_premium_rounded, size: 22),
        label: const Text("Get Gold Membership – ₹11",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ─── ACTIVE STATUS ────────────────────────────────────────────────────────────
  Widget _buildActiveStatus() {
    final daysLeft = memberUntil?.difference(DateTime.now()).inDays ?? 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: goldLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: goldDark, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Gold Membership Active",
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0D1B1E))),
                const SizedBox(height: 3),
                Text("$daysLeft days remaining",
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          TextButton(
            onPressed: _activateGoldMembership,
            child: const Text("Renew",
                style: TextStyle(color: goldDark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─── FAQ ─────────────────────────────────────────────────────────────────────
  Widget _buildFAQ() {
    final faqs = [
      {
        "q": "What is the Gold Membership?",
        "a":
            "Gold Membership gives you zero platform fees on all bookings for 1 full month, just for ₹11.",
      },
      {
        "q": "When does it start?",
        "a":
            "Your membership starts immediately after payment and lasts 30 days.",
      },
      {
        "q": "Is it auto-renewed?",
        "a":
            "No. It's a one-time payment. You can renew manually before or after it expires.",
      },
      {
        "q": "What are platform fees?",
        "a":
            "Platform fees are small charges added on bookings. With Gold, these are waived completely.",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("FAQs",
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D1B1E))),
        const SizedBox(height: 12),
        ...faqs.map(
          (faq) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
              ],
            ),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              title: Text(faq["q"]!,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF0D1B1E))),
              iconColor: cyanDark,
              collapsedIconColor: Colors.grey,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text(faq["a"]!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
