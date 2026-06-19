import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'tracking_screen.dart';

const Color _cyan = Color(0xFF00BCD4);
const Color _cyanBg = Color(0xFFE0F7FA);
const Color _error = Color(0xFFF44336);
const Color _bg = Color(0xFFF5FAFE);
const Color _card = Color(0xFFFFFFFF);
const Color _border = Color(0xFFD4ECF5);
const Color _txtDark = Color(0xFF0D2B35);
const Color _txtMuted = Color(0xFF6B9BAD);

/// Shown to user after instant booking while waiting for a worker.
/// Watches Firestore status and auto-navigates to TrackingScreen
/// the moment a worker accepts (status != 'pending' and != 'cancelled').
class SearchingScreen extends StatelessWidget {
  final String requestId;
  const SearchingScreen({super.key, required this.requestId});

  Future<void> _cancelRequest(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Cancel Request?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text('Are you sure you want to cancel this service request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _error,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .snapshots(),
      builder: (context, snap) {
        // Loading
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(child: CircularProgressIndicator(color: _cyan)),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final status = data['status'] as String? ?? 'pending';

        // Auto-navigate when worker accepts
        if (status != 'pending' &&
            status != 'waiting' &&
            status != 'cancelled') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackingScreen(
                    requestId: requestId,
                    workerId: data['workerId'] as String? ?? '',
                    workerName: data['workerName'] as String? ?? '',
                  ),
                ),
              );
            }
          });
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(child: CircularProgressIndicator(color: _cyan)),
          );
        }

        // Cancelled state
        if (status == 'cancelled') {
          return Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                  child:
                      const Icon(Icons.cancel_rounded, color: _error, size: 48),
                ),
                const SizedBox(height: 20),
                const Text('Request Cancelled',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _txtDark)),
                const SizedBox(height: 8),
                const Text('Your booking has been cancelled.',
                    style: TextStyle(color: _txtMuted, fontSize: 14)),
                const SizedBox(height: 28),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _cyan,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          );
        }

        // Searching state (pending / waiting)
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _cancelRequest(context);
          },
          child: Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── Animated pulsing icon ──────────────────────────────
                    const _PulsingCircle(),
                    const SizedBox(height: 36),

                    // ── Title ──────────────────────────────────────────────
                    const Text(
                      'Finding Your Worker...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _txtDark),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'We\'re notifying nearby professionals.\nThis usually takes less than a minute.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _txtMuted, fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 32),

                    // ── Live status steps ──────────────────────────────────
                    const _SearchingSteps(),
                    const SizedBox(height: 28),

                    // ── Service summary ────────────────────────────────────
                    _ServiceSummaryCard(data: data),
                    const SizedBox(height: 32),

                    // ── Cancel button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelRequest(context),
                        icon: const Icon(Icons.close_rounded,
                            color: _error, size: 18),
                        label: const Text('Cancel Request',
                            style: TextStyle(
                                color: _error, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _error.withOpacity(0.6)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _error.withOpacity(0.05),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cancellation is free before a worker is assigned.',
                      style: TextStyle(fontSize: 11, color: _txtMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PULSING CIRCLE ANIMATION
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingCircle extends StatefulWidget {
  const _PulsingCircle();

  @override
  State<_PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _scale = Tween(begin: 1.0, end: 1.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween(begin: 0.45, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(alignment: Alignment.center, children: [
        // Outer pulse ring
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _cyan, width: 3),
                ),
              ),
            ),
          ),
        ),
        // Second pulse ring (offset phase)
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = (_ctrl.value + 0.4) % 1.0;
            final s = 1.0 + t * 0.7;
            final o = (0.45 * (1 - t)).clamp(0.0, 1.0);
            return Transform.scale(
              scale: s,
              child: Opacity(
                opacity: o,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _cyan.withOpacity(0.6), width: 2),
                  ),
                ),
              ),
            );
          },
        ),
        // Center circle
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: _cyanBg,
            shape: BoxShape.circle,
            border: Border.all(color: _cyan, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: _cyan.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 2),
            ],
          ),
          child: const Icon(Icons.search_rounded, color: _cyan, size: 42),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SEARCHING STEPS  (animated progress steps)
