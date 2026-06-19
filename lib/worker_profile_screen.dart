import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color _cyan = Color(0xFF06B6D4);
const Color _bgDark = Color(0xFF020F14);
const Color _bgCard = Color(0xFF062330);
const Color _bgSurface = Color(0xFF083040);
const Color _textLight = Color(0xFFE0F7FC);
const Color _textMuted = Color(0xFF7BAABF);
const Color _success = Color(0xFF00E676);
const Color _warning = Color(0xFFFFB300);

class WorkerProfileScreen extends StatelessWidget {
  final String? uid;
  final bool isEditable;

  const WorkerProfileScreen({
    super.key,
    required this.uid,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        backgroundColor: _bgDark,
        body: Center(
            child:
                Text('Worker not found', style: TextStyle(color: _textLight))),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('workers').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: _bgDark,
            body: Center(child: CircularProgressIndicator(color: _cyan)),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        return _ProfileBody(data: data, uid: uid!, isEditable: isEditable);
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final String uid;
  final bool isEditable;

  const _ProfileBody(
      {required this.data, required this.uid, required this.isEditable});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Worker';
    final image = data['profileImage'] ?? '';
    final phone = data['phone'] ?? '';
    final categories = (data['category'] as List?)?.join(', ') ?? 'Service';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final totalJobs = data['totalJobs'] ?? 0;
    final isOnline = data['isOnline'] ?? false;
    final bio = data['bio'] ?? 'Professional service provider.';
    final experience = data['experience'] ?? '1+ years';
    final city = data['city'] ?? '';

    return Scaffold(
      backgroundColor: _bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _bgCard,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _textLight, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF062330), _bgDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Column(children: [
                      Stack(children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isOnline ? _success : _textMuted,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: image.isNotEmpty
                                ? Image.network(image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        color: _cyan,
                                        size: 40))
                                : const Icon(Icons.person,
                                    color: _cyan, size: 40),
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            bottom: 3,
                            right: 3,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _success,
                                shape: BoxShape.circle,
                                border: Border.all(color: _bgCard, width: 2),
                              ),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 10),
                      Text(name,
                          style: const TextStyle(
                              color: _textLight,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(categories,
                          style: const TextStyle(
                              color: _cyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats
                Row(children: [
                  Expanded(
                      child: _StatCard(
                          label: 'Rating',
                          value: rating.toStringAsFixed(1),
                          icon: Icons.star_rounded,
                          color: _warning)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatCard(
                          label: 'Jobs Done',
                          value: '$totalJobs',
                          icon: Icons.check_circle_rounded,
                          color: _success)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatCard(
                          label: 'Status',
                          value: isOnline ? 'Online' : 'Offline',
                          icon: isOnline
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          color: isOnline ? _success : _textMuted)),
                ]),
                const SizedBox(height: 20),

                // About
                _InfoCard(
                  title: 'About',
                  children: [
                    _InfoRow(icon: Icons.info_outline, label: bio),
                    if (experience.isNotEmpty)
                      _InfoRow(
                          icon: Icons.work_outline,
                          label: '$experience experience'),
                    if (city.isNotEmpty)
                      _InfoRow(icon: Icons.location_on_outlined, label: city),
                    if (phone.isNotEmpty)
                      _InfoRow(icon: Icons.phone_outlined, label: phone),
                  ],
                ),
                const SizedBox(height: 16),

                // Services
                _InfoCard(
                  title: 'Services Offered',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ((data['category'] as List?) ?? [])
                          .map((cat) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _cyan.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: _cyan.withOpacity(0.3)),
                                ),
                                child: Text(cat.toString(),
                                    style: const TextStyle(
                                        color: _cyan,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recent Reviews
                _buildReviews(uid),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(String workerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('workerId', isEqualTo: workerId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        final reviews = snap.data?.docs ?? [];
        if (reviews.isEmpty) {
          return _InfoCard(
            title: 'Reviews',
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No reviews yet',
                      style: TextStyle(color: _textMuted, fontSize: 13)),
                ),
              ),
            ],
          );
        }

        return _InfoCard(
          title: 'Reviews',
          children: reviews.map((doc) {
            final r = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.person_outline,
                          color: _textMuted, size: 16),
                      const SizedBox(width: 6),
                      Text(r['userName'] ?? 'Customer',
                          style: const TextStyle(
                              color: _textLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      ...List.generate(
                          (r['rating'] as num?)?.toInt() ?? 0,
                          (_) => const Icon(Icons.star_rounded,
                              color: _warning, size: 14)),
                    ]),
                    const SizedBox(height: 4),
                    Text(r['comment'] ?? '',
                        style: const TextStyle(
                            color: _textMuted, fontSize: 12, height: 1.5)),
                    const Divider(color: Color(0xFF0E3A50), height: 16),
                  ]),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 11)),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF0E3A50)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: _cyan, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: _cyan, size: 16),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: _textLight, fontSize: 13, height: 1.4))),
      ]),
    );
  }
}
