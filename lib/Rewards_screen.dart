import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// 🎨 THEME — White & Cyan
// ─────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF5F9FC);
  static const white = Color(0xFFFFFFFF);
  static const cyan = Color(0xFF00BCD4);
  static const cyanLight = Color(0xFFE0F7FA);
  static const cyanMid = Color(0xFF4DD0E1);
  static const cyanDark = Color(0xFF0097A7);
  static const text = Color(0xFF1A2332);
  static const textSub = Color(0xFF6B7C93);
  static const textHint = Color(0xFFAABBC8);
  static const border = Color(0xFFDDE8EF);
  static const borderCyan = Color(0xFFB2EBF2);
  static const success = Color(0xFF26C97A);
  static const amber = Color(0xFFFFB300);
  static const purple = Color(0xFF7C4DFF);
  static const red = Color(0xFFFF5252);
}

// ─────────────────────────────────────────────
// 🏆 REWARDS SCREEN
// ─────────────────────────────────────────────
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryAnim;
  late AnimationController _progressAnim;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late Animation<double> _progressValue;

  int totalPoints = 0;
  int completedJobs = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> history = [];

  final List<Map<String, dynamic>> tiers = [
    {
      "name": "Bronze",
      "icon": Icons.military_tech,
      "min": 0,
      "max": 499,
      "color": Color(0xFFBF8A5E)
    },
    {
      "name": "Silver",
      "icon": Icons.military_tech,
      "min": 500,
      "max": 999,
      "color": Color(0xFF9E9E9E)
    },
    {
      "name": "Gold",
      "icon": Icons.military_tech,
      "min": 1000,
      "max": 1999,
      "color": Color(0xFFFFB300)
    },
    {
      "name": "Platinum",
      "icon": Icons.diamond_outlined,
      "min": 2000,
      "max": 4999,
      "color": _C.cyan
    },
    {
      "name": "Diamond",
      "icon": Icons.diamond,
      "min": 5000,
      "max": 99999,
      "color": _C.purple
    },
  ];

  final List<Map<String, dynamic>> catalogue = [
    {
      "icon": Icons.local_offer_outlined,
      "title": "₹50 Off Next Booking",
      "points": 200,
      "color": _C.cyan
    },
    {
      "icon": Icons.handyman_outlined,
      "title": "Free Service Inspection",
      "points": 500,
      "color": _C.amber
    },
    {
      "icon": Icons.bolt_outlined,
      "title": "Priority Worker Match",
      "points": 300,
      "color": _C.purple
    },
    {
      "icon": Icons.discount_outlined,
      "title": "10% Discount Coupon",
      "points": 150,
      "color": Color(0xFF26A69A)
    },
    {
      "icon": Icons.account_balance_wallet_outlined,
      "title": "₹100 Cashback",
      "points": 800,
      "color": _C.red
    },
    {
      "icon": Icons.star_outline_rounded,
      "title": "Premium Member Badge",
      "points": 1000,
      "color": _C.amber
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _entryAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _progressAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _entryFade = CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut));
    _progressValue = Tween<double>(begin: 0, end: 1).animate(_progressAnim);
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    _progressAnim.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => isLoading = false);
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final data = userDoc.data() ?? {};
      totalPoints = (data["rewardPoints"] ?? 0) as int;
      completedJobs = (data["completedJobs"] ?? 0) as int;

      final reqs = await FirebaseFirestore.instance
          .collection("requests")
          .where("userId", isEqualTo: uid)
          .where("status", isEqualTo: "completed")
          .orderBy("createdAt", descending: true)
          .limit(10)
          .get();

      history = reqs.docs.map((d) {
        final rd = d.data();
        return {
          "service": rd["service"] ?? "Service",
          "sub": rd["subCategory"] ?? "",
          "points": 50,
          "date": rd["createdAt"],
        };
      }).toList();
    } catch (e) {
      debugPrint("Rewards load error: $e");
    }
    setState(() => isLoading = false);
    _progressAnim.forward();
  }

  Map<String, dynamic> get _currentTier {
    for (final t in tiers.reversed) {
      if (totalPoints >= (t["min"] as int)) return t;
    }
    return tiers.first;
  }

  Map<String, dynamic> get _nextTier {
    final idx = tiers.indexOf(_currentTier);
    return idx < tiers.length - 1 ? tiers[idx + 1] : tiers.last;
  }

  double get _tierProgress {
    final cur = _currentTier;
    final next = _nextTier;
    if (cur == next) return 1.0;
    final range = (next["min"] as int) - (cur["min"] as int);
    final done = totalPoints - (cur["min"] as int);
    return (done / range).clamp(0.0, 1.0);
  }

  int get _pointsToNext {
    if (_currentTier == _nextTier) return 0;
    return (_nextTier["min"] as int) - totalPoints;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: isLoading ? _buildLoader() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoader() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: _C.cyan, strokeWidth: 2),
          const SizedBox(height: 12),
          Text("Loading rewards...",
              style: TextStyle(color: _C.textSub, fontSize: 13)),
        ]),
      );

  Widget _buildContent() {
    return SlideTransition(
      position: _entrySlide,
      child: FadeTransition(
        opacity: _entryFade,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildPointsCard()),
            SliverToBoxAdapter(child: _buildTierCard()),
            SliverToBoxAdapter(child: _buildStatsRow()),
            SliverToBoxAdapter(child: _buildCatalogueSection()),
            SliverToBoxAdapter(child: _buildHistorySection()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.white,
              border: Border.all(color: _C.border),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: _C.text, size: 15),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("My Rewards",
                style: TextStyle(
                    color: _C.text, fontSize: 19, fontWeight: FontWeight.w700)),
            Text("Earn 50 pts on every booking",
                style: TextStyle(color: _C.textSub, fontSize: 12)),
          ]),
        ),
        GestureDetector(
          onTap: () {
            setState(() => isLoading = true);
            _progressAnim.reset();
            _loadData();
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.cyanLight,
              border: Border.all(color: _C.borderCyan),
            ),
            child: Icon(Icons.refresh_rounded, color: _C.cyanDark, size: 18),
          ),
        ),
      ]),
    );
  }

  // ── Points Card ──
  Widget _buildPointsCard() {
    final tier = _currentTier;
    final tierColor = tier["color"] as Color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.border),
        ),
        child: Column(children: [
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tierColor.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(tier["icon"] as IconData, color: tierColor, size: 15),
              const SizedBox(width: 5),
              Text(tier["name"] as String,
                  style: TextStyle(
                      color: tierColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ]),
          ),
          const SizedBox(height: 18),

          // Points circle
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.cyanLight,
              border: Border.all(color: _C.borderCyan, width: 2),
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.stars_rounded, color: _C.cyan, size: 22),
              const SizedBox(height: 2),
              Text("$totalPoints",
                  style: TextStyle(
                      color: _C.cyanDark,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              Text("pts",
                  style: TextStyle(
                      color: _C.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 16),

          Text("Total Reward Points",
              style: TextStyle(color: _C.textSub, fontSize: 13)),
          const SizedBox(height: 12),

          // Next tier pill
          if (_pointsToNext > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.flag_outlined, color: _C.cyan, size: 14),
                const SizedBox(width: 6),
                Text(
                  "$_pointsToNext pts away from ${_nextTier["name"]}",
                  style: TextStyle(
                      color: _C.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _C.cyanLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.borderCyan),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.emoji_events_outlined, color: _C.cyanDark, size: 14),
                const SizedBox(width: 6),
                Text("Max Tier Reached!",
                    style: TextStyle(
                        color: _C.cyanDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
      ),
    );
  }

  // ── Tier Card ──
  Widget _buildTierCard() {
    final tier = _currentTier;
    final tierColor = tier["color"] as Color;
    final progress = _tierProgress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
        ),
        child: Column(children: [
          // Current → Next row
          Row(children: [
            _tierIcon(tier, true),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier["name"] as String,
                    style: TextStyle(
                        color: tierColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                Text("Current Tier",
                    style: TextStyle(color: _C.textSub, fontSize: 11)),
              ],
            )),
            if (_currentTier != _nextTier) ...[
              Icon(Icons.chevron_right, color: _C.textHint, size: 18),
              const SizedBox(width: 6),
              _tierIcon(_nextTier, false),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_nextTier["name"] as String,
                    style: TextStyle(
                        color: _C.textSub,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text("Next",
                    style: TextStyle(color: _C.textHint, fontSize: 10)),
              ]),
            ],
          ]),
          const SizedBox(height: 16),

          // Progress bar
          AnimatedBuilder(
            animation: _progressValue,
            builder: (_, __) {
              final animated = progress * _progressValue.value;
              return Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: animated,
                    minHeight: 8,
                    backgroundColor: _C.bg,
                    valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${tier["min"]} pts",
                        style: TextStyle(color: _C.textHint, fontSize: 11)),
                    Text("${(progress * 100).toInt()}%",
                        style: TextStyle(
                            color: tierColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    Text(
                        "${_currentTier == _nextTier ? "∞" : _nextTier["min"]} pts",
                        style: TextStyle(color: _C.textHint, fontSize: 11)),
                  ],
                ),
              ]);
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEF3F7)),
          const SizedBox(height: 14),

          // All tiers row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tiers.map((t) {
              final isActive = t["name"] == tier["name"];
              final tc = t["color"] as Color;
              return Column(children: [
                Container(
                  width: isActive ? 38 : 30,
                  height: isActive ? 38 : 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? tc.withOpacity(0.12) : _C.bg,
                    border: Border.all(
                        color: isActive ? tc : _C.border,
                        width: isActive ? 1.5 : 1),
                  ),
                  child: Icon(t["icon"] as IconData,
                      color: isActive ? tc : _C.textHint,
                      size: isActive ? 18 : 14),
                ),
                const SizedBox(height: 4),
                Text(t["name"] as String,
                    style: TextStyle(
                        color: isActive ? tc : _C.textHint,
                        fontSize: 9,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500)),
              ]);
            }).toList(),
          ),
        ]),
      ),
    );
  }

  Widget _tierIcon(Map<String, dynamic> t, bool large) {
    final tc = t["color"] as Color;
    final size = large ? 44.0 : 34.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tc.withOpacity(0.1),
        border: Border.all(color: tc.withOpacity(0.3)),
      ),
      child: Icon(t["icon"] as IconData, color: tc, size: large ? 22 : 16),
    );
  }

  // ── Stats Row ──
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        Expanded(
            child: _statCard(Icons.check_circle_outline, "Jobs Done",
                "$completedJobs", _C.success)),
        const SizedBox(width: 10),
        Expanded(
            child:
                _statCard(Icons.stars_outlined, "Points / Job", "50", _C.cyan)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                _currentTier["icon"] as IconData,
                "Tier",
                _currentTier["name"] as String,
                _currentTier["color"] as Color)),
      ]),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: _C.text, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.textSub, fontSize: 10)),
      ]),
    );
  }

  // ── Catalogue ──
  Widget _buildCatalogueSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.card_giftcard_outlined, "Redeem Rewards"),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemCount: catalogue.length,
          itemBuilder: (_, i) {
            final item = catalogue[i];
            final c = item["color"] as Color;
            final pts = item["points"] as int;
            final canRedeem = totalPoints >= pts;
            return GestureDetector(
              onTap: canRedeem ? () => _showRedeemDialog(item) : null,
              child: AnimatedOpacity(
                opacity: canRedeem ? 1.0 : 0.45,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _C.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: canRedeem ? c.withOpacity(0.3) : _C.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            Icon(item["icon"] as IconData, color: c, size: 18),
                      ),
                      Text(item["title"] as String,
                          maxLines: 2,
                          style: TextStyle(
                              color: _C.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.3)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("$pts pts",
                              style: TextStyle(
                                  color: c,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                          if (canRedeem)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: c.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: c.withOpacity(0.3)),
                              ),
                              child: Text("Redeem",
                                  style: TextStyle(
                                      color: c,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            )
                          else
                            Icon(Icons.lock_outline,
                                color: _C.textHint, size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  void _showRedeemDialog(Map<String, dynamic> item) {
    final c = item["color"] as Color;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _C.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: _C.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item["icon"] as IconData, color: c, size: 30),
          ),
          const SizedBox(height: 14),
          Text(item["title"] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _C.text, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text("Costs ${item["points"]} points",
              style: TextStyle(color: _C.textSub, fontSize: 13)),
          const SizedBox(height: 4),
          Text("You have $totalPoints points",
              style: TextStyle(
                  color: _C.cyan, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                _redeemReward(item);
              },
              child: const Text("Confirm Redemption",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(color: _C.textSub, fontSize: 13)),
          ),
        ]),
      ),
    );
  }

  Future<void> _redeemReward(Map<String, dynamic> item) async {
    final pts = item["points"] as int;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({"rewardPoints": totalPoints - pts});
      setState(() => totalPoints -= pts);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${item["title"]} redeemed successfully!",
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } catch (e) {
      debugPrint("Redeem error: $e");
    }
  }

  // ── History ──
  Widget _buildHistorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.history_rounded, "Points History"),
        const SizedBox(height: 12),
        if (history.isEmpty)
          _buildEmptyHistory()
        else
          ...history.map((h) => _historyItem(h)),
      ]),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _C.cyanLight,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.inbox_outlined, color: _C.cyan, size: 26),
        ),
        const SizedBox(height: 12),
        Text("No completed jobs yet",
            style: TextStyle(
                color: _C.text, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text("Complete a booking to earn 50 points!",
            style: TextStyle(color: _C.textSub, fontSize: 12),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _historyItem(Map<String, dynamic> h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _C.cyanLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.star_rounded, color: _C.cyan, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h["service"] as String,
                style: TextStyle(
                    color: _C.text, fontSize: 13, fontWeight: FontWeight.w600)),
            if ((h["sub"] as String).isNotEmpty)
              Text(h["sub"] as String,
                  style: TextStyle(color: _C.textSub, fontSize: 11)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.cyanLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.borderCyan),
            ),
            child: Text("+50 pts",
                style: TextStyle(
                    color: _C.cyanDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 3),
          Text("Completed",
              style: TextStyle(
                  color: _C.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  // ── Helpers ──
  Widget _sectionHeader(IconData icon, String title) {
    return Row(children: [
      Icon(icon, color: _C.cyan, size: 16),
      const SizedBox(width: 7),
      Text(title,
          style: TextStyle(
              color: _C.text, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 0.5, color: _C.border)),
    ]);
  }
}
