import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _loginAsGuest(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.loginAsGuest();
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Find Your Dream Home",
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
                child: Text(
                  "Discover the best properties to buy or rent.",
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Sign In
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                child: const Text('Sign In'),
              ),

              // Sign Up
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/register'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colorScheme.primary,
                      width: 2.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Sign Up',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Continue as Guest
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: OutlinedButton(
                  onPressed: () => _loginAsGuest(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colorScheme.secondary,
                      width: 2.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Continue as Guest',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
