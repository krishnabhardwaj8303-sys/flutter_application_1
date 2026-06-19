// tracking_screen.dart
// User Side — Tracking Screen (Instant + Scheduled)
//
// STATUS MACHINE:
//   pending / waiting       → searching for worker
//   accepted                → worker assigned, heading to location
//   arrived                 → worker tapped "I've Arrived" → arrivalOtp generated
//   working                 → user verified arrival OTP → job timer running
//   waitingCompletionOtp    → user generated completion OTP → worker must enter it
//   completed               → worker entered correct OTP → show rating
//
// OTP FLOW (same for instant & scheduled):
//   1. Worker arrives → taps "I've Arrived" on their app → arrivalOtp saved to Firestore
//   2. User opens this screen → sees amber card → asks worker for OTP → enters it here
//      → otpVerified = true, status = 'working', workStartedAt = serverTimestamp
//   3. Work finishes → user taps "Work Finished?" → completionOtp generated
//      → status = 'waitingCompletionOtp'
//   4. User shows completionOtp to worker → worker enters it on their app → status = 'completed'
//   5. User rates worker → isRated = true
//
// FIXES APPLIED:
//   • setState never called directly from build() — moved side-effects to
//     WidgetsBinding.addPostFrameCallback
//   • TextEditingController in _openDialog disposed INSIDE the dialog (not via .then)
//     — eliminates use-after-dispose when Firestore update runs after Navigator.pop
//   • err variable moved inside StatefulBuilder builder scope for correct state isolation
//   • Firestore update in arrival OTP verify now wrapped in try/catch with error snackbar
//   • mounted guards added after every async gap in _generateCompletionOtp
//   • Rating: totalJobs NOT re-incremented here (already done in job_request_screen)
//   • Rating: average recalculated using already-incremented totalJobs
//   • workerTotalJobs vs totalJobs naming clarified
//   • _fetchPhone result cached to avoid repeated Firestore reads
//   • chatId properly populated in ChatScreen constructor

// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_screen.dart';
import 'worker_profile_screen.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const Color _cyan = Color(0xFF06B6D4);
const Color _cyanLight = Color(0xFFE0F8FC);
const Color _cyanDark = Color(0xFF0891B2);
const Color _bg = Color(0xFFF5FAFE);
const Color _card = Color(0xFFFFFFFF);
const Color _surface = Color(0xFFF0F8FC);
const Color _txtDark = Color(0xFF0D2B35);
const Color _txtMuted = Color(0xFF6B9BAD);
const Color _border = Color(0xFFD4ECF5);

const Color _green = Color(0xFF00C073);
const Color _greenBg = Color(0xFFDCFCE7);
const Color _greenBdr = Color(0xFF86EFAC);
const Color _greenTxt = Color(0xFF166534);

const Color _amber = Color(0xFFF59E0B);
const Color _amberBg = Color(0xFFFEF3C7);
const Color _amberBdr = Color(0xFFFDE68A);
const Color _amberTxt = Color(0xFF92400E);

const Color _purple = Color(0xFF9C27B0);
const Color _purpleBg = Color(0xFFF3E5F5);
const Color _purpleBdr = Color(0xFFCE93D8);
// ignore: unused_element
const Color _purpleTxt = Color(0xFF4A148C);

const Color _red = Color(0xFFF43F5E);
// ignore: unused_element
const Color _orange = Color(0xFFFF6B35);

String _genOtp() => (1000 + Random.secure().nextInt(9000)).toString();

