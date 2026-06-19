import 'package:flutter/material.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen>
    with SingleTickerProviderStateMixin {
  // 🌊 CYAN THEME COLORS
  static const Color kDark = Color(0xFF062B36);
  static const Color kCyan = Color(0xFF00BCD4);
  static const Color kLightCyan = Color(0xFFE0F7FA);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildSection(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.7,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FCFD),

      // 🌊 APPBAR
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: kCyan,
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 6,
              shadowColor: kCyan.withOpacity(0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌊 TITLE
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kLightCyan,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.gavel_rounded,
                            color: kCyan,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "AJOOMI Terms & Conditions",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kDark,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🔥 FULL CONTENT
                    buildSection(
                      """These terms and conditions ("Terms") govern the use of services made 
available on or through 'website link' and/or the "AJOOMI" 
mobile app (collectively, the "Platform", and together with the services
made available on or through the Platform, the "Services"). By using the
Services, you represent and warrant that you have full legal capacity 
and authority to agree to and bind yourself to these Terms.

Where you access or use the Services on behalf of another person or entity, you 
confirm that you are duly authorized to accept these Terms on their behalf.

Please read these Terms carefully. By accessing or using the Platform, 
you are agreeing to these Terms and concluding a legally binding contract 
with the Company.

You may not use the Services if you do not accept the Terms or are unable to be bound by the Terms.

Your use of the Platform is at your own risk, including the risk that you might be exposed to content 
that is objectionable or otherwise inappropriate.

In order to use the Services, you must first agree to the Terms.

By using the Services, you agree that you have read, understood, and are bound
by these Terms, as amended from time to time, and that you will comply with 
the requirements listed here.

These Terms expressly supersede any prior written agreements with you. 
If you do not agree to these Terms, please do not use the Services.

1. OUR SERVICES

Electrical Services:
We provide comprehensive electrical solutions ranging from minor repairs to complete
household wiring. Our certified electricians handle everything from fixing faulty
switches, MCBs, and sockets to professional installation of fans, chandeliers, 
and decorative lighting.

Plumbing & Sanitation:
From leaky faucets and clogged drains to full bathroom renovations, our plumbing 
experts offer quick and reliable solutions.

Professional Maid Services:
Keep your home spotless and stress-free with our verified domestic help. Whether you 
need a one-time deep cleaning or a reliable daily maid, we connect you with trained professionals.

Deep Cleaning & Specialized Housekeeping:
Our deep cleaning experts use professional-grade equipment to sanitize your entire home.""",
                    ),

                    const SizedBox(height: 14),

                    // 🌊 INFO BOX
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kLightCyan,
                            Colors.cyan.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.cyan.shade100,
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_rounded,
                            color: kCyan,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "By continuing to use Ajoomi, you agree to all terms mentioned above.",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: kDark,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // 🌊 BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kCyan,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Accept & Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
