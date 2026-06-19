import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// THEME COLORS
// ─────────────────────────────────────────────
class _C {
  static const cyan = Color(0xFF00BCD4);
  static const cyanDark = Color(0xFF0097A7);
  static const cyanDeep = Color(0xFF006064);
  static const cyanLight = Color(0xFFE0F7FA);

  static const bg = Color(0xFFF4FCFD);
  static const dark = Color(0xFF102027);
  static const muted = Color(0xFF607D8B);
}

// ─────────────────────────────────────────────
// NOTIFICATION TYPE CONFIG
// ─────────────────────────────────────────────
class _NType {
  final IconData icon;
  final Color color;
  final Color bg;

  const _NType(this.icon, this.color, this.bg);
}

const _typeMap = <String, _NType>{
  'booking': _NType(
    Icons.calendar_today_rounded,
    Color(0xFF0097A7),
    Color(0xFFE0F7FA),
  ),
  'worker': _NType(
    Icons.person_rounded,
    Color(0xFF1565C0),
    Color(0xFFE3F2FD),
  ),
  'payment': _NType(
    Icons.payment_rounded,
    Color(0xFF2E7D32),
    Color(0xFFE8F5E9),
  ),
  'promo': _NType(
    Icons.local_offer_rounded,
    Color(0xFFF57F17),
    Color(0xFFFFF8E1),
  ),
  'completed': _NType(
    Icons.check_circle_rounded,
    Color(0xFF2E7D32),
    Color(0xFFE8F5E9),
  ),
  'cancelled': _NType(
    Icons.cancel_rounded,
    Color(0xFFC62828),
    Color(0xFFFFEBEE),
  ),
  'rating': _NType(
    Icons.star_rounded,
    Color(0xFFF9A825),
    Color(0xFFFFF8E1),
  ),
  'system': _NType(
    Icons.notifications_rounded,
    Color(0xFF6A1B9A),
    Color(0xFFF3E5F5),
  ),
};

_NType _resolveType(String? type) {
  return _typeMap[type] ?? _typeMap['system']!;
}

// ─────────────────────────────────────────────
// NOTIFICATION SCREEN
// ─────────────────────────────────────────────
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _headerCtrl,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllRead();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  // ───────────────── MARK ALL READ ─────────────────
  Future<void> _markAllRead() async {
    if (_uid == null) return;

    try {
      final unread = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (unread.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in unread.docs) {
        batch.update(doc.reference, {
          'isRead': true,
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Mark read error: $e");
    }
  }

  // ───────────────── DELETE SINGLE ─────────────────
  Future<void> _deleteNotification(String docId) async {
    if (_uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(docId)
          .delete();

      _showSnack("Notification deleted");
    } catch (e) {
      _showSnack("Failed to delete");
    }
  }

  // ───────────────── CLEAR ALL ─────────────────
  Future<void> _clearAll(List<QueryDocumentSnapshot> docs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Clear All Notifications?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Clear All",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || _uid == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      _showSnack("All notifications cleared");
    } catch (e) {
      _showSnack("Failed to clear notifications");
    }
  }

  // ───────────────── SNACKBAR ─────────────────
  void _showSnack(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _C.cyanDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ───────────────── TIME AGO ─────────────────
  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';

    final dt = ts.toDate();
    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat('d MMM').format(dt);
  }

  // ───────────────── GROUP BY DATE ─────────────────
  Map<String, List<QueryDocumentSnapshot>> _groupNotifications(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final ts = data['createdAt'] as Timestamp?;

      final label = ts == null
          ? 'Earlier'
          : _dateLabel(
              ts.toDate(),
            );

      grouped.putIfAbsent(label, () => []).add(doc);
    }

    return grouped;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }

    final yesterday = now.subtract(const Duration(days: 1));

    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }

    return DateFormat('d MMM yyyy').format(dt);
  }

  // ───────────────── BUILD ─────────────────
  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(
          child: Text("Please login first"),
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          final docs =
              snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot>[];

          final grouped = _groupNotifications(docs);

          return NestedScrollView(
            headerSliverBuilder: (_, __) {
              return [
                _buildSliverAppBar(docs),
              ];
            },
            body: snap.connectionState == ConnectionState.waiting
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _C.cyan,
                    ),
                  )
                : docs.isEmpty
                    ? _buildEmpty()
                    : _buildNotificationList(grouped),
          );
        },
      ),
    );
  }

  // ───────────────── APP BAR ─────────────────
  Widget _buildSliverAppBar(List<QueryDocumentSnapshot> docs) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
      backgroundColor: _C.cyanDeep,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (docs.isNotEmpty)
          TextButton(
            onPressed: () => _clearAll(docs),
            child: const Text(
              "Clear All",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF006064),
                Color(0xFF00BCD4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 45, 20, 0),
              child: FadeTransition(
                opacity: _headerFade,
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Notifications",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Stay updated with activity",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── EMPTY STATE ─────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: _C.cyanLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                color: _C.cyanDark,
                size: 50,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              "No Notifications Yet",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: _C.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You'll see updates, bookings,\npayments and alerts here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── LIST ─────────────────
  Widget _buildNotificationList(
    Map<String, List<QueryDocumentSnapshot>> grouped,
  ) {
    final groups = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: groups.length,
      itemBuilder: (_, index) {
        final group = groups[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                group.key,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            ...group.value.asMap().entries.map((e) {
              return _buildCard(
                e.value,
                e.key,
              );
            }),
          ],
        );
      },
    );
  }

  // ───────────────── CARD ─────────────────
  Widget _buildCard(QueryDocumentSnapshot doc, int index) {
    final data = doc.data() as Map<String, dynamic>;

    final title = data['title'] ?? 'Notification';
    final body = data['body'] ?? '';
    final type = data['type'];
    final isRead = data['isRead'] == true;
    final ts = data['createdAt'] as Timestamp?;

    final nt = _resolveType(type);

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => _deleteNotification(doc.id),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 300 + (index * 60)),
        curve: Curves.easeOut,
        builder: (_, value, child) {
          return Opacity(
            opacity: value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : _C.cyanLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isRead ? Colors.grey.shade200 : _C.cyan.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: nt.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                nt.icon,
                color: nt.color,
                size: 24,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                fontSize: 14,
                color: _C.dark,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (body.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _timeAgo(ts),
                  style: const TextStyle(
                    color: _C.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: !isRead
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: _C.cyan,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
            onTap: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_uid)
                    .collection('notifications')
                    .doc(doc.id)
                    .update({
                  'isRead': true,
                });
              } catch (_) {}
            },
          ),
        ),
      ),
    );
  }
}
