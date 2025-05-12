import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealComparisonPage extends StatefulWidget {
  final File? mealImage;
  final Map<String, dynamic>? mealNutrition;
  final Map<String, dynamic>? goalNutrition;
  final String? goalName;
  final String? mealName; // Add this line
  const MealComparisonPage({
    super.key,
    required this.mealImage,
    this.mealNutrition,
    this.goalNutrition,
    this.goalName,
    this.mealName, // Add this line
  });

  @override
  State<MealComparisonPage> createState() => _MealComparisonPageState();
}

class _MealComparisonPageState extends State<MealComparisonPage> {
  final Color customGreen = const Color(0xFF86BF3E);
  String selectedGoal = 'Cholesterol Patients';
  Map<String, dynamic>? mealNutrition;
  Map<String, dynamic>? goalNutrition;
  Map<String, dynamic>? recommendedMealNutrition;
  String? mealName;
  bool isLoading = true;
  List<String> availableGoals = [];
  List<Map<String, dynamic>> recommendedMeals = [];

  @override
  void initState() {
    super.initState();
    if (widget.mealNutrition != null && widget.goalNutrition != null) {
      mealNutrition = widget.mealNutrition;
      goalNutrition = widget.goalNutrition;
      selectedGoal = widget.goalName ?? selectedGoal;
      // Extract and normalize mealName
      mealName = _extractAndNormalizeMealName(widget.mealNutrition);
      isLoading = false;
      _fetchGoals();
      // Fetch recommended meal for direct compare mode
      if (mealName != null && mealName!.isNotEmpty) {
        _fetchRecommendedMeal(selectedGoal, mealName!);
      }
      _fetchRecommendedMealsList(selectedGoal); // Fetch all recommended meals for the goal
    } else {
      _fetchGoalsAndData();
    }
  }

  // Helper to robustly extract meal name from nutrition map (no underscore normalization)
  String? _extractAndNormalizeMealName(Map<String, dynamic>? nutrition) {
    if (nutrition == null) return null;
    // Try common keys
    for (final key in ['name', 'mealName', 'title', 'MealName', 'meal_name']) {
      if (nutrition.containsKey(key) && nutrition[key] != null && nutrition[key].toString().trim().isNotEmpty) {
        return nutrition[key].toString().trim();
      }
    }
    // Fallback: if only one key and it's not a nutrition field, use it
    if (nutrition.length == 1) {
      final k = nutrition.keys.first;
      if (!['calories', 'protein', 'carbs', 'fat', 'Calories', 'Protein', 'Carbs', 'Fat'].contains(k)) {
        return nutrition[k].toString().trim();
      }
    }
    return null;
  }

  // Fetch recommended meal nutrition for a mealName from top-level meals collection (to match MealResultPage)
  Future<void> _fetchRecommendedMeal(String goal, String mealName) async {
    setState(() => isLoading = true);
    final docId = mealName.trim();
    print('[DEBUG] Fetching recommended meal (top-level meals): mealName="$mealName", docId="$docId"');
    final recommendedMealSnap = await FirebaseFirestore.instance
        .collection('meals')
        .doc(docId)
        .get();
    print('[DEBUG] Firestore doc exists: ' + recommendedMealSnap.exists.toString());
    print('[DEBUG] Firestore doc data: ' + (recommendedMealSnap.data()?.toString() ?? 'null'));
    setState(() {
      recommendedMealNutrition = recommendedMealSnap.data();
      isLoading = false;
    });
  }

  Future<void> _fetchGoals() async {
    final goalsSnap = await FirebaseFirestore.instance.collection('goals').get();
    setState(() {
      availableGoals = goalsSnap.docs.map((doc) => doc.id).toList();
      if (!availableGoals.contains(selectedGoal) && availableGoals.isNotEmpty) {
        selectedGoal = availableGoals.first;
      }
    });
  }

