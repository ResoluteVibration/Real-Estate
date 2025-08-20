import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    _checkAuthenticationStatus();
  }

  void _checkAuthenticationStatus(){
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Future.delayed(const Duration(seconds: 3), () {
      if (authProvider.currentUser != null){
        Navigator.of(context).pushReplacementNamed('/home');
      }
      else{
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Image.asset(
          'assets/logo/x_state.png',
          width: screenWidth * 2,
          height: screenHeight * 1,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
