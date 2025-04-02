import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

  void _showContactDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: const Color(0xFF86BF3E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Contact Us Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Us',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.email, color: Color(0xFF86BF3E)),
                  title: const Text('Email Support'),
                  subtitle: const Text('support@nutritiousapp.com'),
                  onTap: () {
                    _showContactDialog(
                      context, 
                      'Email Support', 
                      'Please email us at support@nutritiousapp.com with your questions or concerns.'
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.phone, color: Color(0xFF86BF3E)),
                  title: const Text('Call Support'),
                  subtitle: const Text('Mon - Fri, 9:00 AM - 5:00 PM'),
                  onTap: () {
                    _showContactDialog(
                      context, 
                      'Call Support', 
                      'Please call our support line at +1234567890 during business hours: Monday to Friday, 9:00 AM - 5:00 PM.'
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // FAQ Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // FAQ Items
                _buildFaqItem(
                  context,
                  'How do I reset my password?',
                  'On the login page, tap "Forgot Password". You will be asked to enter your email address or phone number. We will then send a verification code to reset your password.',
                ),
                _buildFaqItem(
                  context,
                  'How does the meal scanning work?',
                  'You can scan your meals using your camera or upload photos from your gallery. Our AI will analyze the food and provide nutritional information including protein, carbohydrates, and fat content.',
                ),
                _buildFaqItem(
                  context,
                  'How accurate is the food recognition?',
                  'Our AI system is trained on thousands of food items, but accuracy may vary. For best results, ensure good lighting and clear visibility of the food items when taking photos.',
                ),
                _buildFaqItem(
                  context,
                  'How do I switch between health goals?',
                  'You can change your health goal at any time by going to your profile settings and selecting "Change Goal". You can choose from diabetics, cholesterol management, weight loss, weight gain, or weight balance.',
                ),
                _buildFaqItem(
                  context,
                  'How are the nutritional recommendations calculated?',
                  'Our recommendations are based on your BMI, chosen health goal, and established nutritional guidelines. For diabetics and cholesterol management, we recommend specific protein, carbohydrate, and fat restrictions.',
                ),
                _buildFaqItem(
                  context,
                  'Can I see my past meals?',
                  'Yes, you can view your meal history for the past 7 days. Go to the "History" tab to see your previous meals and their nutritional content.',
                ),
                _buildFaqItem(
                  context,
                  'How do I update my weight and height?',
                  'You can update your weight, height, and other personal information by going to your profile page and tapping "Edit Profile".',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tutorial Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Tutorials',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Tutorial Items
                ListTile(
                  leading: const Icon(Icons.lightbulb_outline, color: Color(0xFF86BF3E)),
                  title: const Text('Getting Started'),
                  onTap: () {
                    // Navigate to tutorial page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Placeholder()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF86BF3E)),
                  title: const Text('How to Scan Meals'),
                  onTap: () {
                    // Navigate to tutorial page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Placeholder()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Color(0xFF86BF3E)),
                  title: const Text('Understanding Your Nutritional Feedback'),
                  onTap: () {
                    // Navigate to tutorial page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Placeholder()),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Feedback Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send Feedback',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We value your feedback! Please let us know how we can improve the app.',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to feedback form
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Placeholder()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF86BF3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Submit Feedback'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About App Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About this App',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const ListTile(
                  title: Text('App Version'),
                  trailing: Text('1.0.0'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to terms page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Placeholder()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to privacy policy page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Placeholder()),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            answer,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }
}