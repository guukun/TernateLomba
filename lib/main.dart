import 'package:flutter/material.dart';

import 'config/appTheme.dart';
import 'screens/splash/splashScreen.dart';

void main() {
  runApp(const TernateLombaApp());
}

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