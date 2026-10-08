import 'package:flutter/material.dart';

import 'appTheme.dart';
import 'screens/splashScreen.dart';

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