// ─────────────────────────────────────────────────────────────────────────────
class _SearchingSteps extends StatefulWidget {
  const _SearchingSteps();

  @override
  State<_SearchingSteps> createState() => _SearchingStepsState();
}

class _SearchingStepsState extends State<_SearchingSteps> {
  int _activeStep = 0;

  static const _steps = [
    {'icon': Icons.receipt_long_rounded, 'label': 'Booking confirmed'},
    {'icon': Icons.wifi_tethering_rounded, 'label': 'Notifying nearby workers'},
    {'icon': Icons.person_search_rounded, 'label': 'Finding best match'},
    {'icon': Icons.handshake_rounded, 'label': 'Waiting for acceptance'},
  ];

  @override
  void initState() {
    super.initState();
    // Animate through steps every 2 seconds to give user feedback
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
      setState(() {
        _activeStep = (_activeStep + 1) % _steps.length;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: List.generate(_steps.length, (i) {
          final done = i < _activeStep;
          final active = i == _activeStep;
          final isLast = i == _steps.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: active ? 34 : 26,
                  height: active ? 34 : 26,
                  decoration: BoxDecoration(
                    color: done
                        ? _cyan
                        : active
                            ? _cyanBg
                            : const Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: done || active ? _cyan : Colors.grey.shade300,
                      width: active ? 2 : 1.5,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: _cyan.withOpacity(0.3), blurRadius: 8)
                          ]
                        : [],
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : _steps[i]['icon'] as IconData,
                    color: done
                        ? Colors.white
                        : active
                            ? _cyan
                            : Colors.grey.shade400,
                    size: active ? 17 : 13,
                  ),
                ),
                if (!isLast)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 2,
                    height: 24,
                    color: done ? _cyan : Colors.grey.shade200,
                  ),
              ]),
              const SizedBox(width: 14),
              Padding(
                padding: EdgeInsets.only(
                    top: active ? 7 : 4, bottom: isLast ? 0 : 14),
                child: Text(
                  _steps[i]['label'] as String,
                  style: TextStyle(
                    fontSize: active ? 13.5 : 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: done
                        ? _cyan
                        : active
                            ? _txtDark
                            : _txtMuted,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SERVICE SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceSummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ServiceSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final address =
        data['address'] as String? ?? data['location'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: _cyanBg, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.home_repair_service_rounded,
                color: _cyan, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['category'] as String? ?? 'Service',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _txtDark)),
              const SizedBox(height: 2),
              Text(data['subCategory'] as String? ?? '',
                  style: const TextStyle(color: _txtMuted, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${data['total'] ?? 0}',
                style: const TextStyle(
                    color: _cyan, fontWeight: FontWeight.bold, fontSize: 17)),
            const Text('Total',
                style: TextStyle(color: _txtMuted, fontSize: 11)),
          ]),
        ]),
        if (address.isNotEmpty) ...[
          const Divider(height: 20, color: Color(0xFFEEEEEE)),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.location_on_rounded, color: _cyan, size: 16),
            const SizedBox(width: 6),
            Expanded(
                child: Text(address,
                    style: const TextStyle(
                        color: _txtMuted, fontSize: 12, height: 1.4))),
          ]),
        ],
        if (data['isScheduled'] == true &&
            (data['scheduledDate'] != null ||
                data['scheduledTime'] != null)) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today_rounded, color: _cyan, size: 14),
            const SizedBox(width: 6),
            Text(
              '${data['scheduledDate'] ?? ''} at ${data['scheduledTime'] ?? ''}',
              style: const TextStyle(color: _txtMuted, fontSize: 12),
            ),
          ]),
        ],
      ]),
    );
  }
}