// ═════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class TrackingScreen extends StatefulWidget {
  final String requestId;
  final String workerId;
  final String workerName;

  const TrackingScreen({
    super.key,
    required this.requestId,
    required this.workerId,
    required this.workerName,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // ── Scheduled countdown ───────────────────────────────────────────────────
  Timer? _countdownTimer;
  Duration _timeUntilJob = Duration.zero;
  bool _countdownStarted = false;
  bool _jobTimeReached = false;

  // ── Worker live location ──────────────────────────────────────────────────
  double? _workerLat;
  double? _workerLng;
  StreamSubscription<DocumentSnapshot>? _workerLocSub;
  String _subscribedWorkerId = '';

  // ── Cached worker phone (avoid repeated Firestore reads) ──────────────────
  String? _cachedWorkerPhone;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _workerLocSub?.cancel();
    super.dispose();
  }

  // ── Parse scheduled datetime from Firestore fields ────────────────────────
  DateTime? _parseScheduledAt(Map<String, dynamic> d) {
    final ts = d['scheduledAt'];
    if (ts is Timestamp) return ts.toDate();
    final dateStr = d['scheduledDate'] as String? ?? '';
    final timeStr = d['scheduledTime'] as String? ?? '';
    if (dateStr.isEmpty || timeStr.isEmpty) return null;
    try {
      final p = dateStr.split('/');
      if (p.length < 3) return null;
      final day = int.parse(p[0]);
      final month = int.parse(p[1]);
      final year = int.parse(p[2]);
      final tp = timeStr.replaceAll(RegExp(r'[APMapm ]'), '').split(':');
      int hour = int.parse(tp[0]);
      final min = tp.length > 1 ? int.parse(tp[1]) : 0;
      final isPm = timeStr.toUpperCase().contains('PM');
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return DateTime(year, month, day, hour, min);
    } catch (_) {
      return null;
    }
  }

  // ── Countdown timer (only within 30 min window) ───────────────────────────
  // NOTE: called via addPostFrameCallback — never directly from build()
  void _updateCountdown(Map<String, dynamic> data) {
    final scheduledAt = _parseScheduledAt(data);
    if (scheduledAt == null) return;
    final diff = scheduledAt.difference(DateTime.now());
    final inWindow = diff.inMinutes <= 30 && !diff.isNegative;

    if (inWindow && !_countdownStarted) {
      _countdownStarted = true;
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final d = scheduledAt.difference(DateTime.now());
        setState(() {
          _timeUntilJob = d.isNegative ? Duration.zero : d;
          _jobTimeReached = d.isNegative || d.inSeconds <= 0;
        });
      });
    }

    if (mounted) {
      setState(() {
        _timeUntilJob = diff.isNegative ? Duration.zero : diff;
        _jobTimeReached = diff.isNegative || diff.inMinutes <= 0;
        if (inWindow) _countdownStarted = true;
      });
    }
  }

  // ── Subscribe to worker GPS location ──────────────────────────────────────
  // NOTE: called via addPostFrameCallback — never directly from build()
  void _subscribeWorkerLocation(String workerId) {
    if (workerId.isEmpty || workerId == _subscribedWorkerId) return;
    _subscribedWorkerId = workerId;
    _workerLocSub?.cancel();
    _workerLocSub = FirebaseFirestore.instance
        .collection('workers')
        .doc(workerId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;
      final d = snap.data()!;
      final lat = (d['lat'] as num?)?.toDouble();
      final lng = (d['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        setState(() {
          _workerLat = lat;
          _workerLng = lng;
        });
      }
    });
  }

  // ── Fetch worker phone (cached after first call) ───────────────────────────
  Future<String> _fetchPhone(String workerId, String fallback) async {
    if (_cachedWorkerPhone != null) return _cachedWorkerPhone!;
    if (workerId.isEmpty) return fallback;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .get();
      _cachedWorkerPhone = doc.data()?['phone'] as String? ??
          doc.data()?['phoneNumber'] as String? ??
          fallback;
      return _cachedWorkerPhone!;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _callWorker(String phone) async {
    if (phone.isEmpty) {
      _snack('Phone not available');
      return;
    }
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[\s\-()]'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMapWithWorker(String workerName) async {
    if (_workerLat == null || _workerLng == null) {
      _snack('Worker location not available yet');
      return;
    }
    final label = Uri.encodeComponent(workerName);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1'
        '&query=$_workerLat,$_workerLng&query_place_id=$label');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── COMPLETION OTP: user generates, shows to worker ───────────────────────
  Future<void> _generateCompletionOtp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm work done?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This generates a completion OTP. Share it with the worker to confirm the job is finished.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Not yet', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, generate',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
        'completionOtp': _genOtp(),
        'completionOtpVerified': false,
        'status': 'waitingCompletionOtp',
        'completionOtpGeneratedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _snack('OTP generated — show it to the worker.', ok: true);
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e');
    }
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? _green : _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(child: CircularProgressIndicator(color: _cyan)),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final status = data['status'] as String? ?? '';
        final isScheduled = data['isScheduled'] == true;

        final arrivalOtp = data['arrivalOtp'] as String? ?? '';
        final arrivalOtpVerified = data['otpVerified'] == true;
        final completionOtp = data['completionOtp'] as String? ?? '';
        final completionOtpVerified = data['completionOtpVerified'] == true;

        final workerId = data['workerId'] as String? ?? '';
        final workerName = data['workerName'] as String? ?? 'Worker';
        final userId = data['userId'] as String? ?? '';
        final workStartedAt = data['workStartedAt'] as Timestamp?;

        final workerAssigned = const [
          'accepted',
          'arrived',
          'working',
          'ongoing',
          'waitingCompletionOtp',
          'completed'
        ].contains(status);

        // Side-effects deferred to post-frame to avoid setState-during-build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (isScheduled) _updateCountdown(data);
          if (workerId.isNotEmpty) _subscribeWorkerLocation(workerId);
        });

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark
              .copyWith(statusBarColor: Colors.transparent),
          child: Scaffold(
            backgroundColor: _bg,
            body: Column(children: [
              _TopBar(
                  isScheduled: isScheduled,
                  onBack: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. Hero card ─────────────────────────────────────
                      if (isScheduled)
                        _ScheduledHeroCard(
                          data: data,
                          timeUntilJob: _timeUntilJob,
                          jobTimeReached: _jobTimeReached,
                          countdownStarted: _countdownStarted,
                        )
                      else
                        _InstantHeroCard(data: data, status: status),
                      const SizedBox(height: 12),

                      // ── 2. Live map ──────────────────────────────────────
                      if (workerAssigned) ...[
                        _TrackWorkerCard(
                          workerName: workerName,
                          workerImage: data['workerImage'] as String? ?? '',
                          workerLat: _workerLat,
                          workerLng: _workerLng,
                          onTrack: () => _openMapWithWorker(workerName),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── 3. Status timeline ────────────────────────────────
                      _StatusTimeline(
                        status: status,
                        isScheduled: isScheduled,
                        arrivalOtpVerified: arrivalOtpVerified,
                        completionOtpVerified: completionOtpVerified,
                      ),
                      const SizedBox(height: 12),

                      // ── 4. Job duration timer ─────────────────────────────
                      if (workStartedAt != null &&
                          const ['working', 'waitingCompletionOtp', 'completed']
                              .contains(status)) ...[
                        _JobTimerCard(
                          workStartedAt: workStartedAt,
                          isCompleted: status == 'completed',
                          completedAt: data['completedAt'] as Timestamp?,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── 5. Worker card ────────────────────────────────────
                      if (workerAssigned) ...[
                        _WorkerCard(
                          data: data,
                          requestId: widget.requestId,
                          onCall: () async {
                            final phone = await _fetchPhone(
                                workerId, data['workerPhone'] as String? ?? '');
                            if (mounted) await _callWorker(phone);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── 6a. Arrival OTP entry (user enters OTP from worker)
                      if (arrivalOtp.isNotEmpty && status == 'arrived') ...[
                        _ArrivalOtpSection(
                          otp: arrivalOtp,
                          otpVerified: arrivalOtpVerified,
                          requestId: widget.requestId,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── 6b. Arrival verified badge ────────────────────────
                      if (arrivalOtpVerified &&
                          const ['working', 'waitingCompletionOtp', 'completed']
                              .contains(status)) ...[
                        _VerifiedBadge(
                          icon: Icons.verified_rounded,
                          color: _green,
                          bg: _greenBg,
                          border: _greenBdr,
                          text: 'Worker arrival confirmed ✓',
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── 7a. Generate completion OTP (work in progress) ─────
                      if (status == 'working') ...[
                        _GenerateCompletionOtpCard(
                            onGenerate: _generateCompletionOtp),
                        const SizedBox(height: 12),
                      ],

                      // ── 7b. Display completion OTP for user to show worker ─
                      if (completionOtp.isNotEmpty &&
                          status == 'waitingCompletionOtp') ...[
                        _CompletionOtpDisplayCard(
                          otp: completionOtp,
                          otpVerified: completionOtpVerified,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── 7c. Completion verified badge ─────────────────────
                      if (completionOtpVerified || status == 'completed') ...[
                        _VerifiedBadge(
                          icon: Icons.check_circle_rounded,
                          color: _green,
                          bg: _greenBg,
                          border: _greenBdr,
                          text: 'Job completion confirmed ✓',
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── 8. Job summary ─────────────────────────────────────
                      _JobSummary(data: data),
                      const SizedBox(height: 12),

                      // ── 9. Rating (completed only) ─────────────────────────
                      if (status == 'completed') _buildRatingSection(data),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildRatingSection(Map<String, dynamic> data) {
    if (data['isRated'] == true) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _greenBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _greenBdr),
        ),
        child:
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.star_rounded, color: _amber, size: 22),
          SizedBox(width: 8),
          Text('Thanks for your rating!',
              style: TextStyle(
                  color: _greenTxt, fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      );
    }
    return _RatingCard(
      requestId: widget.requestId,
      workerId: data['workerId'] as String? ?? '',
      workerName: data['workerName'] as String? ?? 'Worker',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'User',
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  HERO CARDS
// ═════════════════════════════════════════════════════════════════════════════

class _InstantHeroCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String status;
  const _InstantHeroCard({required this.data, required this.status});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';
    final isWorking =
        const ['working', 'waitingCompletionOtp'].contains(status);
    final isPending = const ['pending', 'waiting'].contains(status);

    final List<Color> grad = isCancelled
        ? [const Color(0xFFF43F5E), const Color(0xFFC62828)]
        : isCompleted
            ? [const Color(0xFF00C073), const Color(0xFF00897B)]
            : isWorking
                ? [const Color(0xFF0891B2), const Color(0xFF06B6D4)]
                : [const Color(0xFF06B6D4), const Color(0xFF0097A7)];

    final IconData icon = isCancelled
        ? Icons.cancel_rounded
        : isCompleted
            ? Icons.check_circle_rounded
            : isWorking
                ? Icons.construction_rounded
                : isPending
                    ? Icons.search_rounded
                    : Icons.flash_on_rounded;

    final String title = isCancelled
        ? 'Booking cancelled'
        : isCompleted
            ? 'Job completed ✓'
            : isWorking
                ? 'Work in progress'
                : isPending
                    ? 'Finding worker...'
                    : 'Worker assigned';

    final String sub = isCancelled
        ? 'This booking was cancelled'
        : isCompleted
            ? 'Please rate your experience below'
            : isWorking
                ? 'Your worker is working at your location'
                : isPending
                    ? 'Searching for the best worker nearby'
                    : 'Worker is on the way to your location';

    final String badge = isCancelled
        ? 'CANCELLED'
        : isCompleted
            ? 'DONE'
            : isWorking
                ? 'ACTIVE'
                : isPending
                    ? 'SEARCHING'
                    : 'ASSIGNED';

    return _HeroShell(
      grad: grad,
      icon: icon,
      badge: badge,
      topLabel: 'INSTANT BOOKING',
      topIcon: Icons.flash_on,
      title: title,
      sub: sub,
    );
  }
}

class _ScheduledHeroCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Duration timeUntilJob;
  final bool jobTimeReached, countdownStarted;
  const _ScheduledHeroCard({
    required this.data,
    required this.timeUntilJob,
    required this.jobTimeReached,
    required this.countdownStarted,
  });

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final date = data['scheduledDate'] as String? ?? '—';
    final time = data['scheduledTime'] as String? ?? '—';
    final status = data['status'] as String? ?? '';
    final isCompleted = status == 'completed';

    final List<Color> grad = isCompleted
        ? [const Color(0xFF00C073), const Color(0xFF00A86B)]
        : jobTimeReached
            ? [const Color(0xFF06B6D4), const Color(0xFF0891B2)]
            : countdownStarted
                ? [const Color(0xFFFF6B35), const Color(0xFFFF8C42)]
                : [_purple, const Color(0xFF7B1FA2)];

    final String title = isCompleted
        ? 'Job completed ✓'
        : jobTimeReached
            ? 'Worker is on the way!'
            : countdownStarted
                ? 'Job starting soon!'
                : 'Upcoming scheduled job';

    final String badge = isCompleted
        ? 'DONE'
        : jobTimeReached
            ? 'LIVE'
            : countdownStarted
                ? 'SOON'
                : 'UPCOMING';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: grad.first.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : jobTimeReached
                      ? Icons.directions_run_rounded
                      : countdownStarted
                          ? Icons.alarm_rounded
                          : Icons.event_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Row(children: [
                  Icon(Icons.calendar_today, color: Colors.white70, size: 11),
                  SizedBox(width: 4),
                  Text('SCHEDULED BOOKING',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 2),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                Text('$date  •  $time',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Text(badge,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 16),
        if (isCompleted)
          _bannerBox('🎉 Service completed! Rate your experience below.',
              sub: null)
        else if (jobTimeReached)
          _bannerBox('🚗 Worker is heading to your location',
              sub: 'Track them on the map below')
        else if (countdownStarted)
          _countdownWidget()
        else
          _upcomingBanner(date, time),
      ]),
    );
  }

  Widget _bannerBox(String msg, {String? sub}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
          ],
        ]),
      );

  Widget _countdownWidget() {
    final mins = timeUntilJob.inMinutes;
    final secs = timeUntilJob.inSeconds % 60;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Job starts in',
          style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _CBox(value: _pad(mins), label: 'min'),
        const Text(':',
            style: TextStyle(
                color: Colors.white60,
                fontSize: 26,
                fontWeight: FontWeight.w700)),
        _CBox(value: _pad(secs), label: 'sec'),
      ]),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)),
        child: const Text('Be ready — worker will arrive soon.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _upcomingBanner(String date, String time) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          const Text('Your booking is confirmed',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Countdown starts 30 min before $time',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.event_rounded, color: Colors.white60, size: 14),
            const SizedBox(width: 5),
            Text('$date at $time',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ]),
      );
}

class _HeroShell extends StatelessWidget {
  final List<Color> grad;
  final IconData icon;
  final String badge, topLabel, title, sub;
  final IconData topIcon;
  const _HeroShell({
    required this.grad,
    required this.icon,
    required this.badge,
    required this.topLabel,
    required this.topIcon,
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: grad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: grad.first.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(topIcon, color: Colors.white70, size: 13),
                const SizedBox(width: 4),
                Text(topLabel,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
              ]),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(sub,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.3)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Text(badge,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
        ]),
      );
}

class _CBox extends StatelessWidget {
  final String value, label;
  const _CBox({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 72,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Center(
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900))),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ]);
}

// ═════════════════════════════════════════════════════════════════════════════
//  TOP BAR
// ═════════════════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final bool isScheduled;
  final VoidCallback onBack;
  const _TopBar({required this.isScheduled, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: _card,
      padding: EdgeInsets.fromLTRB(14, top + 10, 14, 12),
      child: Row(children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _border)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: _txtDark),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isScheduled ? _purpleBg : _cyanLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isScheduled ? Icons.calendar_today_rounded : Icons.flash_on_rounded,
            color: isScheduled ? _purple : _cyan,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isScheduled ? 'Scheduled booking' : 'Instant booking',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _txtDark),
            ),
            const Text('Track your service in real time',
                style: TextStyle(fontSize: 11, color: _txtMuted)),
          ]),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TRACK WORKER CARD
