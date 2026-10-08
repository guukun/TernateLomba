import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'splash_screen.dart';

void main() => runApp(const TernateLombaApp());

class TernateLombaApp extends StatelessWidget {
  const TernateLombaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TernateLomba',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
