// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:real_estate/providers/property_provider.dart';

import 'firebase_options.dart';
import 'theme/custom_colors.dart';

import 'pages/authentication/login_page.dart';
import 'pages/authentication/register_page.dart';
import 'pages/intro/splash_page.dart';
import 'pages/intro/welcome_page.dart';
import 'pages/home/home_page.dart';

import 'providers/auth_provider.dart';
import 'providers/city_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CityProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'X STATE',

      // ✅ Light theme only — no dark theme toggle
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: customLightColorScheme,
        scaffoldBackgroundColor: CustomColors.background,
        fontFamily: 'Montserrat',

        textTheme: const TextTheme(
          displayLarge: TextStyle(color: CustomColors.textPrimary),
          displayMedium: TextStyle(color: CustomColors.textPrimary),
          displaySmall: TextStyle(color: CustomColors.textPrimary),
          headlineLarge: TextStyle(color: CustomColors.textPrimary),
          headlineMedium: TextStyle(color: CustomColors.textPrimary),
          headlineSmall: TextStyle(color: CustomColors.textPrimary),
          titleLarge: TextStyle(color: CustomColors.textPrimary),
          titleMedium: TextStyle(color: CustomColors.textPrimary),
          titleSmall: TextStyle(color: CustomColors.textPrimary),
          bodyLarge: TextStyle(color: CustomColors.textSecondary),
          bodyMedium: TextStyle(color: CustomColors.textSecondary),
          bodySmall: TextStyle(color: CustomColors.textSecondary),
        ),

        // ✅ Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CustomColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: CustomColors.textSecondary.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          labelStyle: TextStyle(color: CustomColors.textPrimary),
        ),

        // ✅ Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.darkGreen,
            foregroundColor: CustomColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
