import 'package:flutter/material.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // ─────────────────────────────────────────────
  // 🎨 CYAN THEME
  // ─────────────────────────────────────────────
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _darkCyan = Color(0xFF0891B2);
  static const Color _lightCyan = Color(0xFFECFEFF);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // 📦 CARD
  // ─────────────────────────────────────────────
  Widget buildCard(String title, String content, IconData icon) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shadowColor: _cyan.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _lightCyan,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: _cyan,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),

                // TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🏗️ UI
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFD),

      // ───────────────── APP BAR ─────────────────
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _cyan,
        title: const Text(
          "Safety & Support",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      // ───────────────── BODY ─────────────────
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TITLE
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              "Contact Ajoomi Support",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // DESCRIPTION
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              "Whether you have a question about a booking, need help with a payment, or want to join our team as a professional, we are here to help you 24/7.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ───────────────── CARDS ─────────────────
          buildCard(
            "Live Chat (Instant Help)",
            "Tap the 'Chat with Us' button inside the app for real-time support. Fastest way to resolve booking issues.",
            Icons.chat_rounded,
          ),

          buildCard(
            "WhatsApp Support",
            "Save our official number (9179369730) and send 'Hi' to get updates or chat with support.",
            Icons.message_rounded,
          ),

          buildCard(
            "Email Support",
            "Send your queries to ajoomisupport@gmail.com. We usually reply within 2–4 hours.",
            Icons.email_rounded,
          ),

          const SizedBox(height: 30),

          // ───────────────── SAFETY BOX ─────────────────
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _lightCyan,
                    Colors.cyan.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _cyan.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: _darkCyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Your safety is our priority. Reach out anytime for help.",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
