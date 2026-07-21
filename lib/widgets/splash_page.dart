import 'dart:async';
import 'package:flutter/material.dart';
import 'package:osc_controller/app_main.dart';
import 'package:osc_controller/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Mostra la splash per 2 secondi, poi vai alla navigazione principale.
    // Nota: si naviga verso HomeNavigation (non verso App) per non annidare
    // un secondo MaterialApp dentro quello già creato in main.dart.
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeNavigation()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png', // metti qui il logo corretto - va inserito in pubspec sezione assets
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