  Future<void> _fetchGoalsAndData() async {
    if (widget.mealNutrition != null && widget.goalNutrition != null) {
      // Already set in initState
      return;
    }
    // Fetch available goals dynamically
    final goalsSnap = await FirebaseFirestore.instance.collection('goals').get();
    setState(() {
      availableGoals = goalsSnap.docs.map((doc) => doc.id).toList();
      if (!availableGoals.contains(selectedGoal) && availableGoals.isNotEmpty) {
        selectedGoal = availableGoals.first;
      }
    });
    await _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.mealNutrition != null && widget.goalNutrition != null) {
      // Already set in initState
      return;
    }
    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    // Get latest scanned meal name
    final scanedMealSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('scaned-meal')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (scanedMealSnap.docs.isEmpty) {
      setState(() {
        mealName = null;
        mealNutrition = null;
        goalNutrition = null;
        recommendedMealNutrition = null;
        isLoading = false;
      });
      return;
    }
    mealName = scanedMealSnap.docs.first.data()['name'];
    if (mealName == null || (mealName is String && (mealName as String).trim().isEmpty)) {
      setState(() {
        mealNutrition = null;
        goalNutrition = null;
        recommendedMealNutrition = null;
        isLoading = false;
      });
      return;
    }
    // Get meal nutrition from top-level meals collection
    final mealSnap = await FirebaseFirestore.instance
        .collection('meals')
        .doc(mealName)
        .get();
    mealNutrition = mealSnap.data() ?? {};
    // Get goal nutrition
    final goalSnap = await FirebaseFirestore.instance
        .collection('goals')
        .doc(selectedGoal)
        .get();
    goalNutrition = goalSnap.data() ?? {};
    // Fetch recommended meal nutrition from top-level meals collection
    final recommendedMealSnap = await FirebaseFirestore.instance
        .collection('meals')
        .doc(mealName)
        .get();
    recommendedMealNutrition = recommendedMealSnap.data();
    setState(() => isLoading = false);
  }

  // Fetch all recommended meals for a goal
  Future<void> _fetchRecommendedMealsList(String goal) async {
    setState(() => isLoading = true);
    final mealsSnap = await FirebaseFirestore.instance
        .collection('goals')
        .doc(goal)
        .collection('meals')
        .get();
    recommendedMeals = mealsSnap.docs.map((doc) {
      final data = doc.data();
      data['mealName'] = doc.id;
      return data;
    }).toList();
    setState(() => isLoading = false);
  }

  int _parseValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final digits = RegExp(r'\d+').stringMatch(value);
      return digits != null ? int.tryParse(digits) ?? 0 : 0;
    }
    return 0;
  }

  // Helper to robustly get nutrition field value from a map
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
    // Always use widget.mealNutrition and widget.goalNutrition if provided
    final Map<String, dynamic>? effectiveMealNutrition = widget.mealNutrition ?? mealNutrition;
    final Map<String, dynamic>? effectiveGoalNutrition = widget.goalNutrition ?? goalNutrition;
    final String effectiveGoal = widget.goalName ?? selectedGoal;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Meal Comparison'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : effectiveMealNutrition == null || effectiveGoalNutrition == null
              ? const Center(child: Text('No meal or goal data found.'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Remove the goal selector dropdown and just show the selected goal
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Text('Goal: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text(
                              effectiveGoal,
                              style: TextStyle(fontWeight: FontWeight.bold, color: customGreen, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      // ...existing code for header...
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Your Meal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      (effectiveMealNutrition != null && effectiveMealNutrition.containsKey('mealName') && effectiveMealNutrition['mealName'].toString().isNotEmpty)
                                          ? effectiveMealNutrition['mealName'].toString()
                                          : (widget.mealName ?? mealName ?? '(no meal name)'),
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: customGreen),
                                    ),
                                  ),
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: widget.mealImage != null
                                          ? DecorationImage(image: FileImage(widget.mealImage!), fit: BoxFit.cover)
                                          : null,
                                      color: Colors.grey[200],
                                    ),
                                    child: widget.mealImage == null
                                        ? const Center(child: Icon(Icons.fastfood, size: 40, color: Colors.grey))
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Card(
                                    color: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Meal Nutrition', style: TextStyle(fontWeight: FontWeight.bold, color: customGreen)),
                                          const SizedBox(height: 4),
                                          _buildMealNutritionRow('Calories', _parseValue(_getFieldValue(effectiveMealNutrition, ['calories', 'Calories', 'calorie', 'Calorie'])).toString(), 'kcal'),
                                          _buildMealNutritionRow('Protein', _parseValue(_getFieldValue(effectiveMealNutrition, ['Protein', 'Protein', 'Protien', 'Protien'])).toString(), 'g'),
                                          _buildMealNutritionRow('Carbs', _parseValue(_getFieldValue(effectiveMealNutrition, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])).toString(), 'g'),
                                          _buildMealNutritionRow('Fat', _parseValue(_getFieldValue(effectiveMealNutrition, ['fat', 'Fat', 'fats', 'Fats'])).toString(), 'g'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: customGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.compare_arrows, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  Text('Recommended', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                  const SizedBox(height: 8),
                                  // Show actual goal and mealName for debugging
                                  Text('Goal: $selectedGoal', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  Text('Meal: ${mealName ?? "(none)"}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  // Show the recommended meal name if available
                                  if (recommendedMealNutrition != null && (recommendedMealNutrition!['name'] != null || recommendedMealNutrition!['mealName'] != null))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                                      child: Text(
                                        recommendedMealNutrition!['name']?.toString() ?? recommendedMealNutrition!['mealName']?.toString() ?? '',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: customGreen),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: customGreen.withOpacity(0.1),
                                      image: const DecorationImage(
                                        image: NetworkImage('https://example.com/healthy-meal.jpg'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Card(
                                    color: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      child: recommendedMealNutrition != null
                                          ? (recommendedMealNutrition!.isNotEmpty
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Recommended Nutrition', style: TextStyle(fontWeight: FontWeight.bold, color: customGreen)),
                                                    const SizedBox(height: 4),
                                                    _buildMealNutritionRow('Calories', _parseValue(_getFieldValue(recommendedMealNutrition!, ['calories', 'Calories', 'calorie', 'Calorie'])).toString(), 'kcal'),
                                                    _buildMealNutritionRow('Protein', _parseValue(_getFieldValue(recommendedMealNutrition!, ['protein', 'Protein', 'protien', 'Protien'])).toString(), 'g'),
                                                    _buildMealNutritionRow('Carbs', _parseValue(_getFieldValue(recommendedMealNutrition!, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])).toString(), 'g'),
                                                    _buildMealNutritionRow('Fat', _parseValue(_getFieldValue(recommendedMealNutrition!, ['fat', 'Fat', 'fats', 'Fats'])).toString(), 'g'),
                                                  ],
                                                )
                                              : const Text('No nutrition data in Firestore for this meal (document exists but is empty).'))
                                          : const Text('No recommended meal found for this goal and meal name (document not found).'),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                        
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Nutrition Comparison
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nutrition Comparison', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User Meal Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Your Meal', style: TextStyle(fontWeight: FontWeight.bold, color: customGreen)),
                                          const SizedBox(height: 8),
                                          _buildMealNutritionRow('Calories', _parseValue(_getFieldValue(effectiveMealNutrition, ['calories', 'Calories', 'calorie', 'Calorie'])).toString(), 'kcal'),
                                          _buildMealNutritionRow('Protein', _parseValue(_getFieldValue(effectiveMealNutrition, ['protein', 'Protein', 'protien', 'Protien'])).toString(), 'g'),
                                          _buildMealNutritionRow('Carbs', _parseValue(_getFieldValue(effectiveMealNutrition, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])).toString(), 'g'),
                                          _buildMealNutritionRow('Fat', _parseValue(_getFieldValue(effectiveMealNutrition, ['fat', 'Fat', 'fats', 'Fats'])).toString(), 'g'),
                                        ],
                                      ),
                                    ),
                                    Container(width: 1, height: 80, color: Colors.grey[300]),
                                    // Recommended Meal Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Recommended', style: TextStyle(fontWeight: FontWeight.bold, color: customGreen)),
                                          const SizedBox(height: 8),
                                          recommendedMealNutrition != null && recommendedMealNutrition!.isNotEmpty
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    _buildMealNutritionRow('Calories', _parseValue(_getFieldValue(recommendedMealNutrition!, ['calories', 'Calories', 'calorie', 'Calorie'])).toString(), 'kcal'),
                                                    _buildMealNutritionRow('Protein', _parseValue(_getFieldValue(recommendedMealNutrition!, ['protein', 'Protein', 'protien', 'Protien'])).toString(), 'g'),
                                                    _buildMealNutritionRow('Carbs', _parseValue(_getFieldValue(recommendedMealNutrition!, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])).toString(), 'g'),
                                                    _buildMealNutritionRow('Fat', _parseValue(_getFieldValue(recommendedMealNutrition!, ['fat', 'Fat', 'fats', 'Fats'])).toString(), 'g'),
                                                  ],
                                                )
                                              : const Text('No recommended meal data'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // ...existing code for macro-by-macro comparison rows...
                                _buildComparisonRow(
                                  'Calories',
                                  _parseValue(_getFieldValue(effectiveMealNutrition, ['calories', 'Calories', 'calorie', 'Calorie'])).toString(),
                                  _parseValue(_getFieldValue(effectiveGoalNutrition, ['calories', 'Calories', 'calorie', 'Calorie'])).toString(),
                                  _parseValue(_getFieldValue(effectiveMealNutrition, ['calories', 'Calories', 'calorie', 'Calorie'])) > _parseValue(_getFieldValue(effectiveGoalNutrition, ['calories', 'Calories', 'calorie', 'Calorie'])),
                                ),
                                _buildComparisonRow(
                                  'Protein',
                                  _parseValue(_getFieldValue(effectiveMealNutrition, ['protein', 'Protein', 'protien', 'Protien'])).toString() + 'g',
                                  _parseValue(_getFieldValue(effectiveGoalNutrition, ['protein', 'Protein', 'protien', 'Protien'])).toString() + 'g',
                                  _parseValue(_getFieldValue(effectiveMealNutrition, ['protein', 'Protein', 'protien', 'Protien'])) < _parseValue(_getFieldValue(effectiveGoalNutrition, ['protein', 'Protein', 'protien', 'Protien'])),
                                ),
                                _buildComparisonRow(
                                  'Carbs',
                                  _parseValue(_getFieldValue(effectiveMealNutrition, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])).toString() + 'g',
                                  _parseValue(_getFieldValue(effectiveGoalNutrition, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])).toString() + 'g',
                                  _parseValue(_getFieldValue(effectiveMealNutrition, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])) > _parseValue(_getFieldValue(effectiveGoalNutrition, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])),
                                ),
                                _buildComparisonRow(
                                  'Fat',
                                  _parseValue(_getFieldValue(effectiveMealNutrition, ['fat', 'Fat', 'fats', 'Fats'])).toString() + 'g',
                                  _parseValue(_getFieldValue(effectiveGoalNutrition, ['fat', 'Fat', 'fats', 'Fats'])).toString() + 'g',
                                  _parseValue(_getFieldValue(effectiveMealNutrition, ['fat', 'Fat', 'fats', 'Fats'])) > _parseValue(_getFieldValue(effectiveGoalNutrition, ['fat', 'Fat', 'fats', 'Fats'])),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // ...existing code for health score and suggestions...
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Health Score', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildScoreIndicator('Your Meal', 75),
                                    Container(width: 1, height: 100, color: Colors.grey[300]),
                                    _buildScoreIndicator('Recommended', 95),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Suggestions for Improvement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                const SizedBox(height: 16),
                                _buildSuggestionItem('Reduce Calories', 'Try using less oil in preparation', Icons.local_fire_department),
                                _buildSuggestionItem('Increase Protein', 'Add lean meat or legumes', Icons.fitness_center),
                                _buildSuggestionItem('More Fiber', 'Include more vegetables', Icons.eco),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    String currentValue,
    String recommendedValue,
    bool isHigher,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentValue,
                  style: TextStyle(
                    fontSize: 16,
                    color: isHigher ? Colors.red : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  isHigher
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: isHigher ? Colors.red : customGreen,
                  size: 20,
                ),
                Text(
                  recommendedValue,
                  style: TextStyle(
                    fontSize: 16,
                    color: customGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(String label, int score) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  score > 80 ? customGreen : Colors.orange,
                ),
              ),
            ),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: customGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: customGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealNutritionRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: customGreen)),
          const SizedBox(width: 2),
          Text(unit, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }
}