// ═════════════════════════════════════════════════════════════════════════════
class _TrackWorkerCard extends StatelessWidget {
  final String workerName, workerImage;
  final double? workerLat, workerLng;
  final VoidCallback onTrack;
  const _TrackWorkerCard({
    required this.workerName,
    required this.workerImage,
    required this.workerLat,
    required this.workerLng,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    final hasLoc = workerLat != null && workerLng != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasLoc ? _cyan.withOpacity(0.5) : _border),
        boxShadow: hasLoc
            ? [
                BoxShadow(
                    color: _cyan.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]
            : [],
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.map_rounded, color: _cyan, size: 14),
          const SizedBox(width: 6),
          const Text('LIVE TRACKING',
              style: TextStyle(
                  color: _cyan,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
          const Spacer(),
          if (hasLoc)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _greenBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _greenBdr)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: _green, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('Live',
                    style: TextStyle(
                        color: _greenTxt,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
        const Divider(color: _border, height: 16),

        // Map area
        GestureDetector(
          onTap: hasLoc ? onTrack : null,
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: hasLoc ? _cyanLight : _surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: hasLoc ? _cyan.withOpacity(0.3) : _border),
            ),
            child: hasLoc
                ? Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://staticmap.openstreetmap.de/staticmap.php'
                        '?center=$workerLat,$workerLng&zoom=15&size=400x140',
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _mapFallback(true),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.navigation,
                                  color: Colors.white, size: 13),
                              SizedBox(width: 5),
                              Text('Worker moving',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ]),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded,
                                  color: _cyan, size: 15),
                              SizedBox(width: 6),
                              Text('Open Maps',
                                  style: TextStyle(
                                      color: _cyanDark,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700)),
                            ]),
                      ),
                    ),
                  ])
                : _mapFallback(false),
          ),
        ),

        const SizedBox(height: 12),
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasLoc ? _cyanLight : _surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasLoc
                  ? Icons.location_on_rounded
                  : Icons.location_searching_rounded,
              color: hasLoc ? _cyan : _txtMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  hasLoc
                      ? '$workerName is on the way'
                      : 'Waiting for worker location...',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasLoc ? _txtDark : _txtMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  hasLoc
                      ? 'Lat ${workerLat!.toStringAsFixed(4)}, Lng ${workerLng!.toStringAsFixed(4)}'
                      : 'Updates once worker starts moving',
                  style: const TextStyle(fontSize: 11, color: _txtMuted),
                ),
              ])),
          if (hasLoc)
            GestureDetector(
              onTap: onTrack,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: _cyan, borderRadius: BorderRadius.circular(10)),
                child: const Text('Track',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _mapFallback(bool hasLoc) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(hasLoc ? Icons.map_rounded : Icons.location_off_rounded,
              color: hasLoc ? _cyan : _txtMuted, size: 36),
          const SizedBox(height: 8),
          Text(
            hasLoc ? 'Tap to open in Maps' : 'Location not available yet',
            style: TextStyle(
                color: hasLoc ? _cyanDark : _txtMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600),
          ),
        ],
      );
}

