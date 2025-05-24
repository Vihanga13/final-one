import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bottom_navbar.dart'; // Import the custom bottom navigation bar

class MealComparisonPage extends StatefulWidget {
  final File? mealImage;
  final Map<String, dynamic>? mealNutrition;
  final Map<String, dynamic>? goalNutrition;
  final String? goalName;
  final String? mealName;
  const MealComparisonPage({
    super.key,
    required this.mealImage,
    this.mealNutrition,
    this.goalNutrition,
    this.goalName,
    this.mealName,
  });

  @override
  State<MealComparisonPage> createState() => _MealComparisonPageState();
}

class _MealComparisonPageState extends State<MealComparisonPage> with SingleTickerProviderStateMixin {
  final Color customGreen = const Color(0xFF86BF3E);
  String selectedGoal = 'Cholesterol Patients';
  Map<String, dynamic>? mealNutrition;
  Map<String, dynamic>? goalNutrition;
  Map<String, dynamic>? recommendedMealNutrition;
  String? mealName;
  String? mealImageUrl;
  bool isLoading = true;
  List<String> availableGoals = [];
  List<Map<String, dynamic>> recommendedMeals = [];
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Delay animation to start after data is loaded
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animationController.forward();
    });

    // Prioritize widget values if passed directly for the scanned meal
    if (widget.mealName != null && widget.mealNutrition != null) {
      mealNutrition = widget.mealNutrition;
      mealName = widget.mealName;
      selectedGoal = widget.goalName ?? 'Cholesterol Patients';
      goalNutrition = widget.goalNutrition;
      _initializePageData();
    } else {
      // Navigating without direct meal data, fetch latest scanned meal and other data
      selectedGoal = widget.goalName ?? 'Cholesterol Patients';
      _initializePageData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializePageData() async {
    if (mounted) setState(() => isLoading = true);

    // 1. Fetch available goals
    await _fetchGoals();

    // 2. Fetch scanned meal data if not provided by widget
    if (mealNutrition == null || mealName == null) {
      await _fetchLatestScannedMealData();
    }

    // 3. Ensure goalNutrition for the selectedGoal is fetched
    if (goalNutrition == null &&
        selectedGoal.isNotEmpty &&
        availableGoals.contains(selectedGoal)) {
      await _fetchGoalNutrition(selectedGoal);
    }

    // 4. Ensure recommended meals for the selectedGoal are fetched
    if (recommendedMeals.isEmpty &&
        selectedGoal.isNotEmpty &&
        availableGoals.contains(selectedGoal)) {
      await _fetchRecommendedMealsList(selectedGoal);
    }

    // Setup score animation after data is loaded
    int yourScore = _calculateHealthScore(mealNutrition ?? {});
    int recommendedScore = _calculateHealthScore(recommendedMealNutrition ?? {});
    
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart)
    );

    if (mounted) setState(() => isLoading = false);
  }

  // Calculate a health score based on nutrition values
  int _calculateHealthScore(Map<String, dynamic> meal, {bool isRecommended = false, Map<String, dynamic>? recommended}) {
    if (isRecommended) return 100;
    if (meal.isEmpty) return 0;

    // Get recommended values (if not provided, use some defaults)
    final rec = recommended ?? {
      'calories': 500.0,
      'protein': 20.0,
      'carbs': 50.0,
      'fat': 15.0,
    };

    double mealCalories = _parseValue(_getFieldValue(meal, ['calories', 'Calories', 'calorie', 'Calorie']));
    double mealProtein = _parseValue(_getFieldValue(meal, ['protein', 'Protein', 'protien', 'Protien']));
    double mealCarbs = _parseValue(_getFieldValue(meal, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb']));
    double mealFat = _parseValue(_getFieldValue(meal, ['fat', 'Fat', 'fats', 'Fats']));

    double recCalories = _parseValue(_getFieldValue(rec, ['calories', 'Calories', 'calorie', 'Calorie']));
    double recProtein = _parseValue(_getFieldValue(rec, ['protein', 'Protein', 'protien', 'Protien']));
    double recCarbs = _parseValue(_getFieldValue(rec, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb']));
    double recFat = _parseValue(_getFieldValue(rec, ['fat', 'Fat', 'fats', 'Fats']));

    // Calculate percent differences
    double calDiff = ((mealCalories - recCalories).abs() / (recCalories == 0 ? 1 : recCalories)) * 100;
    double proteinDiff = ((mealProtein - recProtein).abs() / (recProtein == 0 ? 1 : recProtein)) * 100;
    double carbsDiff = ((mealCarbs - recCarbs).abs() / (recCarbs == 0 ? 1 : recCarbs)) * 100;
    double fatDiff = ((mealFat - recFat).abs() / (recFat == 0 ? 1 : recFat)) * 100;

    // Start from 100, subtract points for deviation
    double score = 100;
    score -= calDiff * 0.3;      // Calories are important
    score -= proteinDiff * 0.2;  // Protein is important
    score -= carbsDiff * 0.2;    // Carbs moderate
    score -= fatDiff * 0.3;      // Fat is important

    // Clamp score between 0 and 100
    score = score.clamp(0, 100);
    return score.round();
  }

  Future<void> _fetchLatestScannedMealData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final scanedMealSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('scaned-meal')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (scanedMealSnap.docs.isEmpty) return;

    final scannedMealData = scanedMealSnap.docs.first.data();
    final fetchedImageUrl = scannedMealData['imageUrl']?.toString();

    if (mounted) setState(() {
      mealImageUrl = fetchedImageUrl;
      // Optionally set mealName, mealNutrition, etc.
    });
  }

  Future<void> _fetchGoals() async {
    final goalsSnap =
        await FirebaseFirestore.instance.collection('goals').get();
    final newAvailableGoals = goalsSnap.docs.map((doc) => doc.id).toList();
    String newSelectedGoal = selectedGoal;
    bool goalHasChanged = false;

    if (mounted) {
      setState(() {
        availableGoals = newAvailableGoals;
        if (availableGoals.isEmpty) {
          newSelectedGoal = '';
          goalNutrition = null;
          recommendedMeals = [];
          recommendedMealNutrition = null;
        } else if (!availableGoals.contains(newSelectedGoal)) {
          newSelectedGoal = availableGoals.first;
        }

        if (selectedGoal != newSelectedGoal) {
          selectedGoal = newSelectedGoal;
          goalHasChanged = true;
        }
      });
    }

    if (selectedGoal.isNotEmpty && (goalHasChanged || goalNutrition == null)) {
      await _fetchGoalNutrition(selectedGoal);
    }
    if (selectedGoal.isNotEmpty &&
        (goalHasChanged || recommendedMeals.isEmpty)) {
      await _fetchRecommendedMealsList(selectedGoal);
    }
  }

  Future<void> _fetchGoalNutrition(String goalName) async {
    if (goalName.isEmpty) {
      if (mounted) setState(() => goalNutrition = null);
      return;
    }
    final goalSnap = await FirebaseFirestore.instance
        .collection('goals')
        .doc(goalName)
        .get();
    if (mounted) {
      setState(() {
        goalNutrition = goalSnap.data() ?? {};
      });
    }
  }

  Future<void> _fetchRecommendedMealsList(String goalName) async {
    if (goalName.isEmpty) {
      if (mounted) {
        setState(() {
          recommendedMeals = [];
          recommendedMealNutrition = null;
        });
      }
      return;
    }

    final mealsSnap = await FirebaseFirestore.instance
        .collection('goals')
        .doc(goalName)
        .collection('meals')
        .get();

    final newRecommendedMeals = mealsSnap.docs.map((doc) {
      final data = doc.data();
      data['mealName'] = doc.id;
      return data;
    }).toList();

    if (mounted) {
      setState(() {
        recommendedMeals = newRecommendedMeals;

        // Try to find a recommended meal that matches the scanned meal's name
        Map<String, dynamic>? matchedMeal;
        if (mealName != null && mealName!.isNotEmpty) {
          try {
            matchedMeal = newRecommendedMeals.firstWhere(
              (recMeal) => recMeal['mealName'] == mealName,
            );
          } catch (e) {
            matchedMeal = null;
          }
        }

        if (matchedMeal != null) {
          recommendedMealNutrition = matchedMeal;
        } else if (recommendedMeals.isNotEmpty) {
          recommendedMealNutrition = recommendedMeals.first;
        } else {
          recommendedMealNutrition = null;
        }
      });
    }
  }

  double _parseValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      final digitsWithDecimal = RegExp(r'\d+\.\d+|\d+').stringMatch(value);
      return digitsWithDecimal != null
          ? double.tryParse(digitsWithDecimal) ?? 0
          : 0;
    }
    return 0;
  }

  dynamic _getFieldValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    // Always use widget.mealNutrition and widget.goalNutrition if provided
    final Map<String, dynamic>? effectiveMealNutrition =
        widget.mealNutrition ?? mealNutrition;
    final Map<String, dynamic>? effectiveGoalNutrition =
        widget.goalNutrition ?? goalNutrition;
    final String effectiveGoal = widget.goalName ?? selectedGoal;
    
    // Calculate health scores
    final int yourScore = effectiveMealNutrition != null ? 
        _calculateHealthScore(effectiveMealNutrition, recommended: recommendedMealNutrition) : 0;
    final int recommendedScore = recommendedMealNutrition != null ?
        _calculateHealthScore(recommendedMealNutrition!, isRecommended: true) : 100;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Meal Comparison',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(customGreen),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Analyzing nutrition data...',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : effectiveMealNutrition == null || effectiveGoalNutrition == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_food, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No meal or goal data found.',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: customGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Goal Header with Card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.flag_rounded, color: customGreen, size: 28),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Goal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    effectiveGoal,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: customGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Main Comparison Section
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              const Text(
                                'Meal Comparison',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Your Meal vs Recommended
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Your Meal
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                              decoration: BoxDecoration(
                                                color: customGreen.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Your Meal',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: customGreen,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Show meal name
                                        Text(
                                          (widget.mealName ?? mealName ?? 'Unknown Meal').toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline,
                                                    size: 16,
                                                    color: customGreen,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Nutrition Facts',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Divider(color: Colors.grey[300]),
                                              const SizedBox(height: 4),
                                              _buildNutritionItem(
                                                'Calories',
                                                _parseValue(_getFieldValue(effectiveMealNutrition, [
                                                  'calories', 'Calories', 'calorie', 'Calorie'
                                                ])).toString(),
                                                'kcal',
                                              ),
                                              _buildNutritionItem(
                                                'Protein',
                                                _parseValue(_getFieldValue(effectiveMealNutrition, [
                                                  'protein', 'Protein', 'protien', 'Protien'
                                                ])).toString(),
                                                'g',
                                              ),
                                              _buildNutritionItem(
                                                'Carbs',
                                                _parseValue(_getFieldValue(effectiveMealNutrition, [
                                                  'carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'
                                                ])).toString(),
                                                'g',
                                              ),
                                              _buildNutritionItem(
                                                'Fat',
                                                _parseValue(_getFieldValue(effectiveMealNutrition, [
                                                  'fat', 'Fat', 'fats', 'Fats'
                                                ])).toString(),
                                                'g',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Center VS
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: SizedBox(width: 0), // No VS icon or image
                                  ),
                                  
                                  // Recommended Meal
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Recommended',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Show recommended meal name if available
                                        Text(
                                          (recommendedMealNutrition != null && recommendedMealNutrition!['mealName'] != null)
                                              ? recommendedMealNutrition!['mealName'].toString()
                                              : 'Recommended Meal',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // No image for recommended meal
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Nutrition Facts',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Divider(color: Colors.grey[300]),
                                              const SizedBox(height: 4),
                                              recommendedMealNutrition != null
                                                  ? Column(
                                                      children: [
                                                        _buildNutritionItem(
                                                          'Calories',
                                                          _parseValue(_getFieldValue(recommendedMealNutrition!, [
                                                            'calories', 'Calories', 'calorie', 'Calorie'
                                                          ])).toString(),
                                                          'kcal',
                                                          color: Colors.blue,
                                                        ),
                                                        _buildNutritionItem(
                                                          'Protein',
                                                          _parseValue(_getFieldValue(recommendedMealNutrition!, [
                                                            'protein', 'Protein', 'protien', 'Protien'
                                                          ])).toString(),
                                                          'g',
                                                          color: Colors.blue,
                                                        ),
                                                        _buildNutritionItem(
                                                          'Carbs',
                                                          _parseValue(_getFieldValue(recommendedMealNutrition!, [
                                                            'carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'
                                                          ])).toString(),
                                                          'g',
                                                          color: Colors.blue,
                                                        ),
                                                        _buildNutritionItem(
                                                          'Fat',
                                                          _parseValue(_getFieldValue(recommendedMealNutrition!, [
                                                            'fat', 'Fat', 'fats', 'Fats'
                                                          ])).toString(),
                                                          'g',
                                                          color: Colors.blue,
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      'No recommended nutrition data available',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                            ],
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

                      // Detailed Nutrition Comparison
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.equalizer, color: customGreen, size: 24),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Detailed Comparison',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                               'See how your meal compares to the recommended option',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Comparison bars
                              _buildNutritionComparisonBar(
                                'Calories',
                                _parseValue(_getFieldValue(effectiveMealNutrition, [
                                  'calories', 'Calories', 'calorie', 'Calorie'
                                ])),
                                _parseValue(_getFieldValue(recommendedMealNutrition ?? {}, [
                                  'calories', 'Calories', 'calorie', 'Calorie'
                                ])),
                                unit: 'kcal',
                                mealColor: customGreen,
                                recommendedColor: Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              _buildNutritionComparisonBar(
                                'Protein',
                                _parseValue(_getFieldValue(effectiveMealNutrition, [
                                  'protein', 'Protein', 'protien', 'Protien'
                                ])),
                                _parseValue(_getFieldValue(recommendedMealNutrition ?? {}, [
                                  'protein', 'Protein', 'protien', 'Protien'
                                ])),
                                unit: 'g',
                                mealColor: customGreen,
                                recommendedColor: Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              _buildNutritionComparisonBar(
                                'Carbs',
                                _parseValue(_getFieldValue(effectiveMealNutrition, [
                                  'carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'
                                ])),
                                _parseValue(_getFieldValue(recommendedMealNutrition ?? {}, [
                                  'carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'
                                ])),
                                unit: 'g',
                                mealColor: customGreen,
                                recommendedColor: Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              _buildNutritionComparisonBar(
                                'Fat',
                                _parseValue(_getFieldValue(effectiveMealNutrition, [
                                  'fat', 'Fat', 'fats', 'Fats'
                                ])),
                                _parseValue(_getFieldValue(recommendedMealNutrition ?? {}, [
                                  'fat', 'Fat', 'fats', 'Fats'
                                ])),
                                unit: 'g',
                                mealColor: customGreen,
                                recommendedColor: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Health Score Card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.favorite, color: Colors.redAccent, size: 24),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Health Score',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'How healthy is your meal for your goals?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 30),
                              
                              // Health Score Meters
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  // Your Meal Score
                                  Column(
                                    children: [
                                      Text(
                                        'Your Meal',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      AnimatedBuilder(
                                        animation: _scoreAnimation,
                                        builder: (context, child) {
                                          return SizedBox(
                                            height: 120,
                                            width: 120,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Background circle
                                                Container(
                                                  height: 120,
                                                  width: 120,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                // Progress circle
                                                SizedBox(
                                                  height: 120,
                                                  width: 120,
                                                  child: CircularProgressIndicator(
                                                    value: _scoreAnimation.value * (yourScore / 100),
                                                    strokeWidth: 12,
                                                    backgroundColor: Colors.transparent,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      yourScore >= 80 
                                                          ? Colors.green 
                                                          : yourScore >= 60 
                                                              ? Colors.amber
                                                              : Colors.redAccent
                                                    ),
                                                  ),
                                                ),
                                                // Score text
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      (yourScore * _scoreAnimation.value).toInt().toString(),
                                                      style: const TextStyle(
                                                        fontSize: 32,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const Text(
                                                      '/100',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  
                                  // Recommended Meal Score
                                  Column(
                                    children: [
                                      Text(
                                        'Recommended',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      AnimatedBuilder(
                                        animation: _scoreAnimation,
                                        builder: (context, child) {
                                          return SizedBox(
                                            height: 120,
                                            width: 120,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Background circle
                                                Container(
                                                  height: 120,
                                                  width: 120,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                // Progress circle
                                                SizedBox(
                                                  height: 120,
                                                  width: 120,
                                                  child: CircularProgressIndicator(
                                                    value: _scoreAnimation.value * (recommendedScore / 100),
                                                    strokeWidth: 12,
                                                    backgroundColor: Colors.transparent,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                                  ),
                                                ),
                                                // Score text
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      (recommendedScore * _scoreAnimation.value).toInt().toString(),
                                                      style: const TextStyle(
                                                        fontSize: 32,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const Text(
                                                      '/100',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 30),
                              
                              // Add Finish Button
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(context, '/main_screen');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: customGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Finish',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20), // Add some bottom padding
                            ],
                          ),
                        ),
                      ),
                      
                      // Add the floating action button here
                    ],
                  ),
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

  Widget _buildNutritionItem(String name, String value, String unit, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            "$value $unit",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionComparisonBar(
    String label,
    double yourValue,
    double recommendedValue, {
    required String unit,
    required Color mealColor,
    required Color recommendedColor,
  }) {
    // Calculate the max value for scaling the bars
    // Use at least 10 as a minimum to avoid empty bars
    double maxValue = max(yourValue, recommendedValue) * 1.2;
    maxValue = max(maxValue, 10);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Your meal icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: mealColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.restaurant,
                color: mealColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Your meal bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Meal',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${yourValue.toStringAsFixed(1)} $unit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: mealColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          // Background
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          // Foreground
                          Container(
                            height: 12,
                            width: (yourValue / maxValue) * 
                                MediaQuery.of(context).size.width * 0.6 * 
                                _animationController.value,
                            decoration: BoxDecoration(
                              color: mealColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Recommended meal icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: recommendedColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.recommend,
                color: recommendedColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Recommended meal bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recommended',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${recommendedValue.toStringAsFixed(1)} $unit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: recommendedColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          // Background
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          // Foreground
                          Container(
                            height: 12,
                            width: (recommendedValue / maxValue) * 
                                MediaQuery.of(context).size.width * 0.6 * 
                                _animationController.value,
                            decoration: BoxDecoration(
                              color: recommendedColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisMessage(
    Map<String, dynamic>? mealNutrition,
    Map<String, dynamic>? recommendedNutrition,
    int yourScore,
    int recommendedScore,
    String goalName,
  ) {
    if (mealNutrition == null || recommendedNutrition == null) {
      return const Text('Not enough data for analysis.');
    }

    // Extract nutritional values
    double mealCalories = _parseValue(_getFieldValue(mealNutrition, ['calories', 'Calories', 'calorie', 'Calorie']));
    double mealProtein = _parseValue(_getFieldValue(mealNutrition, ['protein', 'Protein', 'protien', 'Protien']));
    double mealCarbs = _parseValue(_getFieldValue(mealNutrition, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb']));
    double mealFat = _parseValue(_getFieldValue(mealNutrition, ['fat', 'Fat', 'fats', 'Fats']));
    
    double recCalories = _parseValue(_getFieldValue(recommendedNutrition, ['calories', 'Calories', 'calorie', 'Calorie']));
    double recProtein = _parseValue(_getFieldValue(recommendedNutrition, ['protein', 'Protein', 'protien', 'Protien']));
    double recCarbs = _parseValue(_getFieldValue(recommendedNutrition, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb']));
    double recFat = _parseValue(_getFieldValue(recommendedNutrition, ['fat', 'Fat', 'fats', 'Fats']));

    // Calculate percentage differences
    double caloriesDiff = ((mealCalories - recCalories) / recCalories * 100).abs();
    double proteinDiff = ((mealProtein - recProtein) / recProtein * 100).abs();
    double carbsDiff = ((mealCarbs - recCarbs) / recCarbs * 100).abs();
    double fatDiff = ((mealFat - recFat) / recFat * 100).abs();

    // Generate analysis text
    String analysisText = '';
    
    // Score-based analysis
    if (yourScore >= 80) {
      analysisText = 'Great job! Your meal is well-aligned with your $goalName dietary goals. ';
    } else if (yourScore >= 60) {
      analysisText = 'Your meal is fairly good for your $goalName goals, but has room for improvement. ';
    } else {
      analysisText = 'This meal may not be ideal for your $goalName goals. Consider the recommended alternatives. ';
    }

    // Add specific nutrient analysis
    List<String> nutritionComments = [];
    
    if (caloriesDiff > 20) {
      if (mealCalories > recCalories) {
        nutritionComments.add('Your meal is higher in calories than recommended');
      } else {
        nutritionComments.add('Your meal is lower in calories than recommended');
      }
    }
    
    if (proteinDiff > 20) {
      if (mealProtein < recProtein) {
        nutritionComments.add('could benefit from more protein');
      } else {
        nutritionComments.add('has more protein than needed');
      }
    }
    
    if (carbsDiff > 20) {
      if (mealCarbs > recCarbs) {
        nutritionComments.add('is higher in carbohydrates than ideal');
      } else {
        nutritionComments.add('is lower in carbohydrates than recommended');
      }
    }
    
    if (fatDiff > 20) {
      if (mealFat > recFat) {
        nutritionComments.add('contains more fat than recommended');
      } else {
        nutritionComments.add('contains less fat than recommended');
      }
    }
    
    if (nutritionComments.isNotEmpty) {
      analysisText += 'Your meal ${nutritionComments.join(' and ')}.';
    }
    
    // Goal-specific advice
    if (goalName.toLowerCase().contains('diabetes') || 
        goalName.toLowerCase().contains('diabetic')) {
      analysisText += ' For diabetic needs, monitor carbohydrate intake carefully and focus on foods with a low glycemic index.';
    } else if (goalName.toLowerCase().contains('cholesterol')) {
      analysisText += ' For cholesterol management, focus on reducing saturated fats and increasing fiber intake.';
    } else if (goalName.toLowerCase().contains('weight') || 
               goalName.toLowerCase().contains('loss')) {
      analysisText += ' For weight management, maintain a calorie deficit while ensuring adequate protein intake to preserve muscle mass.';
    }

    return Text(
      analysisText,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  Widget _buildRecommendationsList(
    Map<String, dynamic>? mealNutrition,
    Map<String, dynamic>? recommendedNutrition,
    String goalName,
  ) {
    if (mealNutrition == null) {
      return const Text('Not enough data for recommendations.');
    }

    // Extract nutritional values
    double mealCalories = _parseValue(_getFieldValue(mealNutrition, ['calories', 'Calories', 'calorie', 'Calorie']));
    double mealProtein = _parseValue(_getFieldValue(mealNutrition, ['protein', 'Protein', 'protien', 'Protien']));
    double mealCarbs = _parseValue(_getFieldValue(mealNutrition, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb']));
    double mealFat = _parseValue(_getFieldValue(mealNutrition, ['fat', 'Fat', 'fats', 'Fats']));
    
    // Generate recommendations
    List<Map<String, dynamic>> recommendations = [];
    
    // Calories
    if (recommendedNutrition != null) {
      double recCalories = _parseValue(_getFieldValue(recommendedNutrition, ['calories', 'Calories', 'calorie', 'Calorie']));
      if (mealCalories > recCalories * 1.2) {
        recommendations.add({
          'title': 'Reduce Portion Size',
          'icon': Icons.fullscreen_exit,
          'description': 'Consider reducing your portion size slightly to lower calorie intake.',
        });
      } else if (mealCalories < recCalories * 0.8) {
        recommendations.add({
          'title': 'Increase Portion Size',
          'icon': Icons.fullscreen,
          'description': 'Your meal may be too light. Consider adding more healthy foods.',
        });
      }
    }
    
    // Protein
    if (mealProtein < 15) {
      recommendations.add({
        'title': 'Increase Protein',
        'icon': Icons.fitness_center,
        'description': 'Add lean protein sources like chicken, fish, tofu, or legumes.',
      });
    }
    
    // Carbs
    if (goalName.toLowerCase().contains('diabetes') && mealCarbs > 50) {
      recommendations.add({
        'title': 'Lower Carbohydrates',
        'icon': Icons.grain,
        'description': 'For diabetes management, consider reducing simple carbohydrates.',
      });
    }
    
    // Fat
    if (goalName.toLowerCase().contains('cholesterol') && mealFat > 20) {
      recommendations.add({
        'title': 'Choose Healthier Fats',
        'icon': Icons.opacity,
        'description': 'Replace saturated fats with heart-healthy fats from sources like avocados, nuts, and olive oil.',
      });
    }
    
    // General recommendations
    recommendations.add({
      'title': 'Add Vegetables',
      'icon': Icons.eco,
      'description': 'Increase your nutrient intake by adding more colorful vegetables to your meal.',
    });
    
    if (goalName.toLowerCase().contains('weight') || 
        goalName.toLowerCase().contains('loss')) {
      recommendations.add({
        'title': 'Focus on Fiber',
        'icon': Icons.grass,
        'description': 'Foods high in fiber help you feel full longer and can aid weight management.',
      });
    }
    
    // Limit to 3 recommendations
    recommendations = recommendations.take(3).toList();
    
    return Column(
      children: recommendations.map((rec) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: customGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  rec['icon'] as IconData,
                  color: customGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec['description'] as String,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Helper function for the max value
double max(double a, double b) {
  return a > b ? a : b;
}