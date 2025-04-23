import 'package:flutter/material.dart';
import 'package:health_app_3/pages/bmi_calculate_page.dart';

class GoalSelectionPage extends StatefulWidget {
  const GoalSelectionPage({Key? key}) : super(key: key);

  @override
  _GoalSelectionPageState createState() => _GoalSelectionPageState();
}

class _GoalSelectionPageState extends State<GoalSelectionPage> with SingleTickerProviderStateMixin {
  int? _selectedGoal;
  late AnimationController _controller;
  final List<Animation<double>> _goalAnimations = [];

  final List<Map<String, dynamic>> _goals = [
    {
      'title': 'Diabetic Patient',
      'description': 'Manage blood sugar levels and maintain a healthy lifestyle',
      'icon': Icons.medical_services_outlined,
      'gradient': [
        const Color(0xFF86BF3E),
        const Color(0xFF69AA28),
      ],
    },
    {
      'title': 'Cholesterol Patient',
      'description': 'Control cholesterol levels with proper diet and exercise',
      'icon': Icons.favorite_outline,
      'gradient': [
        const Color(0xFF8CC63F),
        const Color(0xFF6FAA28),
      ],
    },
    {
      'title': 'Loss Weight',
      'description': 'Achieve healthy weight loss through balanced nutrition',
      'icon': Icons.trending_down,
      'gradient': [
        const Color(0xFF93CC3F),
        const Color(0xFF75B028),
      ],
    },
    {
      'title': 'Gain Weight',
      'description': 'Build healthy mass with proper nutrition and exercise',
      'icon': Icons.trending_up,
      'gradient': [
        const Color(0xFF9AD33F),
        const Color(0xFF7CB628),
      ],
    },
    {
      'title': 'Weight Balancing',
      'description': 'Maintain optimal weight and healthy lifestyle',
      'icon': Icons.balance_outlined,
      'gradient': [
        const Color(0xFFA1D93F),
        const Color(0xFF83BC28),
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create staggered animations for each goal card
    for (int i = 0; i < _goals.length; i++) {
      final start = i * 0.1;
      final end = start + 0.6;
      _goalAnimations.add(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    }

    // Start the animation when the page loads
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
                  ),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose Your \nHealth Goal',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select the goal that best matches your health journey',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return AnimatedBuilder(
                      animation: _goalAnimations[index],
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_goalAnimations[index]),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.5, 0),
                              end: Offset.zero,
                            ).animate(_goalAnimations[index]),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GoalCard(
                                title: _goals[index]['title'],
                                description: _goals[index]['description'],
                                icon: _goals[index]['icon'],
                                gradient: _goals[index]['gradient'],
                                isSelected: _selectedGoal == index,
                                onTap: () {
                                  setState(() {
                                    _selectedGoal = index;
                                  });
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _goals.length,
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _selectedGoal != null
                                  ? () {
                                      _animateButtonPress(context);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF86BF3E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
      ),
    );
  }

  void _animateButtonPress(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WhiteGreenBMIPage()),
    );
  }
}

class GoalCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final bool isSelected;
  final VoidCallback onTap;

  const GoalCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        tween: Tween<double>(begin: 1.0, end: isSelected ? 1.05 : 1.0),
        builder: (context, double scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? gradient[0].withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                spreadRadius: isSelected ? 2 : 1,
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF86BF3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      icon,
                      key: ValueKey<bool>(isSelected),
                      color: isSelected ? Colors.white : const Color(0xFF86BF3E),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        child: Text(title),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
                        child: Text(description),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF86BF3E).withOpacity(0.1),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF86BF3E),
                      width: 2,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return RotationTransition(
                        turns: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            key: ValueKey<bool>(true),
                            size: 16,
                            color: Color(0xFF86BF3E),
                          )
                        : const SizedBox(key: ValueKey<bool>(false)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}