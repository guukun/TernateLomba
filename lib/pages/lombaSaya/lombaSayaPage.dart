import 'package:flutter/material.dart';

class LombaSayaPage extends StatelessWidget {
  const LombaSayaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Lomba Saya",

          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
