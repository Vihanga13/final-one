import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealComparisonPage extends StatefulWidget {
  final File? mealImage;
  const MealComparisonPage({super.key, required this.mealImage});

  @override
  State<MealComparisonPage> createState() => _MealComparisonPageState();
}

class _MealComparisonPageState extends State<MealComparisonPage> {
  final Color customGreen = const Color(0xFF86BF3E);
  String selectedGoal = 'Cholesterol Patients';
  Map<String, dynamic>? mealNutrition;
  Map<String, dynamic>? goalNutrition;
  String? mealName;
  bool isLoading = true;
  List<String> availableGoals = [];

  @override
  void initState() {
    super.initState();
    _fetchGoalsAndData();
  }

  Future<void> _fetchGoalsAndData() async {
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
        isLoading = false;
      });
      return;
    }
    mealName = scanedMealSnap.docs.first.data()['name'];
    if (mealName == null || (mealName is String && (mealName as String).trim().isEmpty)) {
      setState(() {
        mealNutrition = null;
        goalNutrition = null;
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
    setState(() => isLoading = false);
  }

  void _onGoalChanged(String? newGoal) async {
    if (newGoal == null) return;
    setState(() => selectedGoal = newGoal);
    await _fetchData();
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
          : mealNutrition == null || goalNutrition == null
              ? const Center(child: Text('No meal or goal data found.'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Goal selector
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Text('Compare with: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: selectedGoal,
                              items: availableGoals
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: _onGoalChanged,
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
                                children: [
                                  Text('Your Meal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                  const SizedBox(height: 8),
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
                                _buildComparisonRow(
                                  'Calories',
                                  _parseValue(_getFieldValue(mealNutrition!, ['calories', 'Calories', 'calorie', 'Calorie'])).toString(),
                                  _parseValue(_getFieldValue(goalNutrition!, ['calories', 'Calories', 'calorie', 'Calorie'])).toString(),
                                  _parseValue(_getFieldValue(mealNutrition!, ['calories', 'Calories', 'calorie', 'Calorie'])) > _parseValue(_getFieldValue(goalNutrition!, ['calories', 'Calories', 'calorie', 'Calorie'])),
                                ),
                                _buildComparisonRow(
                                  'Protein',
                                  _parseValue(_getFieldValue(mealNutrition!, ['protein', 'Protein', 'protien', 'Protien'])).toString() + 'g',
                                  _parseValue(_getFieldValue(goalNutrition!, ['protein', 'Protein', 'protien', 'Protien'])).toString() + 'g',
                                  _parseValue(_getFieldValue(mealNutrition!, ['protein', 'Protein', 'protien', 'Protien'])) < _parseValue(_getFieldValue(goalNutrition!, ['protein', 'Protein', 'protien', 'Protien'])),
                                ),
                                _buildComparisonRow(
                                  'Carbs',
                                  _parseValue(_getFieldValue(mealNutrition!, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])).toString() + 'g',
                                  _parseValue(_getFieldValue(goalNutrition!, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])).toString() + 'g',
                                  _parseValue(_getFieldValue(mealNutrition!, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])) > _parseValue(_getFieldValue(goalNutrition!, ['carbs', 'Carbs', 'carbohydrates', 'Carbohydrates', 'carb', 'Carb'])),
                                ),
                                _buildComparisonRow(
                                  'Fat',
                                  _parseValue(_getFieldValue(mealNutrition!, ['fat', 'Fat', 'fats', 'Fats'])).toString() + 'g',
                                  _parseValue(_getFieldValue(goalNutrition!, ['fat', 'Fat', 'fats', 'Fats'])).toString() + 'g',
                                  _parseValue(_getFieldValue(mealNutrition!, ['fat', 'Fat', 'fats', 'Fats'])) > _parseValue(_getFieldValue(goalNutrition!, ['fat', 'Fat', 'fats', 'Fats'])),
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
}