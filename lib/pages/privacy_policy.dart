import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );

  Widget _sectionBody(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/main_screen',
              (route) => false,
            );
          },
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF86BF3E)),
            tooltip: 'About this policy',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('About this Policy',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Text(
                          'This privacy policy is designed to be transparent and easy to understand. We are committed to protecting your data and respecting your privacy.'),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(bottom: 24),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.privacy_tip_rounded,
                        color: Color(0xFF86BF3E), size: 48),
                  ),
                ),
                Center(
                  child: Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Last updated: May 21, 2025',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionBody(
                    'Your privacy is our top priority. This Privacy Policy explains how we collect, use, protect, and share your information when you use our app. We use modern security and privacy practices to keep your data safe.'),
                _sectionTitle('1. Information We Collect'),
                _sectionBody(
                    '• Personal information (name, email, profile image) when you register or update your profile.'
                    '\n• Health and fitness data you provide or generate while using the app.'
                    '\n• Usage data, device information, and analytics to improve your experience.'
                    '\n• Optional: Location data (if you enable location-based features).'),
                _sectionTitle('2. How We Use Your Information'),
                _sectionBody(
                    '• To provide, personalize, and improve app features.'
                    '\n• To analyze usage and enhance user experience.'
                    '\n• To communicate with you about updates, support, or offers.'
                    '\n• To ensure security and prevent misuse.'),
                _sectionTitle('3. Information Sharing & Disclosure'),
                _sectionBody(
                    'We do not sell your personal information. We only share data with trusted partners for core app functionality (e.g., authentication, cloud storage) or as required by law.'
                    '\n\nIf you use social or third-party integrations, their privacy policies apply.'),
                _sectionTitle('4. Data Security'),
                _sectionBody(
                    'We use industry-standard encryption and security measures to protect your data. However, no method of transmission or storage is 100% secure.'),
                _sectionTitle('5. Your Rights & Choices'),
                _sectionBody(
                    '• You can review, update, or delete your personal information at any time in your account settings.'
                    '\n• You may opt out of analytics or marketing communications.'
                    '\n• You can request a copy of your data or account deletion by contacting support.'),
                _sectionTitle('6. Children’s Privacy'),
                _sectionBody(
                    'Our app is not intended for children under 13. We do not knowingly collect data from children. If you believe a child has provided us with personal information, please contact us.'),
                _sectionTitle('7. Changes to This Policy'),
                _sectionBody(
                    'We may update this policy from time to time. We will notify you of significant changes via the app or email.'),
                _sectionTitle('8. Contact Us'),
                _sectionBody(
                    'If you have questions or concerns about this Privacy Policy, contact us through the app support page or at privacy@yourapp.com.'),
                const SizedBox(height: 32),
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOut,
                    width: 120,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Removed the back button for a cleaner look
              ],
            ),
          ),
        ),
      ),
    );
  }
}