import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_app_3/pages/main_screen.dart';
import 'package:health_app_3/pages/scanmeal_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WhiteGreenBMIPage extends StatefulWidget {
  const WhiteGreenBMIPage({super.key});

  @override
  _WhiteGreenBMIPageState createState() => _WhiteGreenBMIPageState();
}

class _WhiteGreenBMIPageState extends State<WhiteGreenBMIPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightFeetController = TextEditingController();
  final TextEditingController _heightInchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  double? _bmi;
  String _bmiCategory = '';
  bool _isLoading = false;
  bool _showResult = false;
  bool _inputsFilled = false;

  // Color Scheme with White Background
  static const Color primaryGreen = Color(0xFF86BF3E);
  static const Color lightGreen = Color(0xFFF7FAF2);
  static const Color textGreen = Color(0xFF2C3E1B);
  static const Color backgroundColor = Colors.white;

  // Height unit selection
  String _heightUnit = 'cm'; // 'cm' or 'ftin'

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    // Add listeners to check if both fields have values
    _heightController.addListener(_checkInputs);
    _weightController.addListener(_checkInputs);
    _heightFeetController.addListener(_checkInputs);
    _heightInchController.addListener(_checkInputs);
  }

  void _checkInputs() {
    setState(() {
      if (_heightUnit == 'cm') {
        _inputsFilled = _heightController.text.isNotEmpty && _weightController.text.isNotEmpty;
      } else {
        _inputsFilled = _heightFeetController.text.isNotEmpty && _heightInchController.text.isNotEmpty && _weightController.text.isNotEmpty;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _heightFeetController.dispose();
    _heightInchController.dispose();
    super.dispose();
  }

  void _calculateBMI() async {
    if ((_heightUnit == 'cm' && _heightController.text.isNotEmpty && _weightController.text.isNotEmpty) ||
        (_heightUnit == 'ftin' && _heightFeetController.text.isNotEmpty && _heightInchController.text.isNotEmpty && _weightController.text.isNotEmpty)) {
      setState(() {
        _isLoading = true;
      });

      // Simulate calculation delay
      await Future.delayed(const Duration(milliseconds: 800));
      double height;
      if (_heightUnit == 'cm') {
        height = double.parse(_heightController.text) / 100;
      } else {
        int feet = int.tryParse(_heightFeetController.text) ?? 0;
        int inches = int.tryParse(_heightInchController.text) ?? 0;
        height = ((feet * 12) + inches) * 2.54 / 100;
      }
      double weight = double.parse(_weightController.text);

      setState(() {
        _bmi = weight / (height * height);
        _updateBMICategory();
        _isLoading = false;
        _showResult = true;

        // Reset and forward animation to animate the result
        _animationController.reset();
        _animationController.forward();
      });

      // Save to Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _bmi != null) {
        double heightCm;
        int? heightFeet;
        int? heightInch;
        if (_heightUnit == 'cm') {
          heightCm = double.tryParse(_heightController.text) ?? 0;
          // Convert to feet/inch
          double totalInches = heightCm / 2.54;
          heightFeet = totalInches ~/ 12;
          heightInch = (totalInches % 12).round();
        } else {
          heightFeet = int.tryParse(_heightFeetController.text) ?? 0;
          heightInch = int.tryParse(_heightInchController.text) ?? 0;
          heightCm = ((heightFeet * 12) + heightInch) * 2.54;
        }
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'height_cm': heightCm,
          'height_feet': heightFeet,
          'height_inch': heightInch,
          'weight': weight,
          'bmi': _bmi,
          'bmiCategory': _bmiCategory,
        }, SetOptions(merge: true));
      }
    }
  }

  void _updateBMICategory() {
    if (_bmi == null) return;

    if (_bmi! < 18.5) {
      _bmiCategory = 'Underweight';
    } else if (_bmi! < 24.9) {
      _bmiCategory = 'Normal Weight';
    } else if (_bmi! < 29.9) {
      _bmiCategory = 'Overweight';
    } else {
      _bmiCategory = 'Obese';
    }
  }

  Future<void> _handleDonePress() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate some processing
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    // Navigate back or to next screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'BMI Calculator',
          style: TextStyle(
            color: textGreen,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input Section
                  Row(
                    children: [
                      const Text('Height unit:'),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('cm'),
                        selected: _heightUnit == 'cm',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _heightUnit = 'cm';
                              _heightFeetController.clear();
                              _heightInchController.clear();
                            });
                            _checkInputs();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('ft/in'),
                        selected: _heightUnit == 'ftin',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _heightUnit = 'ftin';
                              _heightController.clear();
                            });
                            _checkInputs();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_heightUnit == 'cm')
                    _buildInputField(
                      controller: _heightController,
                      label: 'Height',
                      hint: 'Enter your height',
                      suffix: 'cm',
                      icon: Icons.height_rounded,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _heightFeetController,
                            label: 'Height',
                            hint: 'Feet',
                            suffix: 'ft',
                            icon: Icons.height_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            controller: _heightInchController,
                            label: '',
                            hint: 'Inches',
                            suffix: 'in',
                            icon: Icons.height_rounded,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _weightController,
                    label: 'Weight',
                    hint: 'Enter your weight',
                    suffix: 'kg',
                    icon: Icons.monitor_weight_rounded,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _inputsFilled && !_isLoading ? _calculateBMI : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: primaryGreen.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Calculate BMI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Result Section
                  if (_showResult && _bmi != null) ...[
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        Color resultBgColor;
                        Color textColor = Colors.black87;
                        Color badgeBg = Colors.black.withOpacity(0.07);
                        Color badgeText = Colors.black87;
                        switch (_bmiCategory) {
                          case 'Normal Weight':
                            resultBgColor = const Color(0xFFE6F4EA); // soft green
                            break;
                          case 'Overweight':
                            resultBgColor = const Color(0xFFFFF4E5); // soft amber
                            textColor = const Color(0xFF7C4700); // dark amber
                            badgeBg = const Color(0xFFFFE0B2);
                            badgeText = const Color(0xFF7C4700);
                            break;
                          case 'Obese':
                            resultBgColor = const Color(0xFFFDE8E4); // soft coral/red
                            textColor = const Color(0xFFB71C1C); // dark red
                            badgeBg = const Color(0xFFFFCDD2);
                            badgeText = const Color(0xFFB71C1C);
                            break;
                          case 'Underweight':
                            resultBgColor = const Color(0xFFE5F0FA); // soft blue
                            textColor = const Color(0xFF1565C0); // dark blue
                            badgeBg = const Color(0xFFBBDEFB);
                            badgeText = const Color(0xFF1565C0);
                            break;
                          default:
                            resultBgColor = const Color(0xFFF3E8FD); // soft purple for unknown
                        }
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: resultBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryGreen.withOpacity(0.15),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Your BMI',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: textColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Text(
                                            _bmiCategory,
                                            style: TextStyle(
                                              color: badgeText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(seconds: 1),
                                      tween: Tween<double>(begin: 0, end: _bmi!),
                                      builder: (context, value, child) {
                                        return Text(
                                          value.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 48,
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],

                  // BMI Scale
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BMI Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBMIScaleItem('Underweight', '< 18.5'),
                          _buildBMIScaleItem('Normal', '18.5 - 24.9'),
                          _buildBMIScaleItem('Overweight', '25.0 - 29.9'),
                          _buildBMIScaleItem('Obese', '≥ 30.0', isLast: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Done Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MainScreen()),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Finish',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textGreen,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              color: textGreen,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: textGreen.withOpacity(0.5),
              ),
              suffixText: suffix,
              suffixStyle: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Icon(
                icon,
                color: primaryGreen,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBMIScaleItem(String category, String range, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: primaryGreen.withOpacity(0.1),
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category,
            style: TextStyle(
              fontSize: 16,
              color: textGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}