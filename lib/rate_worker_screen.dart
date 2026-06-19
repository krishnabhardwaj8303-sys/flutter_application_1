import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
//  THEME
// ─────────────────────────────────────────────
class _C {
  static const cyan = Color(0xFF00BCD4);
  static const cyanDark = Color(0xFF0097A7);
  static const cyanDeep = Color(0xFF006064);
  static const cyanLight = Color(0xFFE0F7FA);
  static const bg = Color(0xFFF4FCFD);
  static const dark = Color(0xFF0D1B1E);
  static const gold = Color(0xFFFFB300);
}

// ─────────────────────────────────────────────
//  RATE WORKER SCREEN
// ─────────────────────────────────────────────
class RateWorkerScreen extends StatefulWidget {
  final String bookingId;
  final String requestId;
  final String workerId;
  final String workerName;
  final String workerJob;
  final double amountPaid;
  final String serviceDate;
  final String? workerImage;

  const RateWorkerScreen({
    super.key,
    required this.bookingId,
    required this.requestId,
    required this.workerId,
    required this.workerName,
    required this.workerJob,
    required this.amountPaid,
    required this.serviceDate,
    this.workerImage,
  });

  @override
  State<RateWorkerScreen> createState() => _RateWorkerScreenState();
}

class _RateWorkerScreenState extends State<RateWorkerScreen>
    with TickerProviderStateMixin {
  int _rating = 0;
  int _hoveredStar = 0;
  final _reviewCtrl = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  // Aspect ratings (optional quick feedback)
  final Map<String, bool> _aspects = {
    '😊 Friendly': false,
    '⚡ Fast': false,
    '🎯 Professional': false,
    '🧹 Neat & Clean': false,
    '💰 Good Value': false,
    '⏰ On Time': false,
  };

  late AnimationController _successCtrl;
  late Animation<double> _successScale;
  late Animation<double> _successFade;
  late AnimationController _starCtrl;

  @override
  void initState() {
    super.initState();

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );
    _successFade = CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn);

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    _successCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  // ── Submit review ──────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_rating == 0) {
      _snack('Please give at least 1 star ⭐');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final review = _reviewCtrl.text.trim();
      final selectedAspects =
          _aspects.entries.where((e) => e.value).map((e) => e.key).toList();

      final batch = FirebaseFirestore.instance.batch();

      // 1. Save review to reviews collection
      final reviewRef = FirebaseFirestore.instance.collection('reviews').doc();
      batch.set(reviewRef, {
        'bookingId': widget.bookingId,
        'requestId': widget.requestId,
        'workerId': widget.workerId,
        'customerId': uid,
        'rating': _rating,
        'review': review,
        'aspects': selectedAspects,
        'workerName': widget.workerName,
        'workerJob': widget.workerJob,
        'serviceDate': widget.serviceDate,
        'amountPaid': widget.amountPaid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Mark booking as rated
      final bookingRef = FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId);
      batch.update(bookingRef, {
        'isRated': true,
        'customerRating': _rating,
        'customerReview': review,
      });

      // 3. Update worker's avg rating
      final workerRef =
          FirebaseFirestore.instance.collection('users').doc(widget.workerId);
      batch.update(workerRef, {
        'totalRatings': FieldValue.increment(1),
        'ratingSum': FieldValue.increment(_rating),
      });

      await batch.commit();

      // 4. Recalculate avg rating
      final workerSnap = await workerRef.get();
      if (workerSnap.exists) {
        final d = workerSnap.data()!;
        final sum = (d['ratingSum'] ?? 0) as num;
        final count = (d['totalRatings'] ?? 1) as num;
        await workerRef.update({
          'avgRating': (sum / count).toStringAsFixed(1),
        });
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
      _successCtrl.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Failed to submit. Please try again.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _C.cyanDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return '😞  Poor';
      case 2:
        return '😐  Fair';
      case 3:
        return '🙂  Good';
      case 4:
        return '😊  Great';
      case 5:
        return '🤩  Excellent!';
      default:
        return 'Tap to rate';
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.cyanDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Rate Your Experience',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  // ─────────────────────────────────────────────
  //  SUCCESS STATE
  // ─────────────────────────────────────────────
  Widget _buildSuccess() {
    return FadeTransition(
      opacity: _successFade,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _successScale,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 60, color: Colors.green),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Thank You! 🎉',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _C.dark)),
              const SizedBox(height: 10),
              Text(
                'Your feedback helps us improve\nand rewards great workers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600, height: 1.6),
              ),
              const SizedBox(height: 16),
              // Stars display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: _C.gold,
                    size: 32,
                  );
                }),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Back to Bookings',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FORM
  // ─────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Gradient header ───────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF006064), Color(0xFF00BCD4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              children: [
                // Worker avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: widget.workerImage != null &&
                          widget.workerImage!.isNotEmpty
                      ? NetworkImage(widget.workerImage!)
                      : null,
                  child:
                      widget.workerImage == null || widget.workerImage!.isEmpty
                          ? const Icon(Icons.person_rounded,
                              size: 40, color: _C.cyanDark)
                          : null,
                ),
                const SizedBox(height: 12),
                Text(widget.workerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(widget.workerJob,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 13)),
                const SizedBox(height: 16),
                // Service info chips
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(Icons.calendar_today_rounded, widget.serviceDate),
                    _chip(Icons.currency_rupee_rounded,
                        '₹${widget.amountPaid.toStringAsFixed(0)} paid'),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Star rating ──────────────────────────────────────
                _card(
                  child: Column(
                    children: [
                      const Text('How was the service?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _C.dark)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final star = i + 1;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _rating = star);
                            },
                            onPanUpdate: (details) {
                              final box =
                                  context.findRenderObject() as RenderBox?;
                              if (box == null) return;
                              final local =
                                  box.globalToLocal(details.globalPosition);
                              final starWidth = box.size.width / 5;
                              final s =
                                  (local.dx / starWidth).ceil().clamp(1, 5);
                              if (s != _rating) {
                                HapticFeedback.selectionClick();
                                setState(() => _rating = s);
                              }
                            },
                            child: AnimatedScale(
                              scale: _rating >= star ? 1.2 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  _rating >= star
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: _rating >= star
                                      ? _C.gold
                                      : Colors.grey.shade300,
                                  size: 44,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _ratingLabel,
                          key: ValueKey(_rating),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _rating >= 4
                                ? _C.cyanDark
                                : _rating >= 3
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Aspect chips ─────────────────────────────────────
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('What went well?',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _C.dark)),
                      const SizedBox(height: 3),
                      Text('Select all that apply',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _aspects.keys.map((label) {
                          final sel = _aspects[label]!;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(
                                  () => _aspects[label] = !_aspects[label]!);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? _C.cyanLight : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel ? _C.cyan : Colors.grey.shade300,
                                  width: sel ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? _C.cyanDark : _C.dark,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Written review ───────────────────────────────────
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Write a review (optional)',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _C.dark)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reviewCtrl,
                        maxLines: 4,
                        maxLength: 300,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Share your experience with this worker…',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                          filled: true,
                          fillColor: _C.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: _C.cyan, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Submit button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.cyan,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Submit Review',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
