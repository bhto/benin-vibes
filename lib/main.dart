import 'package:flutter/material.dart';
import 'onboarding_page.dart';
import 'theme.dart';

void main() => runApp(const BeninVibesApp());

class BeninVibesApp extends StatelessWidget {
  const BeninVibesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Benin Vibes',
      theme: buildTheme(),
      home: const OnboardingPage(),
    );
  }
}
