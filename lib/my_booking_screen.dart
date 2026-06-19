import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'rate_worker_screen.dart';
import 'book_service.dart';
import 'tracking_screen.dart';

// ─────────────────────────────────────────────
//  CYAN THEME COLORS
// ─────────────────────────────────────────────
const _kDark = Color(0xFF0097A7);
const _kCyan = Color(0xFF00BCD4);
const _kLightCyan = Color(0xFFE0F7FA);
const _kBg = Color(0xFFF4FCFD);

// ─────────────────────────────────────────────
//  STATUS CONFIG
// ─────────────────────────────────────────────
class _StatusStyle {
  const _StatusStyle(
      {required this.label, required this.bg, required this.color});
  final String label;
  final Color bg, color;
}

const _kStatusMap = <String, _StatusStyle>{
  'pending': _StatusStyle(
      label: 'Searching Worker',
      bg: Color(0xFFE0F7FA),
      color: Color(0xFF006064)),
  'accepted': _StatusStyle(
      label: 'Worker Assigned',
      bg: Color(0xFFE0F7FA),
      color: Color(0xFF006064)),
  'ongoing': _StatusStyle(
      label: 'In Progress', bg: Color(0xFFE3F2FD), color: Color(0xFF0D47A1)),
  'completed': _StatusStyle(
      label: 'Completed', bg: Color(0xFFE8F5E9), color: Color(0xFF1B5E20)),
  'cancelled': _StatusStyle(
      label: 'Cancelled', bg: Color(0xFFFFEBEE), color: Color(0xFFC62828)),
  'scheduled': _StatusStyle(
      label: 'Scheduled', bg: Color(0xFFF3E5F5), color: Color(0xFF6A1B9A)),
  'waiting': _StatusStyle(
      label: 'Awaiting Confirmation',
      bg: Color(0xFFE0F7FA),
      color: Color(0xFF006064)),
};

