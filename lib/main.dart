import 'package:flutter/material.dart';

import 'config/appTheme.dart';
import 'widgets/app_feedback.dart';
import 'screens/splash/splashScreen.dart';
import 'pages/ajukan/ajukanPage.dart';

Future<void> main() async {
  runApp(const TernateLombaApp());
}

class TernateLombaApp extends StatelessWidget {
  const TernateLombaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: AppNotification.messengerKey,
      title: 'TernateLomba',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
      routes: {'/ajukan': (context) => const AjukanPage()},
    );
  }
}