// ═════════════════════════════════════════════════════════════════════════════
//  STATUS TIMELINE
// ═════════════════════════════════════════════════════════════════════════════
class _StatusTimeline extends StatelessWidget {
  final String status;
  final bool isScheduled, arrivalOtpVerified, completionOtpVerified;
  const _StatusTimeline({
    required this.status,
    required this.isScheduled,
    required this.arrivalOtpVerified,
    required this.completionOtpVerified,
  });

  static const _scheduledSteps = [
    {
      'key': 'confirmed',
      'label': 'Booking confirmed',
      'icon': Icons.event_rounded
    },
    {
      'key': 'accepted',
      'label': 'Worker assigned',
      'icon': Icons.person_pin_rounded
    },
    {
      'key': 'arrived',
      'label': 'Worker arrived',
      'icon': Icons.location_on_rounded
    },
    {
      'key': 'working',
      'label': 'Work in progress',
      'icon': Icons.construction_rounded
    },
    {
      'key': 'completed',
      'label': 'Job completed',
      'icon': Icons.verified_rounded
    },
  ];

  static const _instantSteps = [
    {
      'key': 'pending',
      'label': 'Booking placed',
      'icon': Icons.receipt_rounded
    },
    {
      'key': 'accepted',
      'label': 'Worker assigned',
      'icon': Icons.person_pin_rounded
    },
    {
      'key': 'arrived',
      'label': 'Worker arrived',
      'icon': Icons.location_on_rounded
    },
    {
      'key': 'working',
      'label': 'Work in progress',
      'icon': Icons.construction_rounded
    },
    {
      'key': 'completed',
      'label': 'Job completed',
      'icon': Icons.verified_rounded
    },
  ];

