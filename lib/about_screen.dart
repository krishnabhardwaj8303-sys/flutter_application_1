import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
const _kMuted = Color(0xFF5E8080);
const _kText = Color(0xFF0D2626);
const _kSubText = Color(0xFF5E8080);

// ─────────────────────────────────────────────
//  ABOUT AJOOMI SCREEN
// ─────────────────────────────────────────────
class AboutAjoomiScreen extends StatelessWidget {
  const AboutAjoomiScreen({super.key});

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _buildHeroBanner(),
                const SizedBox(height: 20),
                _sectionLabel('About'),
                const SizedBox(height: 10),
                _infoCard(
                  Icons.home_repair_service_rounded,
                  _kCyan,
                  'What is Ajoomi?',
                  'Ajoomi is a smart service platform that connects customers with trusted professionals for home services like electrical work, plumbing, cleaning, AC repair, and more — all at your convenience.',
                ),
                const SizedBox(height: 8),
                _infoCard(
                  Icons.flag_rounded,
                  const Color(0xFF185FA5),
                  'Our Mission',
                  'To make home services simple, reliable, and accessible to everyone by connecting users with skilled professionals instantly.',
                ),
                const SizedBox(height: 8),
                _infoCard(
                  Icons.visibility_rounded,
                  const Color(0xFF854F0B),
                  'Our Vision',
                  'To become India\'s most trusted home service platform by ensuring quality, safety, and customer satisfaction in every booking.',
                ),
                const SizedBox(height: 20),
                _sectionLabel('Ajoomi in Numbers'),
                const SizedBox(height: 10),
                _buildStatsRow(),
                const SizedBox(height: 20),
                _sectionLabel('Our Services'),
                const SizedBox(height: 10),
                _buildServicesWrap(),
                const SizedBox(height: 20),
                _sectionLabel('Contact & Support'),
                const SizedBox(height: 10),
                _buildContactCard(),
                const SizedBox(height: 20),
                _buildMadeWithLove(),
                const SizedBox(height: 12),
                _buildVersion(),
              ],
            ),
          ),
        ]),
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
            Text('About Ajoomi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text('Your trusted home service partner',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _kCyan,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('v1.0',
              style: TextStyle(
                  color: _kDark, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  HERO BANNER
  // ─────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(color: _kCyan.withOpacity(0.4), width: 2),
          ),
          child: const Icon(Icons.home_repair_service_rounded,
              size: 34, color: _kCyan),
        ),
        const SizedBox(height: 14),
        const Text('Ajoomi',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
        const SizedBox(height: 5),
        const Text('Your trusted home service partner',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kCyan.withOpacity(0.3)),
          ),
          child: const Text(
            '🇮🇳  Made in India  •  Trusted by Thousands',
            style: TextStyle(
                color: _kCyan, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  INFO CARD
  // ─────────────────────────────────────────────
  Widget _infoCard(IconData icon, Color iconColor, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _kBorder),
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: _kText, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(body,
                style: const TextStyle(
                    color: _kSubText, fontSize: 12, height: 1.5)),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  STATS ROW
  // ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(children: [
      Expanded(child: _statBox(Icons.engineering_rounded, '500+', 'Workers')),
      const SizedBox(width: 8),
      Expanded(child: _statBox(Icons.check_circle_rounded, '10k+', 'Bookings')),
      const SizedBox(width: 8),
      Expanded(child: _statBox(Icons.location_city_rounded, '20+', 'Cities')),
    ]);
  }

  Widget _statBox(IconData icon, String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(children: [
        Icon(icon, color: _kCyan, size: 24),
        const SizedBox(height: 7),
        Text(val,
            style: const TextStyle(
                color: _kDark, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: _kSubText, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  SERVICES WRAP
  // ─────────────────────────────────────────────
  Widget _buildServicesWrap() {
    const services = [
      {'icon': Icons.plumbing_rounded, 'name': 'Plumber'},
      {'icon': Icons.electrical_services_rounded, 'name': 'Electrician'},
      {'icon': Icons.cleaning_services_rounded, 'name': 'Cleaning'},
      {'icon': Icons.ac_unit_rounded, 'name': 'AC Repair'},
      {'icon': Icons.chair_rounded, 'name': 'Carpenter'},
      {'icon': Icons.format_paint_rounded, 'name': 'Painter'},
      {'icon': Icons.content_cut_rounded, 'name': 'Salon'},
      {'icon': Icons.local_laundry_service_rounded, 'name': 'Laundry'},
      {'icon': Icons.home_rounded, 'name': 'Maid'},
      {'icon': Icons.restaurant_rounded, 'name': 'Cook'},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: services
          .map((s) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _kLightCyan,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(s['icon'] as IconData, color: _kCyanDark, size: 15),
                  const SizedBox(width: 6),
                  Text(s['name'] as String,
                      style: const TextStyle(
                          color: _kText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────
  //  CONTACT CARD
  // ─────────────────────────────────────────────
  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("We're here 24/7 to help you 🙌",
            style: TextStyle(
                color: _kText, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'Questions about booking, payment, or joining as a professional? Reach us anytime.',
          style: TextStyle(color: _kSubText, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 14),
        _contactRow(
          icon: Icons.chat_rounded,
          label: 'WhatsApp',
          value: '+91 9179369730',
          color: const Color(0xFF25D366),
          onTap: _openWhatsApp,
        ),
        const SizedBox(height: 8),
        _contactRow(
          icon: Icons.email_rounded,
          label: 'Email',
          value: 'ajoomisupport@gmail.com',
          color: const Color(0xFF185FA5),
          onTap: _openEmail,
        ),
        const SizedBox(height: 8),
        _contactRow(
          icon: Icons.call_rounded,
          label: 'Call Us',
          value: '+91 9179369730',
          color: _kCyan,
          onTap: _openCall,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _kLightCyan,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: const Row(children: [
            Icon(Icons.tips_and_updates_rounded, color: _kCyan, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Use in-app chat for the fastest response — typically under 2 minutes.',
                style: TextStyle(color: _kMuted, fontSize: 11, height: 1.4),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      color: _kSubText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.4), size: 13),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  MADE WITH LOVE
  // ─────────────────────────────────────────────
  Widget _buildMadeWithLove() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kLightCyan,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.favorite_rounded, color: Colors.red, size: 18),
        SizedBox(width: 8),
        Text('Made with love to simplify your daily life.',
            style: TextStyle(
                color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  VERSION
  // ─────────────────────────────────────────────
  Widget _buildVersion() {
    return Center(
      child: Column(children: [
        const Text('Ajoomi © 2026  •  Version 1.0.0',
            style: TextStyle(color: _kSubText, fontSize: 11)),
        const SizedBox(height: 4),
        Text('All rights reserved',
            style: TextStyle(color: _kSubText.withOpacity(0.6), fontSize: 10)),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  SECTION LABEL
  // ─────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Row(children: [
      Text(label,
          style: const TextStyle(
              color: _kText, fontSize: 13, fontWeight: FontWeight.bold)),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1, color: _kBorder)),
    ]);
  }
}
