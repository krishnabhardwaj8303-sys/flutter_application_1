import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────
const _kDark = Color(0xFF0D2626);
const _kCyan = Color(0xFF00BCD4);
const _kCyanDark = Color(0xFF00838F);
const _kLightCyan = Color(0xFFE0F7FA);
const _kBg = Colors.white;
const _kCard = Color(0xFFF4FDFD);
const _kBorder = Color(0xFFC8EDEF);
const _kText = Color(0xFF0D2626);
const _kSubText = Color(0xFF5E8080);

// ─────────────────────────────────────────────
//  FAQ MODEL
// ─────────────────────────────────────────────
class _FaqSection {
  const _FaqSection(
      {required this.title, required this.icon, required this.items});
  final String title;
  final IconData icon;
  final List<_FaqItem> items;
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

const _kFaqSections = [
  _FaqSection(
    title: 'Frequently Asked Questions',
    icon: Icons.help_rounded,
    items: [
      _FaqItem(
        question: 'Is Ajoomi available in my area?',
        answer:
            'Enter your address and enable location access to check availability. We currently serve selected cities and are expanding rapidly.',
      ),
      _FaqItem(
        question: 'Do I need to provide tools or materials?',
        answer:
            'Our professionals bring standard tools. If specific parts are needed, your professional will inform you in advance.',
      ),
    ],
  ),
  _FaqSection(
    title: 'Account',
    icon: Icons.manage_accounts_rounded,
    items: [
      _FaqItem(
        question: 'How do I change my phone number?',
        answer:
            'Go to Profile → Edit Profile → verify your identity → update your number.',
      ),
      _FaqItem(
        question: 'How do I change my email address?',
        answer:
            'Update your email from Profile settings after OTP verification.',
      ),
      _FaqItem(
        question: 'Why is verification failing?',
        answer:
            'Common reasons: wrong OTP, unsupported carrier, or account age below 18. Contact support if the issue persists.',
      ),
      _FaqItem(
        question: 'Can I have multiple accounts?',
        answer:
            'Only one account is allowed per mobile number to ensure accountability.',
      ),
    ],
  ),
  _FaqSection(
    title: 'Booking & Scheduling',
    icon: Icons.calendar_today_rounded,
    items: [
      _FaqItem(
        question: 'How do I book a service?',
        answer:
            'Select service → Choose task → Pick date & time → Add address → Confirm booking. That\'s it!',
      ),
      _FaqItem(
        question: 'How do I reschedule a booking?',
        answer:
            'Go to My Bookings → Select the booking → Tap Reschedule and choose a new time.',
      ),
      _FaqItem(
        question: 'Can I request the same professional again?',
        answer:
            'Yes! Use the Rebook option from your completed bookings to request the same professional.',
      ),
    ],
  ),
  _FaqSection(
    title: 'Cancellation Policy',
    icon: Icons.cancel_rounded,
    items: [
      _FaqItem(
        question: 'What is the free cancellation window?',
        answer:
            'Cancel within 30 minutes of booking for free. After that, a small cancellation fee applies.',
      ),
      _FaqItem(
        question: 'Cancellation for instant bookings?',
        answer:
            'Instant bookings have a 5-minute free cancellation window after confirmation.',
      ),
    ],
  ),
  _FaqSection(
    title: 'Payments',
    icon: Icons.payment_rounded,
    items: [
      _FaqItem(
        question: 'What payment methods are accepted?',
        answer:
            'UPI, Debit/Credit Cards, Net Banking, and Cash on Delivery are all supported.',
      ),
      _FaqItem(
        question: 'Is my payment information secure?',
        answer:
            'Yes. All payments are processed through Razorpay with 256-bit SSL encryption. We never store card details.',
      ),
      _FaqItem(
        question: 'I was charged twice. What do I do?',
        answer:
            'Please share your transaction ID with us via chat or email. Refunds are processed within 24–48 hours.',
      ),
    ],
  ),
  _FaqSection(
    title: 'Safety',
    icon: Icons.verified_user_rounded,
    items: [
      _FaqItem(
        question: 'How does Ajoomi ensure worker safety?',
        answer:
            'Every professional undergoes ID verification, background checks, and skill testing before joining. An SOS button is available during active bookings for emergencies.',
      ),
      _FaqItem(
        question: 'What if I feel unsafe during a service?',
        answer:
            'Tap the SOS button in the active booking screen to alert our safety team immediately. You can also call us at +91 9179369730.',
      ),
    ],
  ),
];

// ─────────────────────────────────────────────
//  HELP & SUPPORT SCREEN
// ─────────────────────────────────────────────
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/919179369730');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail() async {
    final uri =
        Uri.parse('mailto:ajoomisupport@gmail.com?subject=Ajoomi Support');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openCall() async {
    final uri = Uri.parse('tel:+919179369730');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildQuickContact(),
              const SizedBox(height: 20),
              _sectionDivider('Frequently Asked Questions'),
              const SizedBox(height: 12),
              ..._kFaqSections.map(_buildFaqSection),
              const SizedBox(height: 20),
              _buildSafetyBanner(),
            ],
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _kDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Help & Support',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text('How can we help you today?',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 18),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  SEARCH BAR
  // ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _kBorder),
      ),
      child: Row(children: [
        const SizedBox(width: 12),
        const Icon(Icons.search_rounded, color: _kCyan, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            style: const TextStyle(fontSize: 13, color: _kText),
            decoration: const InputDecoration(
              hintText: 'Search for help topics...',
              hintStyle: TextStyle(color: _kSubText, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  QUICK CONTACT ROW
  // ─────────────────────────────────────────────
  Widget _buildQuickContact() {
    return Row(children: [
      Expanded(
          child: _contactChip(
        icon: Icons.chat_rounded,
        label: 'WhatsApp',
        color: const Color(0xFF25D366),
        onTap: _openWhatsApp,
      )),
      const SizedBox(width: 8),
      Expanded(
          child: _contactChip(
        icon: Icons.email_rounded,
        label: 'Email Us',
        color: const Color(0xFF185FA5),
        onTap: _openEmail,
      )),
      const SizedBox(width: 8),
      Expanded(
          child: _contactChip(
        icon: Icons.call_rounded,
        label: 'Call Us',
        color: _kCyan,
        onTap: _openCall,
      )),
    ]);
  }

  Widget _contactChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FAQ SECTION
  // ─────────────────────────────────────────────
  Widget _buildFaqSection(_FaqSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kLightCyan,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Row(children: [
            Icon(section.icon, color: _kCyanDark, size: 16),
            const SizedBox(width: 8),
            Text(section.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: _kText)),
          ]),
        ),
        const SizedBox(height: 8),
        ...section.items.map(_buildFaqItem),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildFaqItem(_FaqItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          iconColor: _kCyan,
          collapsedIconColor: _kSubText,
          title: Text(item.question,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kText)),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Text(item.answer,
                  style: const TextStyle(
                      fontSize: 12, color: _kSubText, height: 1.55)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SAFETY BANNER
  // ─────────────────────────────────────────────
  Widget _buildSafetyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.verified_user_rounded, color: _kCyan, size: 18),
          SizedBox(width: 8),
          Text('Your Safety is Our Priority',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        const Text(
          'Every professional on Ajoomi undergoes ID verification, background checks, and skill testing. '
          'An SOS button is available during active bookings for emergencies.',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _safetyBadge(Icons.badge_rounded, 'ID Verified')),
          const SizedBox(width: 8),
          Expanded(
              child:
                  _safetyBadge(Icons.fact_check_rounded, 'Background Check')),
          const SizedBox(width: 8),
          Expanded(child: _safetyBadge(Icons.star_rounded, 'Skill Tested')),
        ]),
      ]),
    );
  }

  Widget _safetyBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(children: [
        Icon(icon, color: _kCyan, size: 18),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────
  Widget _sectionDivider(String label) {
    return Row(children: [
      Text(label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: _kText)),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1, color: _kBorder)),
    ]);
  }
}
