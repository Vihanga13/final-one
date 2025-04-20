import 'package:flutter/material.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController;
  
  // Track the expanded state of FAQ items
  final Map<int, bool> _expandedItems = {};

  void _showContactDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: Tween<double>(begin: 0.5, end: 1.0)
                .animate(CurvedAnimation(
                  parent: _controller, 
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)
                )).value,
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0)
                  .animate(CurvedAnimation(
                    parent: _controller, 
                    curve: const Interval(0.0, 0.5, curve: Curves.easeOut)
                  )),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                ),
              ),
            );
          }
        );
      },
    );
    
    // Reset and start the animation when showing dialog
    _controller.reset();
    _controller.forward();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scrollController = ScrollController();
    
    // Start the animation when the page loads
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
              ),
            ),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
                ),
              ),
              child: const Text(
                'How can we help you?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Contact Us Section
          _buildAnimatedContainer(
            0.1, 0.4,
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
                  _buildAnimatedListItem(
                    0.15, 0.45,
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
                  ),
                  const Divider(),
                  _buildAnimatedListItem(
                    0.2, 0.5,
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
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // FAQ Section
          _buildAnimatedContainer(
            0.25, 0.55,
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
                  _buildFaqItem(context, 0, 'How do I reset my password?',
                    'On the login page, tap "Forgot Password". You will be asked to enter your email address or phone number. We will then send a verification code to reset your password.'),
                  _buildFaqItem(context, 1, 'How does the meal scanning work?',
                    'You can scan your meals using your camera or upload photos from your gallery. Our AI will analyze the food and provide nutritional information including protein, carbohydrates, and fat content.'),
                  _buildFaqItem(context, 2, 'How accurate is the food recognition?',
                    'Our AI system is trained on thousands of food items, but accuracy may vary. For best results, ensure good lighting and clear visibility of the food items when taking photos.'),
                  _buildFaqItem(context, 3, 'How do I switch between health goals?',
                    'You can change your health goal at any time by going to your profile settings and selecting "Change Goal". You can choose from diabetics, cholesterol management, weight loss, weight gain, or weight balance.'),
                  _buildFaqItem(context, 4, 'How are the nutritional recommendations calculated?',
                    'Our recommendations are based on your BMI, chosen health goal, and established nutritional guidelines. For diabetics and cholesterol management, we recommend specific protein, carbohydrate, and fat restrictions.'),
                  _buildFaqItem(context, 5, 'Can I see my past meals?',
                    'Yes, you can view your meal history for the past 7 days. Go to the "History" tab to see your previous meals and their nutritional content.'),
                  _buildFaqItem(context, 6, 'How do I update my weight and height?',
                    'You can update your weight, height, and other personal information by going to your profile page and tapping "Edit Profile".'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tutorial Section
          _buildAnimatedContainer(
            0.35, 0.65,
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
                  _buildAnimatedListItem(
                    0.4, 0.7,
                    ListTile(
                      leading: const Icon(Icons.lightbulb_outline, color: Color(0xFF86BF3E)),
                      title: const Text('Getting Started'),
                      onTap: () {
                        _navigateWithAnimation(context, const Placeholder());
                      },
                    ),
                  ),
                  const Divider(),
                  _buildAnimatedListItem(
                    0.45, 0.75,
                    ListTile(
                      leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF86BF3E)),
                      title: const Text('How to Scan Meals'),
                      onTap: () {
                        _navigateWithAnimation(context, const Placeholder());
                      },
                    ),
                  ),
                  const Divider(),
                  _buildAnimatedListItem(
                    0.5, 0.8,
                    ListTile(
                      leading: const Icon(Icons.bar_chart, color: Color(0xFF86BF3E)),
                      title: const Text('Understanding Your Nutritional Feedback'),
                      onTap: () {
                        _navigateWithAnimation(context, const Placeholder());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Feedback Section
          _buildAnimatedContainer(
            0.55, 0.85,
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
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    builder: (BuildContext context, double value, Widget? child) {
                      return Transform.scale(
                        scale: 0.7 + (0.3 * value),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateWithAnimation(context, const Placeholder());
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About App Section
          _buildAnimatedContainer(
            0.65, 0.95,
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
                  _buildAnimatedListItem(
                    0.7, 1.0,
                    const ListTile(
                      title: Text('App Version'),
                      trailing: Text('1.0.0'),
                    ),
                  ),
                  const Divider(),
                  _buildAnimatedListItem(
                    0.75, 1.0,
                    ListTile(
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _navigateWithAnimation(context, const Placeholder());
                      },
                    ),
                  ),
                  const Divider(),
                  _buildAnimatedListItem(
                    0.8, 1.0,
                    ListTile(
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _navigateWithAnimation(context, const Placeholder());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAnimatedContainer(double startInterval, double endInterval, Widget child) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildAnimatedListItem(double startInterval, double endInterval, Widget child) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, int index, String question, String answer) {
    // Initialize if not already in map
    _expandedItems.putIfAbsent(index, () => false);
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),  
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return RotationTransition(
              turns: animation.drive(Tween<double>(begin: 0.25, end: 0.0)),
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            _expandedItems[index] == true ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            key: ValueKey<bool>(_expandedItems[index] == true),
          ),
        ),
        onExpansionChanged: (bool expanded) {
          setState(() {
            _expandedItems[index] = expanded;
          });
        },
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateWithAnimation(BuildContext context, Widget destination) {
    // Create a custom page route with animation
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}