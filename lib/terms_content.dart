import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CONSTANTS (CYAN THEME)
// ─────────────────────────────────────────────
const _kDark = Color(0xFF0D3B46);
const _kCyan = Color(0xFF00BCD4);
const _kLightCyan = Color(0xFFE0F7FA);
const _kBorder = Color(0xFFB2EBF2);
const _kText = Color(0xFF0D3B46);
const _kBody = Color(0xFF444444);

// ─────────────────────────────────────────────
//  TERMS SECTION MODEL
// ─────────────────────────────────────────────
class _Section {
  const _Section({
    required this.title,
    required this.icon,
    required this.body,
    this.cards,
  });

  final String title;
  final IconData icon;
  final String body;
  final List<_Card>? cards;
}

class _Card {
  const _Card({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

const _kSections = [
  _Section(
    title: 'Introduction',
    icon: Icons.info_rounded,
    body:
        'These Terms govern the use of services available on the AJOOMI mobile app.\n\n'
        'By using the Services, you confirm you have full legal capacity to agree to these Terms. '
        'By accessing the Platform, you accept these Terms and form a legal contract. '
        'If you do not agree, please do not use the Services.',
  ),
  _Section(
    title: 'Our Services',
    icon: Icons.home_repair_service_rounded,
    body: '',
    cards: [
      _Card(
        title: 'Electrical Services',
        content:
            'Complete electrical solutions including wiring, switches, MCB, fans, lights, geysers, and AC setup.',
      ),
      _Card(
        title: 'Plumbing & Sanitation',
        content:
            'Leak fixing, drain cleaning, bathroom fittings, tank cleaning, and pump repairs.',
      ),
      _Card(
        title: 'Maid Services',
        content:
            'Daily cleaning, sweeping, mopping, kitchen work, and complete home maintenance.',
      ),
      _Card(
        title: 'Deep Cleaning',
        content:
            'Full house deep cleaning including bathroom scrubbing, sofa cleaning, and kitchen degreasing.',
      ),
    ],
  ),
  _Section(
    title: 'User Eligibility & Security',
    icon: Icons.person_rounded,
    body:
        'Users must be 18+ and legally capable. False information can lead to account termination.\n\n'
        'You are responsible for your account and password security. Ajoomi is not liable for misuse of your credentials.',
  ),
  _Section(
    title: 'Booking & Timelines',
    icon: Icons.calendar_today_rounded,
    body:
        'We aim for 30-minute service arrival but timing may vary based on availability and location.\n\n'
        'Users can select preferred time slots. Delays may occur and rescheduling will be offered if needed.',
  ),
  _Section(
    title: 'Pricing & Payments',
    icon: Icons.payment_rounded,
    body:
        'No hidden charges. The shown price is the final labor cost — no bargaining allowed.\n\n'
        'Payments via UPI, Debit/Credit Cards, Net Banking, or Cash on Delivery. '
        'Spare parts cost, if required, is charged separately and communicated in advance.',
  ),
  _Section(
    title: 'Customer Conduct',
    icon: Icons.handshake_rounded,
    body:
        'Users must behave respectfully toward all professionals. Abuse or misconduct will lead to a permanent ban.\n\n'
        'Prohibited: illegal tasks, bypassing the platform system, or making off-platform payments to workers.',
  ),
  _Section(
    title: 'Privacy & Data',
    icon: Icons.lock_rounded,
    body:
        'We collect data such as phone number, location, and booking history to improve our services. All data is stored securely.\n\n'
        'Basic details are shared with service professionals only for booking completion. We do not sell your data to third parties.',
  ),
  _Section(
    title: 'Legal & Disclaimers',
    icon: Icons.gavel_rounded,
    body:
        'Services are provided "as-is". Ajoomi is not liable for indirect or consequential damages arising from service use.\n\n'
        'All disputes are governed under Indian law and handled in local courts of jurisdiction.',
  ),
  _Section(
    title: 'Grievance Policy',
    icon: Icons.support_agent_rounded,
    body:
        'Users can raise complaints through the in-app support section or email us at ajoomisupport@gmail.com. '
        'All grievances are acknowledged within 48 hours and resolved within 15–30 business days.',
  ),
  _Section(
    title: 'Updates to Terms',
    icon: Icons.update_rounded,
    body:
        'These Terms may be updated at any time. Continued use of Ajoomi after changes are posted constitutes acceptance of the updated Terms. '
        'We recommend reviewing this page periodically.',
  ),
];

// ─────────────────────────────────────────────
//  TERMS SCREEN
// ─────────────────────────────────────────────
class TermsContent extends StatelessWidget {
  const TermsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildTopBanner(),
                const SizedBox(height: 20),
                ..._kSections
                    .asMap()
                    .entries
                    .map((e) => _buildSection(e.key + 1, e.value)),
                const SizedBox(height: 8),
                _buildLastUpdated(),
                const SizedBox(height: 20),
                _buildAcceptButton(context),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
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
        bottom: 14,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Please read carefully before using Ajoomi',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TOP BANNER
  // ─────────────────────────────────────────────
  Widget _buildTopBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D3B46),
            Color(0xFF00BCD4),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gavel_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajoomi Terms of Service',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'By continuing to use the app, you agree to the terms outlined below.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SECTION
  // ─────────────────────────────────────────────
  Widget _buildSection(int index, _Section section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: _kLightCyan,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: _kDark,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                section.icon,
                color: _kCyan,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                section.title,
                style: const TextStyle(
                  color: _kText,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // BODY
        if (section.body.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FCFD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0F7FA)),
            ),
            child: Text(
              section.body,
              style: const TextStyle(
                fontSize: 13,
                height: 1.65,
                color: _kBody,
              ),
            ),
          ),

        // SERVICE CARDS
        if (section.cards != null) ...[
          ...section.cards!.map(_buildServiceCard),
        ],

        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildServiceCard(_Card card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F7FA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: _kCyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  card.content,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: _kBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  LAST UPDATED
  // ─────────────────────────────────────────────
  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kLightCyan,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            color: _kCyan,
            size: 15,
          ),
          SizedBox(width: 8),
          Text(
            'Last updated: 1 May 2026  •  Version 1.0',
            style: TextStyle(
              fontSize: 11,
              color: _kText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ACCEPT BUTTON
  // ─────────────────────────────────────────────
  Widget _buildAcceptButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(
          Icons.check_circle_rounded,
          size: 19,
        ),
        label: const Text(
          'Accept & Continue',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
