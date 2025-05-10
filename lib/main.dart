import 'package:flutter/material.dart';
import 'package:health_app_3/firebase_options.dart';
import 'package:health_app_3/pages/Help_and_support_page.dart';
import 'package:health_app_3/pages/bmi_calculate_page.dart';
import 'package:health_app_3/pages/bottom_navbar.dart';
import 'package:health_app_3/pages/change_password.dart';
import 'package:health_app_3/pages/forgotpassword.dart';
import 'package:health_app_3/pages/goal_selection_page.dart';
import 'package:health_app_3/pages/login_page.dart';
import 'package:health_app_3/pages/profile_page.dart';
import 'package:health_app_3/pages/register_page.dart';
import 'package:health_app_3/pages/settings_page.dart';
import 'complete_details_page.dart';
import 'pages/meal_comparison_page.dart';
import 'pages/meal_result_page.dart';
import 'pages/scanmeal_page.dart';


import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/goal_selection': (context) => const GoalSelectionPage(),
        '/bmi': (context) => WhiteGreenBMIPage(),
        '/bottom': (context) => CustomBottomNavBar(
              onItemSelected: (int index) {
                // Implement functionality here
              },
              selectedIndex: 0,
            ),
        '/scan_meal': (context) => const ScanMealPage(),
        '/complete_details': (context) => CompleteProfilePage(),
        '/forgot_password': (context) => ModernForgotPasswordPage(),
        '/meal_result': (context) => const MealResultPage(mealImage: null,), // Replace 'defaultGoal' with an appropriate value
        '/profile': (context) => ProfilePage(),
        '/changepw': (context) => ChangePasswordPage(),
        '/settings': (context) => SettingsPage(),
        '/help': (context) => HelpSupportPage(),
      },
    );
  }
}
