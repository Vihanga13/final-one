import 'package:flutter/material.dart';
import 'package:health_app_3/compo/BMICard.dart';
import 'package:health_app_3/pages/Help_and_support_page.dart';
import 'package:health_app_3/pages/change_password.dart';
import 'package:health_app_3/pages/privacy_policy.dart';
import 'package:health_app_3/pages/settings_page.dart';
import 'package:health_app_3/pages/meal_result_page.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Add any missing initializations at the top
  final Color customGreen = const Color(0xFF86BF3E);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> _mealHistory = [];
  bool _isLoading = true;
  bool _isLoadingMeals = true;
  int _totalScans = 0;
  int _streakDays = 0;
  bool _showAllMeals = false; // State variable to track if we're showing all meals

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchMealHistory();
    _fetchTotalScansAndStreak();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        if (!mounted) return;
        setState(() {
          userData = doc.data();
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          userData = null;
          _isLoading = false;
        });
      }
    } else {
      if (!mounted) return;
      setState(() {
        userData = null;
        _isLoading = false;
      });
    }
  }

  // Update the _fetchMealHistory function
  Future<void> _fetchMealHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get current date
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scaned-meal')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
            .orderBy('timestamp', descending: true)
            .get();

        if (!mounted) return;
        setState(() {
          _mealHistory = querySnapshot.docs
              .map((doc) {
                final data = doc.data();
                return {
                  ...data,
                  'id': doc.id,
                  'name': data['mealName'] ?? 'Unknown Meal',
                  'calories': data['calories'] ?? 0,
                  'protein': data['protein'] ?? 0,
                  'carbs': data['carbs'] ?? 0,
                  'fats': data['fats'] ?? 0,
                  'healthScore': data['healthScore'] ?? 0,
                };
              })
              .toList();
          _isLoadingMeals = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching meal history: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingMeals = false;
      });
    }
  }

  Future<void> _fetchTotalScansAndStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final mealCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scaned-meal');
      final querySnapshot = await mealCollection.orderBy('timestamp', descending: true).get();
      final docs = querySnapshot.docs;
      if (!mounted) return;
      setState(() {
        _totalScans = docs.length;
      });
      // Streak logic
      Set<String> uniqueDays = {};
      for (var doc in docs) {
        final ts = doc['timestamp'];
        if (ts is Timestamp) {
          final date = ts.toDate();
          uniqueDays.add(DateTime(date.year, date.month, date.day).toIso8601String());
        }
      }
      // Sort days descending
      List<DateTime> days = uniqueDays.map((d) => DateTime.parse(d)).toList();
      days.sort((a, b) => b.compareTo(a));
      int streak = 0;
      DateTime today = DateTime.now();
      for (int i = 0; i < days.length; i++) {
        if (i == 0) {
          if (days[i].difference(DateTime(today.year, today.month, today.day)).inDays == 0) {
            streak = 1;
          } else {
            break;
          }
        } else {
          if (days[i - 1].difference(days[i]).inDays == 1) {
            streak++;
          } else {
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _streakDays = streak;
      });
    }
  }

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  customGreen.withOpacity(0.8),
                  customGreen,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    image: userData != null && userData!['profileImage'] != null && (userData!['profileImage'] as String).isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(userData!['profileImage']),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: (userData == null || userData!['profileImage'] == null || (userData!['profileImage'] as String).isEmpty)
                        ? Colors.grey[300]
                        : null,
                  ),
                  child: (userData == null || userData!['profileImage'] == null || (userData!['profileImage'] as String).isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 12),
                // Text(
                //   userData != null && userData!['name'] != null && (userData!['name'] as String).isNotEmpty
                //       ? userData!['name']
                //       : 'No Name',
                //   style: const TextStyle(
                //     color: Colors.white,
                //     fontSize: 18,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
              ],
            ),
          ),          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile Details'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
           onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help and Support'),
           onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage(),
                ),
              );
              // Add navigation to privacy policy
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          // Navigate to login page and clear all routes
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/', 
                            (Route<dynamic> route) => false
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error logging out. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (userData == null) {
      return const Scaffold(
        body: Center(child: Text('No user data found.')),
      );
    }
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Blur Effect
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white,
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Pattern
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          customGreen.withOpacity(0.8),
                          customGreen,
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: CirclePatternPainter(),
                    ),
                  ),
                  // Profile Content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              image: userData!['profileImage'] != null && (userData!['profileImage'] as String).isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(userData!['profileImage']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: userData!['profileImage'] == null || (userData!['profileImage'] as String).isEmpty
                                  ? Colors.grey[300]
                                  : null,
                            ),
                            child: (userData!['profileImage'] == null || (userData!['profileImage'] as String).isEmpty)
                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (userData!['name'] ?? '').toString().isNotEmpty ? userData!['name'] : 'No Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (userData!['username'] ?? '').toString().isNotEmpty ? userData!['username'] : 'No Username',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14, // Updated from 14
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getGoalIcon(userData!['goal']),
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (userData!['goal'] ?? '').toString().isNotEmpty ? userData!['goal'] : 'No Goal Selected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14, // Updated from 14
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stats Row
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Total Scans',
                          _totalScans.toString(),
                          Icons.document_scanner,
                        ),
                        _buildVerticalDivider(),
                        _buildStatItem(
                          'Steps',
                          userData!['steps'] != null ? userData!['steps'].toString() : '0',
                          Icons.directions_walk,
                        ),
                        _buildVerticalDivider(),
                        _buildStatItem(
                          'Water',
                          '${userData!['daily_water_cups'] ?? 0} ',
                          Icons.water_drop,
                        ),
                        _buildVerticalDivider(),
                        _buildStatItem(
                          'Streak',
                          '$_streakDays ',
                          Icons.local_fire_department,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  BMICard(
                    height: userData!['height_cm'] != null ? (userData!['height_cm'] as num).toDouble() : 0.0,
                    weight: userData!['weight'] != null ? (userData!['weight'] as num).toDouble() : 0.0,
                  ),

                  const SizedBox(height: 30),

                      // Recent Meals
                  _buildSection(
                    'Recent Meals',
                    [
                      if (_isLoadingMeals)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_mealHistory.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'No meals scanned yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._mealHistory.map((meal) => _buildMealTile(
                              meal['name'] ?? 'Unknown Meal',
                              '${_formatDateTime(meal['timestamp'])} • ${meal['calories'] ?? 0} kcal',
                              meal['healthScore']?.toInt() ?? 0,
                              meal['imageUrl'] ?? '',
                            )),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: customGreen, width: 10),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          elevation: 3,
          child: ClipOval(
            child: Image.asset(
              'assets/images/chatbot.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/chatscreen');
          },
          tooltip: 'Chat',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'No date';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      return 'Invalid date';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: customGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: customGreen,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
    );
  }

  // Update the _buildSection method
  Widget _buildSection(String title, List<Widget> children) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    // Filter out loading and empty state widgets
    final mealWidgets = children.where((widget) => 
      widget is! Center && 
      widget is! CircularProgressIndicator
    ).toList();
    
    // Determine which meals to show
    final displayedMeals = _showAllMeals 
        ? mealWidgets 
        : mealWidgets.take(4).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${DateFormat('MMM d').format(sevenDaysAgo)} - ${DateFormat('MMM d').format(now)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (mealWidgets.length > 4) // Only show button if there are more than 4 meals
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllMeals = !_showAllMeals;
                  });
                },
                child: Text(
                  _showAllMeals ? 'Show Less' : 'See All',
                  style: TextStyle(
                    color: customGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingMeals)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_mealHistory.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No meals scanned yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
            children: displayedMeals,
          ),
      ],
    );
  }

  // Update the _buildMealTile method

  Widget _buildMealTile(String title, String subtitle, int score, String imageUrl) {
    final mealData = _mealHistory.firstWhere(
      (meal) => meal['name'] == title,
      orElse: () => {},
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (mealData.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MealResultPage(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.fastfood,
                              color: Colors.grey,
                              size: 40,
                            ),
                          )
                        : const Icon(
                            Icons.fastfood,
                            color: Colors.grey,
                            size: 40,
                          ),
                  ),
                ),
              ),
              // Content
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle.split(' • ')[0],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGoalIcon(String? goal) {
    switch (goal) {
      case 'Diabetic Patient':
        return Icons.medical_services_outlined;
      case 'Cholesterol Patient':
        return Icons.favorite_outline;
      case 'Loss Weight':
        return Icons.trending_down;
      case 'Gain Weight':
        return Icons.trending_up;
      case 'Weight Balancing':
        return Icons.balance_outlined;
      default:
        return Icons.flag_outlined;
    }
  }
}

// Custom Painter for background pattern
class CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final radius = size.width / 8;
    final centers = [
      Offset(-radius, -radius),
      Offset(size.width / 2, -radius),
      Offset(size.width + radius, -radius),
      Offset(-radius, size.height / 2),
      Offset(size.width + radius, size.height / 2),
      Offset(-radius, size.height + radius),
      Offset(size.width / 2, size.height + radius),
      Offset(size.width + radius, size.height + radius),
    ];

    for (var center in centers) {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
