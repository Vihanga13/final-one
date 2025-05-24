import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'meal_comparison_page.dart';

class MealResultPage extends StatefulWidget {
  final File? mealImage;
  final Color customGreen = const Color(0xFF86BF3E);

  const MealResultPage({super.key, this.mealImage});

  @override
  State<MealResultPage> createState() => _MealResultPageState();
}

class _MealResultPageState extends State<MealResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  final List<int> _staggerDelays = [100, 200, 300, 400];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meal Results'),
          backgroundColor: widget.customGreen,
        ),
        body: const Center(child: Text('User not signed in.')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated background
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            builder: (context, double value, child) {
              return Positioned(
                top: -100 + (value * 20),
                right: -100,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.customGreen.withOpacity(0.1 * value),
                    ),
                  ),
                ),
              );
            },
          ),
          // Main content
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('scaned-meal')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_food, size: 120, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No meals scanned yet',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Scan your first meal to see the results here',
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                );
              }
              final meal =
                  snapshot.data!.docs.first.data() as Map<String, dynamic>;
              final mealName =
                  (meal['mealName'] ?? '').toString().toLowerCase().trim();
              final timestamp = meal['timestamp'] as Timestamp?;
              final dateString = timestamp != null
                  ? DateFormat('MMM d, yyyy • h:mm a')
                      .format(timestamp.toDate())
                  : 'Unknown date';
              final imageUrl = meal['imageUrl'] as String?;
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 350,
                    pinned: true,
                    stretch: true,
                    backgroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          imageUrl != null && imageUrl.isNotEmpty
                              ? Hero(
                                  tag: 'meal_image',
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 1.2, end: 1.0),
                                    duration:
                                        const Duration(milliseconds: 1000),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: NetworkImage(imageUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container(color: Colors.grey[200]),
                          FadeTransition(
                            opacity: _fadeInAnimation,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.4),
                                    Colors.transparent,
                                    Colors.white,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                leading: Row(
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    GestureDetector(
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
  ],
),
                    actions: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: child,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.share, color: Colors.black),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              // Implement share functionality
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('meals')
                          .doc(mealName)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!snapshot.hasData ||
                            !(snapshot.data?.exists ?? false)) {
                          return _buildNoNutritionInfo(dateString, mealName);
                        }
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        if (data == null) {
                          return _buildNoNutritionInfo(dateString, mealName);
                        }
                        final calories = data['Calories']?.toString() ??
                            data['calories']?.toString() ??
                            '0';
                        final protein = data['Protein']?.toString() ??
                            data['Proteins']?.toString() ??
                            data['Protiens']?.toString() ??
                            data['proteins']?.toString() ??
                            '0';
                        final carbs = data['Carbs']?.toString() ??
                            data['carbs']?.toString() ??
                            '0';
                        final fats = data['Fats']?.toString() ??
                            data['fats']?.toString() ??
                            '0';
                        return _buildAnimatedMealResult(dateString, mealName,
                            calories, protein, carbs, fats);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget _buildRecommendationCard( // This method is unused
  //     BuildContext context, String title, String subtitle, String imagePath) {
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12.0),
  //       child: Row(
  //         children: [
  //           Image.asset(imagePath, width: 60, height: 60, fit: BoxFit.cover),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(title,
  //                     style: const TextStyle(
  //                         fontSize: 16, fontWeight: FontWeight.bold)),
  //                 const SizedBox(height: 4),
  //                 Text(subtitle,
  //                     style: TextStyle(fontSize: 14, color: Colors.grey[600])),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildNoNutritionInfo(String dateString, String mealName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            mealName.isNotEmpty
                ? mealName[0].toUpperCase() + mealName.substring(1)
                : 'Unknown Meal',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(dateString,
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),
          Icon(Icons.info_outline, color: Colors.grey[400], size: 60),
          const SizedBox(height: 16),
          const Text('Nutrition information not available',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAnimatedMealResult(String dateString, String mealName,
      String calories, String protein, String carbs, String fats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            mealName.isNotEmpty
                ? mealName[0].toUpperCase() + mealName.substring(1)
                : 'Unknown Meal',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(dateString,
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final List<Map<String, dynamic>> macroData = [
                  {
                    'title': 'Calories',
                    'value': calories.replaceAll(RegExp(r'[^0-9.]'), ''),
                    'unit': 'kcal',
                    'icon': Icons.local_fire_department,
                    'color': Colors.orange,
                  },
                  {
                    'title': 'Protein',
                    'value': protein.replaceAll(RegExp(r'[^0-9.]'), ''),
                    'unit': 'g',
                    'icon': Icons.fitness_center,
                    'color': Colors.red,
                  },
                  {
                    'title': 'Carbs',
                    'value': carbs.replaceAll(RegExp(r'[^0-9.]'), ''),
                    'unit': 'g',
                    'icon': Icons.grain,
                    'color': Colors.brown,
                  },
                  {
                    'title': 'Fat',
                    'value': fats.replaceAll(RegExp(r'[^0-9.]'), ''),
                    'unit': 'g',
                    'icon': Icons.opacity,
                    'color': Colors.blue,
                  },
                ];
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final double delayedStart = _staggerDelays[index] / 1000;
                    final double delayedEnd = delayedStart + 0.5;
                    final Animation<double> delayedAnimation = Tween<double>(
                      begin: 0.0,
                      end: 1.0,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          delayedStart,
                          delayedEnd,
                          curve: Curves.easeOut,
                        ),
                      ),
                    );
                    return Opacity(
                      opacity: delayedAnimation.value,
                      child: Transform.translate(
                        offset: Offset(50 * (1 - delayedAnimation.value), 0),
                        child: _buildMacroCard(
                          macroData[index]['title'],
                          macroData[index]['value'],
                          macroData[index]['unit'],
                          macroData[index]['icon'],
                          macroData[index]['color'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
              ),
            ),
            child: Text(
              'Nutrition Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final percentages = _calculateNutrientPercentages(protein, carbs, fats);
              final double progressAnimation = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                ),
              ).value;

              return Column(
                children: [
                  _buildNutrientProgressBar(
                      'Proteins',
                      percentages['Proteins']! * progressAnimation,
                      widget.customGreen,
                      protein,
                  ),
                  _buildNutrientProgressBar(
                      'Carbohydrates',
                      percentages['Carbohydrates']! * progressAnimation,
                      Colors.orange,
                      carbs,
                  ),
                  _buildNutrientProgressBar(
                      'Fats',
                      percentages['Fats']! * progressAnimation,
                      Colors.red,
                      fats,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
          const SizedBox(height: 30),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                margin: const EdgeInsets.only(bottom: 30),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.95, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      // Fetch user's goal
                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get();
                      final userGoal =
                          userDoc.data()?['goal']?.toString() ?? '';
                      if (userGoal.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('No goal set for user.')),
                        );
                        return;
                      }
                      // Fetch goal nutrition
                      final goalDoc = await FirebaseFirestore.instance
                          .collection('goals')
                          .doc(userGoal)
                          .get();
                      final goalNutrition = goalDoc.data() ?? {};
                      // Prepare meal nutrition
                      final mealNutrition = {
                        'calories': calories,
                        'protein': protein,
                        'carbs': carbs,
                        'fats': fats,
                        'mealName': mealName, // Pass meal name for display
                      };
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                            return FadeTransition(
                              opacity: animation,
                              child: MealComparisonPage(
                                mealImage: widget.mealImage,
                                mealNutrition: mealNutrition,
                                goalNutrition: goalNutrition,
                                goalName: userGoal,
                                mealName:
                                    mealName, // Pass meal name as argument
                              ),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.customGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Compare',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // First, calculate the percentages based on recommended daily values
  Map<String, double> _calculateNutrientPercentages(String protein, String carbs, String fats) {
    // Recommended Daily Values (in grams)
    const double recommendedProtein = 50.0;
    const double recommendedCarbs = 275.0;
    const double recommendedFats = 78.0;

    // Convert string values to double
    double proteinValue = double.tryParse(protein.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    double carbsValue = double.tryParse(carbs.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    double fatsValue = double.tryParse(fats.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    // Calculate percentages
    return {
      'Proteins': (proteinValue / recommendedProtein).clamp(0.0, 1.0),
      'Carbohydrates': (carbsValue / recommendedCarbs).clamp(0.0, 1.0),
      'Fats': (fatsValue / recommendedFats).clamp(0.0, 1.0),
    };
  }

  Widget _buildMacroCard(
      String title, String value, String unit, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween:
                    Tween<double>(begin: 0, end: double.tryParse(value) ?? 0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (context, animValue, child) {
                  // Check if the value has a decimal component
                  String displayValue;
                  if (animValue.toStringAsFixed(1) !=
                      animValue.toStringAsFixed(0)) {
                    // Value has decimal component, show one decimal place
                    displayValue = animValue.toStringAsFixed(1);
                  } else {
                    // Value is a whole number, don't show decimal place
                    displayValue = animValue.toStringAsFixed(0);
                  }
                  return Text(
                    displayValue,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientProgressBar(String label, double value, Color color, String actualValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${actualValue.replaceAll(RegExp(r'[^0-9.]'), '')}g',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: value),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, child) {
                  return FractionallySizedBox(
                    widthFactor: animValue,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}