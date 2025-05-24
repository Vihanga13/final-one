import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/news_service.dart';
import '../models/news.dart';
import 'news_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final Color customGreen = const Color(0xFF86BF3E);
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Water tracking related fields
  int _waterCups = 0;
  int _waterGoal = 13; // Default for male
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  Timer? _waterReminderTimer;

  // Step counting related fields
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?';
  int _steps = 0;
  bool _isStepCountAvailable = true;

  // Daily step goal
  int dailyStepGoal = 10000; // Default goal
  bool isLoadingSteps = true;

  // News related fields
  final NewsService _newsService = NewsService();
  List<NewsArticle> _newsArticles = [];
  bool _isLoadingNews = true;

  // Animation controller for header image
  AnimationController? _animationController;
  Animation<double>? _imageScaleAnimation;

  // Streak field
  int? _streak;

  // Helper method for creating styled chevron buttons
  Widget _buildChevronButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1), // changes position of shadow
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18.0,
          color: Colors.black54,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDailySteps();
    initPlatformState();
    _initializeNotifications();
    _loadWaterData();
    _startWaterReminders();
    _loadNews();
    _fetchStreak(); // Fetch streak on init

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Define image scale animation
    _imageScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _waterReminderTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  void onStepCount(StepCount event) {
    if (!mounted) return;
    setState(() {
      _steps = event.steps;
    });
    _updateStepsInFirebase(event.steps);
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    if (!mounted) return;
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    if (!mounted) return;
    setState(() {
      _status = 'Pedestrian Status not available';
    });
  }

  void onStepCountError(error) {
    if (!mounted) return;
    setState(() {
      _isStepCountAvailable = false;
      isLoadingSteps = false;
    });
    // Optionally, show a SnackBar or dialog to the user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Step counting is not available on this device.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> initPlatformState() async {
    // Request activity recognition permission
    final permissionStatus = await Permission.activityRecognition.request();
    if (permissionStatus.isGranted) {
      try {
        _stepCountStream = Pedometer.stepCountStream;
        _pedestrianStatusStream = Pedometer.pedestrianStatusStream;

        _stepCountStream.listen(onStepCount, onError: (error) {
          setState(() {
            _isStepCountAvailable = false;
            isLoadingSteps = false;
          });
        });
        _pedestrianStatusStream.listen(onPedestrianStatusChanged, onError: (error) {
          setState(() {
            _status = 'Pedestrian Status not available';
          });
        });
      } catch (e) {
        setState(() {
          _isStepCountAvailable = false;
          isLoadingSteps = false;
        });
      }
    } else {
      setState(() {
        _isStepCountAvailable = false;
        isLoadingSteps = false;
      });
    }
  }

  Future<void> _updateStepsInFirebase(int steps) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_steps')
          .doc(today)
          .set({
        'steps': steps,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _loadDailySteps() async {
    if (!mounted) return;
    setState(() => isLoadingSteps = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('daily_steps')
            .doc(today)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            _steps = doc.data()?['steps'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading steps: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingSteps = false);
      }
    }
  }

  Future<void> _fetchStreak() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final lastActive = userDoc.data()?['last_active'] as Timestamp?;
          final currentStreak = userDoc.data()?['streak'] ?? 0;

          if (lastActive != null) {
            final lastActiveDate = DateTime(
              lastActive.toDate().year,
              lastActive.toDate().month,
              lastActive.toDate().day,
            );
            final today = DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            );
            final difference = today.difference(lastActiveDate).inDays;

            // Calculate new streak
            int newStreak;
            if (difference == 0) {
              // Same day, maintain streak
              newStreak = currentStreak;
            } else if (difference == 1) {
              // Yesterday, maintain streak
              newStreak = currentStreak;
            } else {
              // More than 1 day gap, reset streak
              newStreak = 0;
            }

            // Update streak in Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
                  'streak': newStreak,
                  'last_active': FieldValue.serverTimestamp(),
                });

            if (mounted) {
              setState(() {
                _streak = newStreak;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching streak: $e');
      if (mounted) {
        setState(() {
          _streak = 0;
        });
      }
    }
  }

  // Add this method to update streak when goals are met
  Future<void> _updateStreak() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if both water and step goals are met
        final waterGoalMet = _waterCups >= _waterGoal;
        final stepGoalMet = _steps >= dailyStepGoal;

        if (waterGoalMet && stepGoalMet) {
          // Get current streak
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          final currentStreak = userDoc.data()?['streak'] ?? 0;
          final lastActive = userDoc.data()?['last_active'] as Timestamp?;

          if (lastActive != null) {
            final lastActiveDate = DateTime(
              lastActive.toDate().year,
              lastActive.toDate().month,
              lastActive.toDate().day,
            );
            final today = DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            );
            final difference = today.difference(lastActiveDate).inDays;

            // Calculate new streak
            int newStreak;
            if (difference == 0) {
              // Same day, maintain streak
              newStreak = currentStreak;
            } else if (difference == 1) {
              // Next day, increment streak
              newStreak = currentStreak + 1;
            } else {
              // Start new streak
              newStreak = 1;
            }

            // Update streak in Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
                  'streak': newStreak,
                  'last_active': FieldValue.serverTimestamp(),
                });

            if (mounted) {
              setState(() {
                _streak = newStreak;
              });
            }

            // Show achievement message
            if (mounted && newStreak > currentStreak) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Congratulations! You\'re on a $newStreak day streak! 🔥'),
                  backgroundColor: customGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }

  double get stepProgress => _steps / dailyStepGoal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildWeeklyProgress(),
                const SizedBox(height: 16),
                _buildHealthMetrics(),
                const SizedBox(height: 16),
                _buildHowToUseSection(),
                const SizedBox(height: 24),
                // Health & Fitness News Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Health & Fitness News',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingNews)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else if (_newsArticles.isEmpty)
                      Center(
                        child: Text(
                          'No news available',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _newsArticles.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final article = _newsArticles[index];                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NewsDetailPage(article: article),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (article.imageUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        article.imageUrl,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            article.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            article.description,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            DateFormat('MMM d, yyyy').format(
                                                DateTime.parse(article.publishedAt)),
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _fetchUserDoc(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey,
                );
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!.exists) {
                return const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                );
              }
              final data = snapshot.data!.data();
              final imageUrl = data?['profileImage'] as String?;
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(imageUrl),
                );
              } else {
                return const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/icon.png'),
                );
              }
            },
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _fetchUserDoc(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return const Text(
                      'User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  final data = snapshot.data!.data();
                  final name = data?['name'] ?? 'User';
                  return Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchUserDoc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Widget _buildWeeklyProgress() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFACA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.bolt, size: 16, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Daily intake',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Weekly',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _streak != null ? '${_streak} days' : '0 days',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Replace CircularProgressIndicator with a 7-day streak indicator (7 dots)
            SevenDayStreakRing(streak: _streak != null ? (_streak! > 7 ? 7 : _streak!) : 0),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetrics() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color.fromARGB(255, 225, 245, 201), width: 2), // Add green border
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Steps Goal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.directions_walk,
                                color: Colors.orange[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isLoadingSteps)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: _isStepCountAvailable 
                                            ? NumberFormat('#,###').format(_steps) + ' '
                                            : '-- ',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: 'steps',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${(stepProgress * 100).toInt()}%',
                                  style: TextStyle(
                                    color: customGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: stepProgress.clamp(0.0, 1.0),
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(customGreen),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Goal: ${NumberFormat('#,###').format(dailyStepGoal)} steps',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                     border: Border.all(color: Color.fromARGB(255, 225, 245, 201), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Water Intake',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.water_drop, color: Colors.blue[300]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$_waterCups ',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'cups',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${((_waterCups / _waterGoal) * 100).toInt()}%',
                                style: TextStyle(
                                  color: customGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (_waterCups / _waterGoal).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(customGreen),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Goal: $_waterGoal cups',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: _waterCups > 0 
                                    ? () => _updateWaterCups(_waterCups - 1)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[100],
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(8),
                                ),
                                child: const Icon(Icons.remove, color: Colors.red),
                              ),
                              ElevatedButton(
                                onPressed: _waterCups < _waterGoal 
                                    ? () => _updateWaterCups(_waterCups + 1)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[100],
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(8),
                                ),
                                child: const Icon(Icons.add, color: Colors.blue),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFeatureTile(
                title: 'Scan Meal',
                subtitle: 'Get instant nutrition info',
                icon: Icons.camera_alt,
                color: Colors.orange[100]!,
                iconColor: Colors.orange[700]!,
                onTap: () => Navigator.pushNamed(context, '/scan_meal'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureTile(
                title: 'Ask Helly',
                subtitle: 'Your health assistant',
                icon: Icons.chat_bubble_outline,
                color: Colors.blue[50]!,
                iconColor: Colors.blue[700]!,
                onTap: () => Navigator.pushNamed(context, '/chatscreen'),
              ),
            ),
            
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromARGB(255, 225, 245, 201), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToUseSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color.fromARGB(255, 225, 245, 201), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.help_outline, color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'How to Use This App',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGuideItem(
            icon: Icons.directions_walk,
            title: 'Step Tracking',
            description: 'Reach your daily goal of ${NumberFormat('#,###').format(dailyStepGoal)} steps. Your progress is automatically tracked throughout the day.',
          ),
          _buildGuideItem(
            icon: Icons.water_drop,
            title: 'Water Intake',
            description: 'Track your daily water intake by tapping + or - buttons. Your goal is $_waterGoal cups per day.',
          ),
          _buildGuideItem(
            icon: Icons.local_fire_department,
            title: 'Maintain Your Streak',
            description: 'Keep your daily streak going by meeting both your step and water intake goals.',
          ),
          _buildGuideItem(
            icon: Icons.calendar_today,
            title: 'Weekly Progress',
            description: 'View your weekly progress in the green box at the top. Complete 7 days to fill all circles.',
          ),
          _buildGuideItem(
            icon: Icons.notifications_active,
            title: 'Stay Updated',
            description: 'Receive hourly water reminders when you haven\'t reached your daily water goal.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.blue[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadWaterData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user's gender for goal setting
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final gender = userDoc.data()?['gender'] as String?;
          setState(() {
            _waterGoal = (gender?.toLowerCase() == 'female') ? 9 : 13;
          });
        }

        // Load today's water intake
        final today = DateTime.now().toIso8601String().split('T')[0];
        final waterDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('daily_water')
            .doc(today)
            .get();

        if (waterDoc.exists) {
          setState(() {
            _waterCups = waterDoc.data()?['cups'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading water data: $e');
    }
  }

  Future<void> _updateWaterCups(int cups) async {
    if (!mounted) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        
        // Update daily water intake
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('daily_water')
            .doc(today)
            .set({
              'cups': cups,
              'timestamp': FieldValue.serverTimestamp(),
              'goal': _waterGoal,
            }, SetOptions(merge: true));

        // Update user's last water intake
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'last_water_intake': FieldValue.serverTimestamp(),
              'daily_water_cups': cups,
            });

        setState(() {
          _waterCups = cups;
        });

        // Show achievement message if goal is met
        if (cups == _waterGoal) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Congratulations! You\'ve met your daily water goal! 🎉'),
              backgroundColor: customGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (cups == _waterGoal && _steps >= dailyStepGoal) {
          await _updateStreak();
        }
      }
    } catch (e) {
      debugPrint('Error updating water cups: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update water intake')),
        );
      }
    }
  }
  void _startWaterReminders() {
    _waterReminderTimer?.cancel();  // Cancel any existing timer
    _waterReminderTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_waterCups < _waterGoal) {
        _showWaterReminder();
      }
    });
  }

  Future<void> _showWaterReminder() async {
    if (!mounted) return;  // Check if widget is still mounted
    
    const androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',
      'Water Reminders',
      channelDescription: 'Reminds you to drink water regularly',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      'Time to drink water!',
      'You still need ${_waterGoal - _waterCups} cups to reach your daily goal',
      notificationDetails,
    );
  }  Future<void> _loadNews() async {
    if (!mounted) return;
    try {
      setState(() => _isLoadingNews = true);
      final articles = await _newsService.getHealthAndFitnessNews();
      if (!mounted) return;
      setState(() {
        _newsArticles = articles;
        _isLoadingNews = false;
      });
    } catch (e) {
      debugPrint('Error loading news: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingNews = false;
        _newsArticles = [];
      });
    }
  }

  Widget _buildNewsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'Latest Health News',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingNews)
            const Center(child: CircularProgressIndicator())
          else if (_newsArticles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No news available at the moment.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Column(
              children: _newsArticles
                  .map(
                    (article) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        onTap: () {
                          // Handle news article tap
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  article.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      article.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
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
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// Custom widget for a 7-segment circular streak indicator
class SevenDayStreakRing extends StatelessWidget {
  final int streak; // number of days in streak (max 7)
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final Color borderColor;

  const SevenDayStreakRing({
    Key? key,
    required this.streak,
    this.size = 80,
    this.filledColor = const Color(0xFF86BF3E),
    this.emptyColor = const Color(0xFFE0E0E0),
    this.borderColor = const Color(0xFFBDBDBD),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _SevenDayStreakRingPainter(
              streak: streak,
              filledColor: filledColor,
              emptyColor: emptyColor,
              borderColor: borderColor,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                streak.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Text(
                'days',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SevenDayStreakRingPainter extends CustomPainter {
  final int streak;
  final Color filledColor;
  final Color emptyColor;
  final Color borderColor;

  _SevenDayStreakRingPainter({
    required this.streak,
    required this.filledColor,
    required this.emptyColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final segmentAngle = 2 * 3.141592653589793 / 7;
    final strokeWidth = 10.0;

    for (int i = 0; i < 7; i++) {
      final paint = Paint()
        ..color = i >= 7 - streak ? filledColor : emptyColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final startAngle = -3.141592653589793 / 2 + i * segmentAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle - 0.08, // small gap between segments
        false,
        paint,
      );
    }
    // Draw border ring
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}