  List<Map<String, dynamic>> get _steps =>
      (isScheduled ? _scheduledSteps : _instantSteps)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  int get _cur {
    switch (status) {
      case 'completed':
        return 4;
      case 'working':
      case 'waitingCompletionOtp':
      case 'ongoing':
        return 3;
      case 'arrived':
        return 2;
      case 'accepted':
        return 1;
      default:
        return 0;
    }
  }

  String _sub(int i) {
    if (i == 2 && status == 'arrived' && !arrivalOtpVerified) {
      return 'Enter arrival OTP below to confirm';
    }
    if (i == 2 && arrivalOtpVerified) return 'Arrival confirmed ✓';
    if (i == 3 && status == 'working') return 'Tap below when work is done';
    if (i == 3 && status == 'waitingCompletionOtp' && !completionOtpVerified) {
      return 'Show OTP to worker to complete';
    }
    if (i == 3 && completionOtpVerified) return 'Work confirmed ✓';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cur = _cur;
    final steps = _steps;
    final Color accent = isScheduled ? _purple : _cyan;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(children: [
        Row(children: [
          Icon(isScheduled ? Icons.calendar_today : Icons.flash_on,
              color: accent, size: 13),
          const SizedBox(width: 6),
          Text(isScheduled ? 'SCHEDULED PROGRESS' : 'BOOKING PROGRESS',
              style: TextStyle(
                  color: accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
        ]),
        const Divider(color: _border, height: 16),
        ...List.generate(steps.length, (i) {
          final done = i <= cur;
          final active = i == cur;
          final isLast = i == steps.length - 1;
          final sub = _sub(i);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: active ? 36 : 28,
                height: active ? 36 : 28,
                decoration: BoxDecoration(
                  color: done ? accent : _surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: done ? accent : _border, width: active ? 2 : 1.5),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: accent.withOpacity(0.3), blurRadius: 10)
                        ]
                      : [],
                ),
                child: Icon(steps[i]['icon'] as IconData,
                    color: done ? Colors.white : _txtMuted,
                    size: active ? 18 : 13),
              ),
              if (!isLast)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 2,
                  height: 28,
                  color: i < cur ? accent : _border,
                ),
            ]),
            const SizedBox(width: 14),
            Padding(
              padding:
                  EdgeInsets.only(top: active ? 8 : 5, bottom: isLast ? 0 : 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(steps[i]['label'] as String,
                        style: TextStyle(
                            color: done ? _txtDark : _txtMuted,
                            fontSize: active ? 13.5 : 12.5,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w500)),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(sub,
                          style: TextStyle(
                              color: sub.contains('✓') ? _green : _amber,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ]),
            ),
          ]);
        }),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  JOB TIMER CARD (self-contained stateful widget)
