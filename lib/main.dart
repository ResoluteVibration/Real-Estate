import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:real_estate/providers/contacted_provider.dart';
import 'firebase_options.dart';
import 'theme/custom_colors.dart';

import 'pages/intro/welcome_page.dart';
import 'pages/intro/splash_page.dart';
import 'pages/authentication/login_page.dart';
import 'pages/authentication/register_page.dart';
import 'pages/home/home_page.dart';

import 'providers/auth_provider.dart';
import 'providers/city_provider.dart';
import 'package:real_estate/providers/property_provider.dart';

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
        ChangeNotifierProvider(create: (_) => ContactedProvider()),
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
      title: 'REAL ESTATE',

      // ✅ Light theme only — no dark theme toggle
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: customLightColorScheme,
        scaffoldBackgroundColor: CustomColors.background,
        fontFamily: 'Montserrat',

        // FIX: Change text themes for body text to a darker color.
        // This will automatically make typed text in TextFields visible.
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
          bodyMedium: TextStyle(color: CustomColors.textPrimary),
          bodySmall: TextStyle(color: CustomColors.textPrimary),
        ),

        // ✅ Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CustomColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: CustomColors.mutedBlue, width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: CustomColors.deepBlue, width: 2.0),
          ),
          hintStyle: TextStyle(color: CustomColors.mutedBlue.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          floatingLabelStyle: const TextStyle(color: CustomColors.onSurface),
          labelStyle: const TextStyle(color: CustomColors.mutedBlue),
          isDense: true,
        ),

        // ✅ Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.deepBlue,
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
