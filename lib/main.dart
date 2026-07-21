import 'package:flutter/material.dart';
import 'widgets/splash_page.dart';

void main() {
  runApp(const MyRoot());
}

class MyRoot extends StatelessWidget {
  const MyRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSC Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false),
      home: const SplashPage(), // qui parte la splash
    );
  }
}