// ═════════════════════════════════════════════════════════════════════════════
class _JobTimerCard extends StatefulWidget {
  final Timestamp workStartedAt;
  final bool isCompleted;
  final Timestamp? completedAt;
  const _JobTimerCard({
    required this.workStartedAt,
    required this.isCompleted,
    this.completedAt,
  });
  @override
  State<_JobTimerCard> createState() => _JobTimerCardState();
}

class _JobTimerCardState extends State<_JobTimerCard> {
  Timer? _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = _calc();
    if (!widget.isCompleted) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed = _calc());
      });
    }
  }

  Duration _calc() {
    final end = widget.isCompleted && widget.completedAt != null
        ? widget.completedAt!.toDate()
        : DateTime.now();
    return end.difference(widget.workStartedAt.toDate());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.isCompleted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: done ? _greenBg : _cyanLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: done ? _greenBdr : _cyan.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: done ? _green.withOpacity(0.15) : _cyan.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(done ? Icons.timer_off_rounded : Icons.timer_rounded,
              color: done ? _green : _cyan, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(done ? 'Total job duration' : 'Time elapsed',
              style: TextStyle(
                  fontSize: 11.5,
                  color: done ? _greenTxt : _cyanDark,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(_fmt(_elapsed),
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: done ? _green : _cyan,
                  letterSpacing: 2)),
        ])),
        if (!done)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: _cyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: _cyan, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('LIVE',
                  style: TextStyle(
                      color: _cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ]),
          ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  WORKER CARD
// ═════════════════════════════════════════════════════════════════════════════
class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String requestId;
  final VoidCallback onCall;
  const _WorkerCard({
    required this.data,
    required this.requestId,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final workerName = data['workerName'] as String? ?? 'Worker';
    final workerImage = data['workerImage'] as String? ?? '';
    final workerPhone = data['workerPhone'] as String? ?? '';
    final workerRating = (data['workerRating'] as num?)?.toDouble() ?? 0.0;
    // workerTotalJobs is a denormalized copy written to the request doc at booking time
    final workerJobs = data['workerTotalJobs'] ?? 0;
    final workerId = data['workerId'] as String? ?? '';
    final userId = data['userId'] as String? ?? '';
    final serviceName = data['subCategory'] as String? ?? '';
    final chatRoomId = 'chat_${requestId}_${workerId}_$userId';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.engineering_rounded, color: _cyan, size: 14),
          SizedBox(width: 6),
          Text('YOUR WORKER',
              style: TextStyle(
                  color: _cyan,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
        ]),
        const Divider(color: _border, height: 16),
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        WorkerProfileScreen(uid: workerId, isEditable: false))),
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 60,
                  height: 60,
                  color: _cyanLight,
                  child: workerImage.isNotEmpty
                      ? Image.network(workerImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: _cyanDark,
                              size: 30))
                      : const Icon(Icons.person_rounded,
                          color: _cyanDark, size: 30),
                ),
              ),
              Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                          border: Border.all(color: _card, width: 2)))),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(workerName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _txtDark)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, color: _amber, size: 14),
                const SizedBox(width: 3),
                Text('${workerRating.toStringAsFixed(1)}  ·  $workerJobs jobs',
                    style: const TextStyle(color: _txtMuted, fontSize: 12)),
              ]),
              if (workerPhone.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.phone_rounded, color: _txtMuted, size: 12),
                  const SizedBox(width: 4),
                  Text(workerPhone,
                      style: const TextStyle(color: _txtMuted, fontSize: 12)),
                ]),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        WorkerProfileScreen(uid: workerId, isEditable: false))),
            icon: const Icon(Icons.person_outline, size: 15, color: _cyan),
            label: const Text('Profile',
                style: TextStyle(color: _cyan, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _cyan),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(
              child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatRoomId: chatRoomId,
                    currentUserId: userId,
                    otherUserId: workerId,
                    otherUserName: workerName,
                    otherUserImage: workerImage,
                    isWorker: false,
                    chatId: 'chat_$requestId',
                    workerName: workerName,
                    workerId: workerId,
                    workerPhone: workerPhone,
                    serviceName: serviceName,
                    requestId: requestId,
                  ),
                )),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
            label: const Text('Chat', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(
              child: ElevatedButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.call_rounded, size: 15),
            label: const Text('Call', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          )),
        ]),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  ARRIVAL OTP SECTION
