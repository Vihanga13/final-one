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
import 'package:path_provider/path_provider.dart';

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
      debugShowCheckedModeBanner: false, // Hides the debug banner 
      title: 'Fitness App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/': (context) => const GoalSelectionPage(),
        '/bmi': (context) => WhiteGreenBMIPage(),
        '/scan_meal': (context) => CustomBottomNavBar(
              onItemSelected: (int index) {
                // Implement functionality here
              },
              selectedIndex: 0,
            ),
        '/meal_result': (context) => const ScanMealPage(),
        '/complete_details': (context) => CompleteProfilePage(),
        '/forgot_password': (context) => MealResultPage(
              mealImage: null,
            ),
        '/MealComparisonPage': (context) => const MealComparisonPage(
              mealImage: null,
            ),
        '/profiledetails': (context) => ProfilePage(),
        '/profile': (context) => ModernForgotPasswordPage(),
        '/changepw': (context) => ChangePasswordPage(),
        '/sett': (context) => SettingsPage(),
        '/help and supp': (context) => HelpSupportPage(),
      },
    );
  }
}
