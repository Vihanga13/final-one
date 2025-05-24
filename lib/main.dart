import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:health_app_3/firebase_options.dart';
import 'package:health_app_3/pages/Help_and_support_page.dart';
import 'package:health_app_3/pages/bmi_calculate_page.dart';
import 'package:health_app_3/pages/bottom_navbar.dart';
import 'package:health_app_3/pages/change_password.dart';
import 'package:health_app_3/pages/forgotpassword.dart';
import 'package:health_app_3/pages/goal_selection_page.dart';
import 'package:health_app_3/pages/login_page.dart';
import 'package:health_app_3/pages/main_screen.dart';
import 'package:health_app_3/pages/profile_page.dart';
import 'package:health_app_3/pages/register_page.dart';
import 'package:health_app_3/pages/scanmeal_page.dart' show ScanMealPage;
import 'package:health_app_3/pages/settings_page.dart';
import 'package:health_app_3/screens/chat_screen.dart';
import 'complete_details_page.dart';
import 'pages/meal_comparison_page.dart';
import 'pages/meal_result_page.dart';



import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Load environment variables with better error handling
    try {
      await dotenv.load(fileName: ".env");
      print("Environment variables loaded successfully");
      print("API Key available: ${dotenv.env['OPENAI_API_KEY']?.isNotEmpty == true}");
    } catch (envError) {
      print('Error loading .env file: $envError');
      // Continue execution even if .env fails to load
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    print('Error during app initialization: $e');
    // Ensure the app still runs even if initialization fails
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  }
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
        '/forgot_password': (context) => ModernForgotPasswordPage(),
        '/register': (context) => const RegisterPage(),
        '/complete_details': (context) => CompleteProfilePage(),
        '/goal_selection': (context) => const GoalSelectionPage(),
        '/bmi': (context) => WhiteGreenBMIPage(),
        '/scan_meal': (context) => const ScanMealPage(),
        '/meal_result': (context) => const MealResultPage(),
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => SettingsPage(),
        '/change_password': (context) => ChangePasswordPage(),
        '/help_&_support': (context) => HelpSupportPage(),
        '/main_screen': (context) => MainScreen(),
     

        '/chatscreen': (context) =>  ChatScreen(),






        '/chat': (context) => CustomBottomNavBar(
              onItemSelected: (int index) {
                // Implement functionality here
              },
              selectedIndex: 0,
            ),
      },
    );
  }
}