//  Worker generates OTP on their screen → tells user verbally → user types here
// ═════════════════════════════════════════════════════════════════════════════
class _ArrivalOtpSection extends StatefulWidget {
  final String otp, requestId;
  final bool otpVerified;
  const _ArrivalOtpSection({
    required this.otp,
    required this.otpVerified,
    required this.requestId,
  });
  @override
  State<_ArrivalOtpSection> createState() => _ArrivalOtpSectionState();
}

class _ArrivalOtpSectionState extends State<_ArrivalOtpSection> {
  // ── KEY FIX: _openDialog no longer uses .then(ctrl.dispose()).
  //    The controller is disposed INSIDE the dialog — either on Cancel
  //    (before Navigator.pop) or on successful verify (before Navigator.pop),
  //    ensuring the controller is never accessed after disposal.
  void _openDialog() {
    final ctrl = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        // err is declared INSIDE the builder so StatefulBuilder owns it
        // cleanly and it doesn't bleed across rebuilds.
        String? err;
        return StatefulBuilder(
          builder: (dCtx, setS) => AlertDialog(
            backgroundColor: _card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: _amberBg, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.lock_open_rounded,
                    color: _amber, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Enter arrival OTP',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _txtDark)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _amberBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _amberBdr)),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: _amber, size: 15),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                    'Your worker has arrived.\nAsk them for the 4-digit OTP on their screen.',
                    style:
                        TextStyle(fontSize: 12, color: _amberTxt, height: 1.4),
                  )),
                ]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 14,
                    color: _txtDark),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 28,
                      letterSpacing: 14),
                  errorText: err,
                  filled: true,
                  fillColor: _surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _amber, width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _red)),
                ),
              ),
              const SizedBox(height: 18),
            ]),
            actions: [
              TextButton(
                onPressed: () {
                  // Dispose BEFORE pop so nothing touches ctrl after this line
                  ctrl.dispose();
                  Navigator.pop(dCtx);
                },
                child: const Text('Cancel', style: TextStyle(color: _txtMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _amber,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 11)),
                onPressed: () async {
                  // ── 1. Validate BEFORE closing — ctrl still alive here ──
                  final entered = ctrl.text.trim();
                  if (entered != widget.otp) {
                    setS(() => err = 'Incorrect OTP — try again');
                    return;
                  }

                  // ── 2. Dispose controller, then close dialog ────────────
                  //    No more ctrl access after this point.
                  ctrl.dispose();
                  Navigator.pop(dCtx);

                  // ── 3. Firestore update — controller is fully gone ──────
                  if (!mounted) return;
                  try {
                    await FirebaseFirestore.instance
                        .collection('requests')
                        .doc(widget.requestId)
                        .update({
                      'otpVerified': true,
                      'status': 'working',
                      'workStartedAt': FieldValue.serverTimestamp(),
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('✓ Arrival confirmed — work has started!'),
                      backgroundColor: _green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error updating status: $e'),
                      backgroundColor: _red,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                child: const Text('Verify OTP',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
    // ← No .then(ctrl.dispose()) — controller lifecycle is fully managed above
  }

  @override
  Widget build(BuildContext context) {
    if (widget.otpVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: _greenBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _greenBdr)),
        child: const Row(children: [
          Icon(Icons.verified_rounded, color: _green, size: 18),
          SizedBox(width: 8),
          Text('Arrival OTP verified ✓',
              style: TextStyle(
                  color: _greenTxt, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      );
    }

    return GestureDetector(
      onTap: _openDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _amberBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _amberBdr, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: _amber.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _amberBdr)),
            child: const Icon(Icons.lock_rounded, color: _amber, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Worker has arrived! 🎉',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _amberTxt)),
              SizedBox(height: 4),
              Text('Ask worker for the 4-digit OTP\nand tap here to enter it',
                  style:
                      TextStyle(fontSize: 12, color: _amberTxt, height: 1.4)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: _amber, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.keyboard_rounded,
                color: Colors.white, size: 18),
          ),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  GENERATE COMPLETION OTP CARD
// ═════════════════════════════════════════════════════════════════════════════
class _GenerateCompletionOtpCard extends StatelessWidget {
  final VoidCallback onGenerate;
  const _GenerateCompletionOtpCard({required this.onGenerate});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onGenerate,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _green.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.task_alt_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Work finished?',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    SizedBox(height: 4),
                    Text(
                        'Tap to generate a completion OTP.\nShare it with the worker to confirm.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white70, height: 1.4)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ),
          ]),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
//  COMPLETION OTP DISPLAY CARD
// ═════════════════════════════════════════════════════════════════════════════
class _CompletionOtpDisplayCard extends StatelessWidget {
  final String otp;
  final bool otpVerified;
  const _CompletionOtpDisplayCard(
      {required this.otp, required this.otpVerified});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: otpVerified ? _greenBg : _amberBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: otpVerified ? _greenBdr : _amberBdr, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: (otpVerified ? _green : _amber).withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(children: [
          Row(children: [
            Icon(otpVerified ? Icons.verified_rounded : Icons.password_rounded,
                color: otpVerified ? _green : _amber, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                otpVerified
                    ? 'Completion OTP verified ✓'
                    : 'Show this OTP to the worker',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: otpVerified ? _greenTxt : _amberTxt),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            otpVerified
                ? 'Worker confirmed the job is complete.'
                : 'Worker enters this OTP on their screen to confirm the job is done.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: otpVerified ? _greenTxt : _amberTxt),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: otp
                .split('')
                .map((digit) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 62,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: otpVerified ? _greenBdr : _amberBdr,
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: (otpVerified ? _green : _amber)
                                  .withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Center(
                        child: Text(digit,
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: otpVerified ? _green : _txtDark)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          if (!otpVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                  color: _amberBdr.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _amber)),
                SizedBox(width: 10),
                Text('Waiting for worker to verify…',
                    style: TextStyle(
                        fontSize: 12,
                        color: _amberTxt,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
//  VERIFIED BADGE
// ═════════════════════════════════════════════════════════════════════════════
class _VerifiedBadge extends StatelessWidget {
  final IconData icon;
  final Color color, bg, border;
  final String text;
  const _VerifiedBadge({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border)),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: _greenTxt, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
//  JOB SUMMARY
// ═════════════════════════════════════════════════════════════════════════════
class _JobSummary extends StatelessWidget {
  final Map<String, dynamic> data;
  const _JobSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    final promoDisc = (data['promoDiscount'] as num?)?.toDouble() ?? 0;
    final goldDisc = (data['goldDiscount'] as num?)?.toDouble() ?? 0;
    final isPaid = data['isPaid'] == true;
    final isCash = data['paymentMethod'] == 'COD';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.receipt_long_outlined, color: _cyan, size: 14),
          SizedBox(width: 6),
          Text('ORDER SUMMARY',
              style: TextStyle(
                  color: _cyan,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
        ]),
        const Divider(color: _border, height: 18),
        if (data['category'] != null) _r('Service', data['category'] as String),
        if (data['subCategory'] != null)
          _r('Type', data['subCategory'] as String),
        if (data['address'] != null) _r('Location', data['address'] as String),
        if (data['scheduledDate'] != null)
          _r('Date', data['scheduledDate'] as String),
        if (data['scheduledTime'] != null)
          _r('Time', data['scheduledTime'] as String),
        const Divider(color: _border, height: 16),
        _r('Service charge', '₹${data['basePrice'] ?? 0}'),
        _r('Platform fee', '₹${data['platformFee'] ?? 0}'),
        if (promoDisc > 0) _r('Promo discount', '−₹$promoDisc', vc: _green),
        if (goldDisc > 0) _r('Gold discount', '−₹$goldDisc', vc: _amber),
        const Divider(color: _border, height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _txtDark)),
          Text('₹${data['total'] ?? 0}',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: _cyan)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border)),
          child: Row(children: [
            Icon(isCash ? Icons.money_rounded : Icons.credit_card_rounded,
                size: 15, color: isPaid ? _green : _amber),
            const SizedBox(width: 8),
            Text(
              isCash
                  ? 'Cash on delivery'
                  : (isPaid ? 'Paid online ✓' : 'Online — pending'),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPaid ? _green : _amber),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _r(String label, String value, {Color? vc}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: _txtMuted, fontSize: 13)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: vc ?? _txtDark)),
          ),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
//  RATING CARD
// ═════════════════════════════════════════════════════════════════════════════
class _RatingCard extends StatefulWidget {
  final String requestId, workerId, workerName, userId, userName;
  const _RatingCard({
    required this.requestId,
    required this.workerId,
    required this.workerName,
    required this.userId,
    required this.userName,
  });
  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  int _stars = 0;
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a star rating.'),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      // 1. Write review document
      await FirebaseFirestore.instance.collection('reviews').add({
        'requestId': widget.requestId,
        'workerId': widget.workerId,
        'workerName': widget.workerName,
        'userId': widget.userId,
        'userName': widget.userName,
        'rating': _stars,
        'comment': _ctrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;

      // 2. Update worker's average rating.
      //    NOTE: totalJobs was already incremented by job_request_screen at
      //    completion time — do NOT increment it again here.
      final wRef =
          FirebaseFirestore.instance.collection('workers').doc(widget.workerId);
      final wDoc = await wRef.get();
      if (!mounted) return;
      final wData = wDoc.data() ?? {};
      final oldRating = (wData['rating'] as num?)?.toDouble() ?? 0.0;
      final totalJobs = (wData['totalJobs'] as num?)?.toInt() ?? 1;
      // Recalculate using the already-incremented totalJobs
      final newRating = totalJobs > 0
          ? ((oldRating * (totalJobs - 1)) + _stars) / totalJobs
          : _stars.toDouble();
      await wRef.update({'rating': newRating});
      if (!mounted) return;

      // 3. Mark request as rated
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({'isRated': true});
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rating submitted — thank you!'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _amberBdr)),
        child: Column(children: [
          const Icon(Icons.star_rounded, color: _amber, size: 32),
          const SizedBox(height: 8),
          const Text('Rate your experience',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _txtDark)),
          const SizedBox(height: 4),
          Text('How was your service with ${widget.workerName}?',
              style: const TextStyle(color: _txtMuted, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                5,
                (i) => GestureDetector(
                      onTap: () => setState(() => _stars = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < _stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: _amber,
                          size: 38,
                        ),
                      ),
                    )),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            style: const TextStyle(color: _txtDark, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Leave a comment (optional)...',
              hintStyle: const TextStyle(color: _txtMuted, fontSize: 13),
              filled: true,
              fillColor: _surface,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _cyan, width: 1.2)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                disabledBackgroundColor: _amber.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit rating',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
            ),
          ),
        ]),
      );
}