const _kTabs = [
  'All',
  'Active',
  'Instant',
  'Scheduled',
  'Completed',
  'Cancelled'
];

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  int _total = 0;
  int _active = 0;
  double _spent = 0;

  static const _activeStatuses = ['pending', 'accepted', 'ongoing', 'waiting'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _kTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  FIRESTORE STREAM
  // ─────────────────────────────────────────────
  Stream<QuerySnapshot> get _stream {
    if (_uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: _uid)
        .snapshots();
  }

  // ─────────────────────────────────────────────
  //  FILTER + SORT
  // ─────────────────────────────────────────────
  List<QueryDocumentSnapshot> _filter(
      List<QueryDocumentSnapshot> docs, String tab) {
    final sorted = List<QueryDocumentSnapshot>.from(docs)
      ..sort((a, b) {
        final aTs = (a.data() as Map<String, dynamic>?)?['createdAt'];
        final bTs = (b.data() as Map<String, dynamic>?)?['createdAt'];
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return (bTs as Timestamp).compareTo(aTs as Timestamp);
      });

    switch (tab) {
      case 'Active':
        return sorted
            .where((d) => _activeStatuses
                .contains((d.data() as Map<String, dynamic>)['status']))
            .toList();
      case 'Instant':
        return sorted
            .where((d) =>
                (d.data() as Map<String, dynamic>)['isScheduled'] != true)
            .toList();
      case 'Scheduled':
        return sorted
            .where((d) =>
                (d.data() as Map<String, dynamic>)['isScheduled'] == true)
            .toList();
      case 'Completed':
        return sorted
            .where((d) =>
                (d.data() as Map<String, dynamic>)['status'] == 'completed')
            .toList();
      case 'Cancelled':
        return sorted
            .where((d) =>
                (d.data() as Map<String, dynamic>)['status'] == 'cancelled')
            .toList();
      default:
        return sorted;
    }
  }

  // ─────────────────────────────────────────────
  //  OPEN TRACKING
  // ─────────────────────────────────────────────
  void _openTracking(String id, Map<String, dynamic> d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingScreen(
          workerId: d['workerId'] ?? '',
          workerName: d['workerName'] ?? '',
          requestId: id,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CANCEL BOOKING
  // ─────────────────────────────────────────────
  Future<void> _cancel(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Cancel Booking',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await FirebaseFirestore.instance.collection('requests').doc(id).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      HapticFeedback.lightImpact();
      _snack('Booking cancelled');
    } catch (e) {
      _snack('Failed to cancel. Try again.', err: true);
    }
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: err ? Colors.red : _kCyan,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _fmtDate(dynamic ts) {
    if (ts == null) return 'N/A';
    try {
      return DateFormat('d MMM, h:mm a').format((ts as Timestamp).toDate());
    } catch (_) {
      return 'N/A';
    }
  }

  String _fmtAmt(double v) => v >= 1000
      ? '₹${(v / 1000).toStringAsFixed(1)}k'
      : '₹${v.toStringAsFixed(0)}';

  void _rebook(Map<String, dynamic> d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookServiceScreen(
          category: d['category'] as String? ?? '',
          subCategory: d['subCategory'] as String? ?? '',
          serviceName: d['subCategory'] as String? ?? '',
        ),
      ),
    );
  }

  void _rateWorker(String bookingId, Map<String, dynamic> d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RateWorkerScreen(
          bookingId: bookingId,
          workerId: d['workerId'] as String? ?? '',
          workerName: d['workerName'] as String? ?? 'Worker',
          workerJob: d['subCategory'] as String? ?? '',
          requestId: bookingId,
          amountPaid: ((d['total'] ?? 0) as num).toDouble(),
          serviceDate: _fmtDate(d['scheduledAt'] ?? d['createdAt']),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Error loading bookings\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              ]),
            );
          }

          final docs =
              snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot>[];

          _total = docs.length;
          _active = docs
              .where((d) => _activeStatuses
                  .contains((d.data() as Map<String, dynamic>)['status']))
              .length;
          _spent = docs
              .where((d) =>
                  (d.data() as Map<String, dynamic>)['status'] == 'completed')
              .fold(
                  0.0,
                  (s, d) =>
                      s +
                      (((d.data() as Map<String, dynamic>)['total'] ?? 0)
                              as num)
                          .toDouble());

          return NestedScrollView(
            headerSliverBuilder: (c, _) => [
              SliverToBoxAdapter(child: _buildHeader()),
            ],
            body: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: _kTabs.map((tab) {
                      final list = _filter(docs, tab);
                      return _buildContent(list, snap.connectionState, tab);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF0097A7)]),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 16,
        right: 16,
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Bookings',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22)),
                    SizedBox(height: 4),
                    Text('Tap any booking to track your worker',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Icon(Icons.receipt_long_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(children: [
            _SumCard(value: '$_total', label: 'Bookings'),
            const SizedBox(width: 10),
            _SumCard(value: '$_active', label: 'Active'),
            const SizedBox(width: 10),
            _SumCard(value: _fmtAmt(_spent), label: 'Spent'),
          ]),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB BAR
  // ─────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: _kDark,
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: _kTabs.map((e) => Tab(text: e)).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CONTENT
  // ─────────────────────────────────────────────
  Widget _buildContent(
      List<QueryDocumentSnapshot> docs, ConnectionState state, String tab) {
    if (state == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: _kCyan));
    }

    if (docs.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            tab == 'Instant'
                ? Icons.flash_on_outlined
                : tab == 'Scheduled'
                    ? Icons.calendar_today_outlined
                    : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text('No $tab bookings yet',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          Text('Your bookings will appear here',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final doc = docs[i];
        final data = doc.data() as Map<String, dynamic>;
        final isScheduled = data['isScheduled'] == true;
        return _buildCard(doc.id, data, isScheduled: isScheduled);
      },
    );
  }

  // ─────────────────────────────────────────────
  //  BOOKING CARD  — tapping opens TrackingScreen
  // ─────────────────────────────────────────────
  Widget _buildCard(String id, Map<String, dynamic> d,
      {bool isScheduled = false}) {
    final status = (d['status'] as String?) ?? 'pending';
    final style = _kStatusMap[status] ?? _kStatusMap['pending']!;
    final total = ((d['total'] ?? 0) as num).toDouble();
    final isActive = _activeStatuses.contains(status);
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';
    final hasWorker = (d['workerId'] as String? ?? '').isNotEmpty;
    final workerName = d['workerName'] as String?;
    final address = d['address'] as String?;
    final isRated = d['isRated'] == true;
    final scheduledAt = d['scheduledAt'];

    // Card is tappable to open tracking when not cancelled/completed
    final bool canTrack = !isCancelled && !isCompleted;

    return GestureDetector(
      onTap: canTrack ? () => _openTracking(id, d) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: canTrack
                ? (isScheduled
                    ? const Color(0xFFCE93D8)
                    : _kCyan.withOpacity(0.5))
                : Colors.grey.shade200,
            width: canTrack ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top badge: Instant or Scheduled ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isScheduled
                    ? const Color(0xFFF3E5F5)
                    : const Color(0xFFE0F7FA),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isScheduled ? Icons.calendar_today : Icons.flash_on,
                    size: 13,
                    color: isScheduled ? const Color(0xFF6A1B9A) : _kDark,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isScheduled ? 'Scheduled Booking' : 'Instant Booking',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isScheduled ? const Color(0xFF6A1B9A) : _kDark,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  // "Tap to track" hint for active bookings
                  if (canTrack) ...[
                    Icon(Icons.my_location,
                        size: 12,
                        color: isScheduled ? const Color(0xFF6A1B9A) : _kDark),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to track',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isScheduled ? const Color(0xFF6A1B9A) : _kDark,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right,
                        size: 14,
                        color: isScheduled ? const Color(0xFF6A1B9A) : _kDark),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Main row ──
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isScheduled
                              ? const Color(0xFFF3E5F5)
                              : _kLightCyan,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isScheduled
                              ? Icons.calendar_month_rounded
                              : Icons.home_repair_service,
                          color: isScheduled ? const Color(0xFF6A1B9A) : _kCyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['subCategory'] as String? ?? 'Service',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 3),
                            Text(d['category'] as String? ?? '',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: style.bg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('● ${style.label}',
                                  style: TextStyle(
                                      color: style.color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                          const SizedBox(height: 4),
                          Text(_fmtDate(d['createdAt']),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),

                  // ── Scheduled time pill ──
                  if (isScheduled && scheduledAt != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCE93D8)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.schedule,
                            size: 14, color: Color(0xFF6A1B9A)),
                        const SizedBox(width: 8),
                        Text('Scheduled: ${_fmtDate(scheduledAt)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6A1B9A))),
                      ]),
                    ),
                  ],

                  // ── Address ──
                  if (address != null && address.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFB2EBF2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.location_on, size: 14, color: _kDark),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(address,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ),
                  ],

                  // ── Worker name (always visible if assigned) ──
                  if (hasWorker && workerName != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.person, size: 14, color: _kDark),
                      const SizedBox(width: 6),
                      Text(workerName,
                          style: const TextStyle(
                              fontSize: 12,
                              color: _kDark,
                              fontWeight: FontWeight.w600)),
                      if (d['workerRating'] != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 13, color: Colors.amber),
                        Text(' ${d['workerRating']}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black87)),
                      ],
                    ]),
                  ],

                  const SizedBox(height: 12),

                  // ── Action buttons ──
                  if (isCancelled)
                    _SolidBtn(label: 'Book Again', onTap: () => _rebook(d))
                  else if (isCompleted)
                    Row(children: [
                      if (!isRated) ...[
                        Expanded(
                          child: _OutlineBtn(
                            label: '⭐ Rate Worker',
                            onTap: () => _rateWorker(id, d),
                            isPurple: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                          child: _SolidBtn(
                              label: 'Book Again', onTap: () => _rebook(d))),
                    ])
                  else
                    Row(children: [
                      Expanded(
                        child: _OutlineBtn(
                            label: 'Cancel',
                            isRed: true,
                            onTap: () => _cancel(id)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OutlineBtn(
                          label: '📍 Track Worker',
                          isBlue: true,
                          onTap: () => _openTracking(id, d),
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUMMARY CARD
// ─────────────────────────────────────────────
class _SumCard extends StatelessWidget {
  const _SumCard({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  OUTLINE BUTTON
// ─────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.label,
    required this.onTap,
    this.isRed = false,
    this.isBlue = false,
    this.isPurple = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isRed, isBlue, isPurple;

  Color get _bg {
    if (isRed) return const Color(0xFFFFEBEE);
    if (isBlue) return const Color(0xFFE3F2FD);
    if (isPurple) return const Color(0xFFF3E5F5);
    return Colors.white;
  }

  Color get _border {
    if (isRed) return Colors.red.shade200;
    if (isBlue) return Colors.blue.shade200;
    if (isPurple) return Colors.purple.shade200;
    return Colors.grey.shade300;
  }

  Color get _text {
    if (isRed) return Colors.red;
    if (isBlue) return const Color(0xFF0D47A1);
    if (isPurple) return const Color(0xFF6A1B9A);
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _bg,
          border: Border.all(color: _border),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: _text, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SOLID BUTTON
// ─────────────────────────────────────────────
class _SolidBtn extends StatelessWidget {
  const _SolidBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
            color: _kDark, borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ),
    );
  }
}
