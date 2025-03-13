import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scan_report.dart';
import 'screens/scan_report_placeholder_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pregnancy Support App',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primaryColor: const Color(0xFF9370DB), // Light violet
        scaffoldBackgroundColor:
            const Color.fromARGB(255, 255, 255, 255), // Light violet
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF9370DB),
        ), // Light violet
      ),
      darkTheme: ThemeData(
        primaryColor: const Color(0xFF4B0082), // Dark violet primary color
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF4B0082)),
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(
              isDarkMode: isDarkMode,
              toggleTheme: toggleTheme,
            ),
        '/login': (context) => LoginScreen(
              toggleTheme: toggleTheme,
              isDarkMode: isDarkMode,
            ),
        '/profile': (context) => ProfileScreen(
              toggleTheme: toggleTheme,
              isDarkMode: isDarkMode,
            ),
        '/signup': (context) => SignupScreen(
              isDarkMode: isDarkMode,
              toggleTheme: toggleTheme,
            ),
        '/reset': (context) => ResetPasswordScreen(
              isDarkMode: isDarkMode,
              toggleTheme: toggleTheme,
            ),
        '/home': (context) => HomeScreen(
              isDarkMode: isDarkMode,
              toggleTheme: toggleTheme,
            ),
        '/scan': (context) => ScanReportScreen(),
        '/scan_placeholder': (context) => const ScanReportPlaceholderScreen(),
      },
    );
  }
}
