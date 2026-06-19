import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ── Theme colors (matches your app) ─────────────────────────
const Color kPrimaryCyan = Color(0xFF06B6D4);
const Color kCyanLight = Color(0xFF22D3EE);
const Color kCyanDark = Color(0xFF0891B2);
const Color kBgDark = Color(0xFF020F14);
const Color kBgCard = Color(0xFF062330);
const Color kBgSurface = Color(0xFF083040);
const Color kTextLight = Color(0xFFE0F7FC);
const Color kTextMuted = Color(0xFF7BAABF);

class AdminWorkerRequests extends StatelessWidget {
  const AdminWorkerRequests({super.key});

  // ── Same logic you already had ───────────────────────────
  Future<void> approveWorker(BuildContext context, String uid) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "verificationStatus": "approved",
      "isVerified": true,
      "canLogin": true,
      "reviewedAt": FieldValue.serverTimestamp(),
    });
    if (context.mounted)
      _snack(context, "✅ Worker approved!", Colors.green.shade700);
  }

  Future<void> rejectWorker(BuildContext context, String uid) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "verificationStatus": "rejected",
      "isVerified": false,
      "canLogin": false,
      "reviewedAt": FieldValue.serverTimestamp(),
    });
    if (context.mounted)
      _snack(context, "❌ Worker rejected", Colors.red.shade700);
  }

  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,

      // ── App Bar ─────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: kBgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: kTextLight, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(children: [
          Icon(Icons.verified_user_rounded, color: kPrimaryCyan, size: 20),
          SizedBox(width: 10),
          Text(
            "Worker Verifications",
            style: TextStyle(
                color: kTextLight, fontWeight: FontWeight.w700, fontSize: 17),
          ),
        ]),
      ),

      // ── Tabs: Pending / Approved / Rejected ─────────────
      body: DefaultTabController(
        length: 3,
        child: Column(children: [
          Container(
            color: kBgCard,
            child: const TabBar(
              indicatorColor: kPrimaryCyan,
              indicatorWeight: 3,
              labelColor: kPrimaryCyan,
              unselectedLabelColor: kTextMuted,
              labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: "Pending"),
                Tab(text: "Approved"),
                Tab(text: "Rejected"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(children: [
              _WorkerList(status: "pending", parent: this),
              _WorkerList(status: "approved", parent: this),
              _WorkerList(status: "rejected", parent: this),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── List per tab ─────────────────────────────────────────────
class _WorkerList extends StatelessWidget {
  final String status;
  final AdminWorkerRequests parent;
  const _WorkerList({required this.status, required this.parent});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .where("role", isEqualTo: "worker")
          .where("verificationStatus", isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: kPrimaryCyan));
        }

        final workers = snapshot.data!.docs;

        if (workers.isEmpty) {
          return Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                status == "pending"
                    ? Icons.hourglass_empty_rounded
                    : status == "approved"
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                color: kTextMuted,
                size: 60,
              ),
              const SizedBox(height: 14),
              Text("No $status workers",
                  style: const TextStyle(color: kTextMuted, fontSize: 15)),
            ]),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workers.length,
          itemBuilder: (context, index) {
            final doc = workers[index];
            final data = doc.data() as Map<String, dynamic>;
            return _WorkerCard(
              uid: doc.id,
              data: data,
              status: status,
              parent: parent,
            );
          },
        );
      },
    );
  }
}

// ── Worker card ──────────────────────────────────────────────
class _WorkerCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final String status;
  final AdminWorkerRequests parent;

  const _WorkerCard({
    required this.uid,
    required this.data,
    required this.status,
    required this.parent,
  });

  @override
  Widget build(BuildContext context) {
    final profileImg = data["profileImage"] ?? "";
    final aadhaarImg = data["aadhaarImage"] ?? "";
    final selfieImg = data["faceVerificationImage"] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryCyan.withOpacity(0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Profile row ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Profile photo
            CircleAvatar(
              radius: 30,
              backgroundColor: kBgSurface,
              backgroundImage:
                  profileImg.isNotEmpty ? NetworkImage(profileImg) : null,
              child: profileImg.isEmpty
                  ? const Icon(Icons.person, color: kPrimaryCyan, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data["name"] ?? "",
                        style: const TextStyle(
                            color: kTextLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      "${data["service"] ?? ""} · ${data["experience"] ?? "0"} yrs exp",
                      style: const TextStyle(color: kPrimaryCyan, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(data["phone"] ?? "",
                        style:
                            const TextStyle(color: kTextMuted, fontSize: 12)),
                  ]),
            ),
            // Status badge
            _StatusBadge(status: status),
          ]),
        ),

        // ── Address & bio ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("📍 ${data["address"] ?? "No address"}",
              style: const TextStyle(color: kTextMuted, fontSize: 12)),
        ),
        if ((data["bio"] ?? "").isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text("💬 ${data["bio"]}",
                style: const TextStyle(color: kTextMuted, fontSize: 12)),
          ),
        ],
        const SizedBox(height: 14),

        // ── Documents ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: _DocThumb(label: "Aadhaar Card", url: aadhaarImg)),
            const SizedBox(width: 10),
            Expanded(child: _DocThumb(label: "Live Selfie", url: selfieImg)),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Approve / Reject (pending only) ──────────────
        if (status == "pending")
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => parent.approveWorker(context, uid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
                  label: const Text("Approve",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => parent.rejectWorker(context, uid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                  label: const Text("Reject",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ]),
          ),

        // ── Approve anyway (rejected tab) ────────────────
        if (status == "rejected")
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => parent.approveWorker(context, uid),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryCyan,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.redo_rounded,
                    color: Colors.white, size: 18),
                label: const Text("Approve Now",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Document thumbnail ───────────────────────────────────────
class _DocThumb extends StatelessWidget {
  final String label;
  final String url;
  const _DocThumb({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: kTextMuted, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      GestureDetector(
        // Tap to view full image
        onTap:
            url.isNotEmpty ? () => _showFullImage(context, label, url) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 100,
                          color: kBgSurface,
                          child: const Center(
                              child: CircularProgressIndicator(
                                  color: kPrimaryCyan, strokeWidth: 2))),
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
      ),
    ]);
  }

  Widget _placeholder() {
    return Container(
      height: 100,
      color: kBgSurface,
      child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: kTextMuted, size: 28)),
    );
  }

  void _showFullImage(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title,
                style: const TextStyle(
                    color: kTextLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ]),
      ),
    );
  }
}

// ── Status badge ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == "approved"
        ? Colors.green
        : status == "rejected"
            ? Colors.red
            : Colors.orange;

    final label = status == "approved"
        ? "✓ APPROVED"
        : status == "rejected"
            ? "✗ REJECTED"
            : "⏳ PENDING";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
